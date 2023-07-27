module graphql.graphql;

import std.array : array, front, empty;
import std.stdio;
version(LDC) {
	import std.experimental.logger;
} else {
	import std.logger;
}

import std.traits;
import std.meta : AliasSeq;
import std.range.primitives : popBack;
import std.algorithm.iteration : filter;
import std.algorithm.searching : canFind;
import std.format : format;
import std.exception : enforce;

import vibe.core.core;
import vibe.data.json;

import graphql.argumentextractor;
import graphql.ast;
import graphql.builder;
import graphql.constants;
import graphql.directives;
import graphql.helper;
import graphql.schema.resolver;
import graphql.schema.types;
import graphql.tokenmodule;
import graphql.exception;
import graphql.treevisitor;
import graphql.traits : interfacesForType;

@safe:

enum AsyncList {
	no,
	yes
}

struct GQLDOptions {
	AsyncList asyncList;
}

struct DefaultContext {
}

private struct ExecutionContext {
	// path information
	PathElement[] path;

	@property ExecutionContext dup() const {
		import std.algorithm.mutation : copy;
		ExecutionContext ret;
		ret.path = new PathElement[](this.path.length);
		this.path.copy(ret.path);
		return ret;
	}
}

struct ParentArgs {
	Json parent;
	Json args;
}

struct DocumentArgs {
	Document doc;
	Field field;
	FieldRangeItem[] fieldRangeItems;
}

class GraphQLD(T, QContext = DefaultContext) {
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context) @safe;
	alias QueryArrayResolver = Json delegate(string name, ParentArgs parentArgs
			, DocumentArgs docArgs, ref Con context) @safe;

	alias DefaultQueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context, ref ExecutionContext ec) @safe;

	alias Schema = GQLDSchema!(T);
	immutable GQLDOptions options;

	Schema schema;

	// the logger to use
	Logger executationTraceLog;
	Logger defaultResolverLog;
	Logger resolverLog;

	// [Type][field]
	QueryResolver[string][string] resolver;
	QueryArrayResolver[string][string] arrayResolver;
	DefaultQueryResolver defaultResolver;

	this(GQLDOptions options = GQLDOptions.init) {
		this.options = options;
		this.schema = toSchema!(T)();
		this.executationTraceLog = new MultiLogger(LogLevel.off);
		this.defaultResolverLog = new MultiLogger(LogLevel.off);
		this.resolverLog = new MultiLogger(LogLevel.off);

		this.defaultResolver = delegate(string name, Json parent, Json args,
									ref Con context, ref ExecutionContext ec)
			{
				import std.format;
				this.defaultResolverLog.logf("name: %s, parent: %s, args: %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				if(parent.type == Json.Type.object && name in parent) {
					ret["data"] = Json.emptyObject();
					ret["data"] = parent[name];
				} else {
					ret[Constants.errors] = Json.emptyArray();
					ret.insertError(format(
							"no field name '%s' found on type '%s' parent '%s'"
									, name
									, parent.getWithDefault!string("__typename")
									, parent.toString()
							), ec.path
						);
				}
				this.defaultResolverLog.logf("default ret %s", ret);
				return ret;
			};

		setDefaultSchemaResolver(this);
	}

	void setResolver(string first, string second, QueryResolver resolver) {
		import std.exception : enforce;
		if(first !in this.resolver) {
			this.resolver[first] = QueryResolver[string].init;
		}
		enforce(second !in this.resolver[first], format(
				"'%s'.'%s' is already registered", first, second));
		this.resolver[first][second] = resolver;
		if(first == "queryType") {
			auto qt = "queryType" in this.schema.member;
			if(qt !is null) {
				this.resolver[qt.name][second] = resolver;
			}
		} else if(first == "mutationType") {
			auto qt = "mutationType" in this.schema.member;
			if(qt !is null) {
				this.resolver[qt.name][second] = resolver;
			}
		} else if(first == "subscriptionType") {
			auto qt = "subscriptionType" in this.schema.member;
			if(qt !is null) {
				this.resolver[qt.name][second] = resolver;
			}
		}
	}

	void setArrayResolver(string first, string second
			, QueryArrayResolver resolver)
	{
		if(first !in this.arrayResolver) {
			this.arrayResolver[first] = QueryArrayResolver[string].init;
		}
		enforce(second !in this.arrayResolver[first], format(
				"'%s'.'%s' is already registered", first, second));
		this.arrayResolver[first][second] = resolver;
	}

	Json resolve(string type, string field, Json parent, Json args,
			ref Con context, ref ExecutionContext ec)
	{
		Json defaultArgs = this.getDefaultArguments(type, field);
		Json joinedArgs = joinJson!(JoinJsonPrecedence.a)(args, defaultArgs);
		enforce(type != "__type" && field != "__ofType"
			, "type != '__type' && field != '__ofType' " ~
				parent.toPrettyString());
		this.resolverLog.logf(
				"type: %s field: %s defArgs: %s par: %s args: %s %s", type,
				field, defaultArgs, parent, args, joinedArgs
			);
		if(type !in this.resolver) {
			return defaultResolver(field, parent, joinedArgs, context, ec);
		} else if(field !in this.resolver[type]) {
			return defaultResolver(field, parent, joinedArgs, context, ec);
		} else {
			return this.resolver[type][field](field, parent, joinedArgs,
					context
				);
		}
	}

	Json getDefaultArguments(string type, string field) {
		if(GQLDType* t = type in this.schema.types) {
			if(GQLDMap m = toMap(*t)) {
				if(GQLDType* ft = field in m.member) {
					if(GQLDOperation op = (*ft).toOperation()) {
						return op.defaultParameter;
					}
				}
			}
		}
		return Json.init;
	}

	Json execute(Document doc, Json variables, ref Con context) @trusted {
		import std.algorithm.searching : canFind, find;
		OperationDefinition[] ops = this.getOperations(doc);
		ExecutionContext ec;

		Json ret = Json.emptyObject();
		ret[Constants.data] = Json.emptyObject();
		foreach(op; ops) {
			Json tmp = this.executeOperation(op, variables, doc, context, ec);
			this.executationTraceLog.logf("%s\n%s\n%s", op.ruleSelection, ret,
					tmp);
			if(tmp.type == Json.Type.object && Constants.data in tmp) {
				foreach(key, value; tmp[Constants.data].byKeyValue()) {
					if(key in ret[Constants.data]) {
						this.executationTraceLog.logf(
								"key %s already present", key
							);
						continue;
					}
					ret[Constants.data][key] = value;
				}
			}
			this.executationTraceLog.logf("%s", tmp);
			if(Constants.errors in tmp && !tmp[Constants.errors].dataIsEmpty())
			{
				ret[Constants.errors] = Json.emptyArray();
			}
			foreach(err; tmp[Constants.errors]) {
				ret[Constants.errors] ~= err;
			}
		}
		return ret;
	}

	static OperationDefinition[] getOperations(Document doc) {
		import std.algorithm.iteration : map;
		return opDefRange(doc).map!(op => op.def.op).array;
	}

	Json executeOperation(OperationDefinition op, Json variables,
			Document doc, ref Con context, ref ExecutionContext ec)
	{
		ec.path ~= PathElement(
				op.name.value.empty ? "SelectionSet" : op.name.value);
		scope(exit) {
			ec.path.popBack();
		}
		immutable bool dirSaysToContinue = continueAfterDirectives(op.d, variables);
		if(!dirSaysToContinue) {
			return returnTemplate();
		}
		if(op.ruleSelection == OperationDefinitionEnum.SelSet
				|| op.ot.tok.type == TokenType.query)
		{
			return this.executeQuery(op, variables, doc, context, ec);
		} else if(op.ot.tok.type == TokenType.mutation) {
			return this.executeMutation(op, variables, doc, context, ec);
		} else if(op.ot.tok.type == TokenType.subscription) {
			assert(false, "Subscription not supported yet");
		}
		assert(false, "Unexpected");
	}

	Json executeMutation(OperationDefinition op, Json variables,
			Document doc, ref Con context, ref ExecutionContext ec)
	{
		this.executationTraceLog.log("mutation");
		Json tmp = this.executeSelections(op.ss.sel,
				this.schema.member["mutationType"], Json.emptyObject(),
				variables, doc, context, ec
			);
		return tmp;
	}

	Json executeQuery(OperationDefinition op, Json variables, Document doc,
			ref Con context, ref ExecutionContext ec)
	{
		this.executationTraceLog.log("query");
		auto qt = this.schema.member["queryType"];
		Json tmp = this.executeSelections(op.ss.sel, qt
				, Json.emptyObject(), variables, doc, context, ec
			);
		return tmp;
	}

	Json executeSelections(Selections sel, GQLDType objectType
			, Json objectValue, Json variables, Document doc, ref Con context
			, ref ExecutionContext ec
			, string[] fieldsToSkip = [])
	{
		Json ret = returnTemplate();
		this.executationTraceLog.logf("OT: %s, OJ: %s, VAR: %s",
				objectType.name, objectValue, variables);
		this.executationTraceLog.logf("TN: %s", interfacesForType(this.schema
				, objectValue
					.getWithDefault!string("data.__typename", "__typename")
			));
		foreach(FieldRangeItem field;
				fieldRangeArr(
					sel,
					doc,
					interfacesForType(this.schema
						, objectValue.getWithDefault!string(
							"data.__typename", "__typename")
						),
					variables)
				.filter!(it => !canFind(fieldsToSkip, it.name))
			)
		{
			//Json args = getArguments(field, variables);
			immutable bool dirSaysToContinue = continueAfterDirectives(
					field.f.dirs, variables);

			Json rslt = dirSaysToContinue
				? this.executeFieldSelection(field, objectType,
						objectValue, variables, doc, context, ec
					)
				: Json.emptyObject();

			const string name = field.f.name.name.value;
			ret.insertPayload(name, rslt);
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType objectType,
			Json objectValue, Json variables, Document doc, ref Con context,
			ref ExecutionContext ec)
	{
		ec.path ~= PathElement(field.f.name.name.value);
		scope(exit) {
			ec.path.popBack();
		}
		this.executationTraceLog.logf("FRI: %s, OT: %s, OV: %s, VAR: %s",
		//this.executationTraceLog.logf("FRI: %s, OT: %s, OV: %s, VAR: %s",
				field.name, objectType.name, objectValue, variables
			);
		Json arguments = getArguments(field, variables);
		//writefln("field %s\nobj %s\nvar %s\narg %s", field.name, objectValue,
		//		variables, arguments);
		Json de;
		try {
			de = this.resolve(objectType.name,
					field.aka.empty ? field.name : field.aka
				, objectValue.type == Json.Type.object && "data" in objectValue
					? objectValue["data"]
					: objectValue
				, arguments, context, ec
			);
		} catch(GQLDExecutionException e) {
			auto ret = Json.emptyObject();
			ret[Constants.data] = Json(null);
			ret[Constants.errors] = Json.emptyArray();
			ret.insertError(e.msg, ec.path);
			return ret;
		}

		auto retType = this.schema.getReturnType(objectType,
				field.aka.empty ? field.name : field.aka
			);
		if(retType is null) {
			this.executationTraceLog.logf("ERR %s %s", objectType.name,
					field.name
				);
			Json ret = Json.emptyObject();
			ret[Constants.errors] = Json.emptyArray();
			ret.insertError(format(
					"No return type for member '%s' of type '%s' found",
					field.name, objectType.name
				));
			return ret;
		}
		this.executationTraceLog.logf("retType %s, de: %s", retType.name, de);
		return this.executeSelectionSet(field.f.ss, retType, de, variables,
				doc, context, ec
			);
	}

	Json executeSelectionSet(SelectionSet ss, GQLDType objectType
			, Json objectValue, Json variables, Document doc, ref Con context
			, ref ExecutionContext ec
			, string[] fieldsToSkip = [])
	{
		Json rslt;
		if(GQLDMap map = objectType.toMap()) {
			this.executationTraceLog.log("MMMMMAP %s %s", map.name, ss !is null);
			enforce(ss !is null && ss.sel !is null, format(
					"ss null %s, ss.sel null %s %s", ss is null,
					(ss is null) ? true : ss.sel is null, ec.path));
			rslt = this.executeSelections(ss.sel, map, objectValue, variables,
					doc, context, ec, fieldsToSkip
				);
		} else if(GQLDNonNull nonNullType = objectType.toNonNull()) {
			this.executationTraceLog.logf("NonNull %s objectValue %s",
					nonNullType.elementType.name, objectValue
				);
			rslt = this.executeSelectionSet(ss, nonNullType.elementType,
					objectValue, variables, doc, context, ec, fieldsToSkip
				);
			if(rslt.dataIsNull()) {
				this.executationTraceLog.logf("%s", rslt);
				rslt.insertError("NonNull was null", ec.path);
			}
		} else if(GQLDNullable nullType = objectType.toNullable()) {
			this.executationTraceLog.logf("NNNNULLABLE %s %s", nullType.name,
					objectValue);
			this.executationTraceLog.logf("IIIIIS EMPTY %s objectValue %s",
					objectValue.dataIsEmpty(), objectValue
				);
			if(objectValue.type == Json.Type.null_ ||
				(objectValue.type == Json.Type.object &&
				((nullType.elementType.toList && "data" !in objectValue)
				 || objectValue.dataIsNull))) {
				if(objectValue.type != Json.Type.object) {
					objectValue = Json.emptyObject();
				}
				objectValue["data"] = null;
				objectValue.remove(Constants.errors);
				rslt = objectValue;
			} else {
				rslt = this.executeSelectionSet(ss, nullType.elementType,
						objectValue, variables, doc, context, ec, fieldsToSkip
					);
			}
		} else if(GQLDList list = objectType.toList()) {
			this.executationTraceLog.logf("LLLLLIST %s objectValue %s",
					list.name, objectValue);
			rslt = this.executeList(ss, list, objectValue, variables, doc,
					context, ec
				);
		} else if(GQLDScalar scalar = objectType.toScalar()) {
			rslt = objectValue;
		}

		return rslt;
	}

	private void toRun(SelectionSet ss, GQLDType elemType, Json item,
			Json variables, ref Json ret, Document doc, ref Con context,
			ref ExecutionContext ec, string[] fieldsToSkip)
		@trusted
	{
		this.executationTraceLog.logf("ET: %s, item %s", elemType.name,
				item
			);
		Json tmp = this.executeSelectionSet(ss, elemType, item, variables,
				doc, context, ec, fieldsToSkip
			);
		if(tmp.type == Json.Type.object) {
			if("data" in tmp) {
				ret["data"] ~= tmp["data"];
			}
			foreach(err; tmp[Constants.errors]) {
				ret[Constants.errors] ~= err;
			}
		} else if(!tmp.dataIsEmpty() && tmp.isScalar()) {
			ret["data"] ~= tmp;
		}
	}

	private void toRunArrayResolverFollow(SelectionSet ss, GQLDType elemType, Json item
			, ref Json ret, Json variables, Document doc, ref Con context
			, ref ExecutionContext ec) @trusted
	{
		//writefln("%s\n%s", elemType, item.toPrettyString());
		if(GQLDList l = elemType.toList()) {
			enforce(item.type == Json.Type.array, "Expected Array got "
					~ item.toPrettyString());
			foreach(it; item) {
				Json tmp = this.executeSelectionSet(ss, l.elementType, it, variables,
					doc, context, ec
				);
				if("data" in tmp) {
					ret["data"] ~= tmp["data"];
				}
				foreach(err; tmp[Constants.errors]) {
					ret[Constants.errors] ~= err;
				}
				writeln(ret["data"].toPrettyString());
			}
		} else {
			Json tmp = this.executeSelectionSet(ss, elemType, item, variables,
					doc, context, ec
				);
			if("data" in tmp) {
				ret["data"] ~= tmp["data"];
			}
			foreach(err; tmp[Constants.errors]) {
				ret[Constants.errors] ~= err;
			}
		}
	}

	Json executeList(SelectionSet ss, GQLDList objectType,
			Json objectValue, Json variables, Document doc, ref Con context,
			ref ExecutionContext ec)
			@trusted
	{
		this.executationTraceLog.logf("OT: %s, OJ: %s, VAR: %s",
				objectType.name, objectValue, variables
			);
		enforce(objectValue.type == Json.Type.object, "Excepted object got "
				~ objectValue.toPrettyString());
		enforce("data" in objectValue, "Excepted object to contain key with name"
				~ " 'data' but got " ~ objectValue.toPrettyString());
		GQLDType elemType = objectType.elementType;
		GQLDType unPacked = unpack2(elemType);

		this.executationTraceLog.logf("elemType %s", elemType);
		Json ret = returnTemplate();
		ret["data"] = Json.emptyArray();

		QueryArrayResolver[string]* arrayTypeResolverArray =
			unPacked !is null
				? unPacked.name in this.arrayResolver
				: null;
		GQLDMap elemTypeMap = toMap(unPacked);

		string[] fieldsHandledByArrayResolver;
		if(arrayTypeResolverArray !is null) {
			FieldRange fr = fieldRange(ss, doc
					, interfacesForType(this.schema
						, objectValue.getWithDefault!string("data.__typename"
						, "__typename"))
					, variables, BuildLinear.yes);
			foreach(FieldRangeItem field; fr) {
				QueryArrayResolver* arrayTypeResolver =
					field.name in (*arrayTypeResolverArray);

				writefln("Array Resolver %s.%s %s", unPacked.name
						, field.name
						, arrayTypeResolver !is null);
				if(arrayTypeResolver !is null) {
					FieldRangeItem[] fri = fieldRangeArr(field.f.ss.sel, doc
						, interfacesForType(this.schema
							, objectValue.getWithDefault!string("data.__typename"
								, "__typename"))
						, variables);

					fieldsHandledByArrayResolver ~= field.name;
					Json rslt = (*arrayTypeResolver)(field.name
							, ParentArgs(objectValue, variables)
							, DocumentArgs(doc, field.f, fri)
							, context);

					enforce(rslt.type == Json.Type.object, "ArrayResolver"
							~ " results must be an Json.Type.object not " ~
							rslt.toPrettyString());
					enforce("data" in rslt, "data must be a member of an"
							~ "ArrayResolver result. Given "
							~ rslt.toPrettyString());
					enforce(rslt["data"].type == Json.Type.array, "ArrayResolver"
							~ "['data'] must be an array not " ~ rslt["data"]
							.toPrettyString());
					//objectValue[field.name] = rslt;

					writefln("objV %s\nrslt %s", objectValue.toPrettyString()
							, rslt.toPrettyString());

					string fieldName = field.aka.empty ? field.name : field.aka;
					auto rsltType = this.schema.getReturnType(unPacked, fieldName);
					auto rsltTypeUn = unpackNonList(rsltType);
					writefln("%s\n%s", rsltType, rsltTypeUn);

					size_t idx;
					foreach(Json item;
							"data" in rslt
									&& rslt["data"].type == Json.Type.array
								? rslt["data"]
								: Json.emptyArray()
						)
					{
						ec.path ~= PathElement(idx);
						++idx;
						scope(exit) {
							ec.path.popBack();
						}
						this.toRunArrayResolverFollow(field.f.ss, rsltTypeUn
								, item, ret, variables, doc, context, ec);
					}
					//joinInArray(ret, rslt, fieldName);
					//return ret;
					//writeln(ret.toPrettyString());
				}
			}
		}
		writefln("already handled %s", fieldsHandledByArrayResolver);

		if(this.options.asyncList == AsyncList.yes) {
			Task[] tasks;
			foreach(Json item;
					objectValue["data"].type == Json.Type.array
						? objectValue["data"]
						: Json.emptyArray()
				)
			{
				tasks ~= runTask({
					() nothrow {
					try {
						auto newEC = ec.dup;
						this.toRun(ss, elemType, item, variables, ret, doc,
								context, newEC, fieldsHandledByArrayResolver
							);
					} catch(Exception e) {
						try {
							this.executationTraceLog.errorf("Error in task %s"
									, e.toString());
						} catch(Exception f) {
						}
					}
					}();
				});
			}
			foreach(task; tasks) {
				task.join();
			}
		} else {
			size_t idx;
			foreach(Json item;
					objectValue["data"].type == Json.Type.array
						? objectValue["data"]
						: Json.emptyArray()
				)
			{
				ec.path ~= PathElement(idx);
				++idx;
				scope(exit) {
					ec.path.popBack();
				}
				this.toRun(ss, elemType, item, variables, ret, doc, context, ec
						, fieldsHandledByArrayResolver);
			}
		}
		return ret;
	}
}

import graphql.uda;
import std.datetime : DateTime;

private DateTime fromStringImpl(string s) {
	return DateTime.fromISOExtString(s);
}

@GQLDUda(TypeKind.OBJECT)
private struct Query {

	GQLDCustomLeaf!(DateTime, toStringImpl, fromStringImpl)  current();
}

private class Schema {
	Query queryTyp;
}

unittest {
	import graphql.schema.typeconversions;
	import graphql.traits;
	import std.datetime : DateTime;

	alias a = collectTypes!(Schema);
	alias exp = AliasSeq!(Schema, Query, string, long, bool,
					GQLDCustomLeaf!(DateTime, toStringImpl, fromStringImpl));
	//static assert(is(a == exp), format("\n%s\n%s", a.stringof, exp.stringof));

	//pragma(msg, InheritedClasses!Schema);

	//auto g = new GraphQLD!(Schema,int)();
}

void joinInArray(ref Json target, ref Json source, string joinFieldName) @trusted {
	writefln("target: %s\nsource: %s", target.toPrettyString()
			, source.toPrettyString());
	if(target.type == Json.Type.object && "data" in target) {
		//enforce(source.type == Json.object && "data" in source.type
		//		, source.toPrettyString());
		joinInArray(target["data"], source, joinFieldName);
	} else if(target.type == Json.Type.object) {
		target[joinFieldName] = source;
	} else if(target.type == Json.Type.array) {
		enforce(source.type == Json.Type.array, source.toPrettyString());
		Json[] sArr = source.get!(Json[])();
		foreach(ref ulong idx, ref Json value; target) {
			enforce(idx < sArr.length, "Source array out of bounds "
					~ source.toPrettyString());
			joinInArray(value, sArr[idx], joinFieldName);
		}
	}
}
