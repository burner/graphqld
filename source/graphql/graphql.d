module graphql.graphql;

import std.array : array, front, empty;
import std.stdio;
import std.experimental.logger;
import std.traits;
import std.meta : AliasSeq;
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

class GQLDExecutionException : Exception {
	this(string msg, string f = __FILE__, size_t l = __LINE__) {
		super(msg, f, l);
		this.line = l;
	}
}

class GraphQLD(T, QContext = DefaultContext) {
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context) @safe;

	alias Schema = GQLDSchema!(T);
	immutable GQLDOptions options;

	// path information
	PathElement[] path;

	Schema schema;

	// the logger to use
	Logger executationTraceLog;
	Logger defaultResolverLog;
	Logger resolverLog;

	// [Type][field]
	QueryResolver[string][string] resolver;
	QueryResolver defaultResolver;

	this(GQLDOptions options = GQLDOptions.init) {
		this.options = options;
		this.schema = toSchema!(T)();
		this.executationTraceLog = new MultiLogger(LogLevel.off);
		this.defaultResolverLog = new MultiLogger(LogLevel.off);
		this.resolverLog = new MultiLogger(LogLevel.off);

		this.defaultResolver = delegate(string name, Json parent, Json args,
									ref Con context)
			{
				import std.format;
				this.defaultResolverLog.logf("name: %s, parent: %s, args: %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				if(parent.type != Json.Type.null_ && name in parent) {
					ret["data"] = Json.emptyObject();
					ret["data"] = parent[name];
				} else {
					ret[Constants.errors] = Json.emptyArray();
					ret.insertError(format(
							"no field name '%s' found on type '%s'",
									name,
									parent.getWithDefault!string("__typename")
							), this.path
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
		enforce(second !in this.resolver[first]);
		this.resolver[first][second] = resolver;
	}

	Json resolve(string type, string field, Json parent, Json args,
			ref Con context)
	{
		Json defaultArgs = this.getDefaultArguments(type, field);
		Json joinedArgs = joinJson!(JoinJsonPrecedence.a)(args, defaultArgs);
		//this.resolverLog.logf(
		//writefln("%s %s", type, field);
		assert(type != "__type" && field != "__ofType",
				parent.toPrettyString());
		this.resolverLog.logf(
				"type: %s field: %s defArgs: %s par: %s args: %s %s", type,
				field, defaultArgs, parent, args, joinedArgs
			);
		if(type !in this.resolver) {
			return defaultResolver(field, parent, joinedArgs, context);
		} else if(field !in this.resolver[type]) {
			return defaultResolver(field, parent, joinedArgs, context);
		} else {
			return this.resolver[type][field](field, parent, joinedArgs,
					context
				);
		}
	}

	Json getDefaultArgumentImpl(string typename, Type)(string type,
			string field)
	{
		static if(isAggregateType!Type) {
			if(typename == type) {
				switch(field) {
					static foreach(mem; __traits(allMembers, Type)) {
						static if(isCallable!(
								__traits(getMember, Type, mem))
							)
						{
							case mem: {
								alias parNames = ParameterIdentifierTuple!(
										__traits(getMember, Type, mem)
									);
								alias parDef = ParameterDefaultValueTuple!(
										__traits(getMember, Type, mem)
									);

								Json ret = Json.emptyObject();
								static foreach(i; 0 .. parNames.length) {
									static if(!is(parDef[i] == void)) {
										ret[parNames[i]] =
											serializeToJson(parDef[i]);
									}
								}
								return ret;
							}
						}
					}
					default: break;
				}
			}
		}
		return Json.init;
	}

	Json getDefaultArguments(string type, string field) {
		import graphql.traits : collectTypes;
		switch(type) {
			static foreach(Type; collectTypes!(T)) {{
				case Type.stringof: {
					Json tmp = getDefaultArgumentImpl!(Type.stringof, Type)(
							type, field
						);
					if(tmp.type != Json.Type.undefined
							&& tmp.type != Json.Type.null_)
					{
						return tmp;
					}
				}
			}}
			default: {}
		}
		// entryPoint == ["query", "mutation", "subscription"];
		switch(type) {
			static foreach(entryPoint; FieldNameTuple!T) {{
				case entryPoint: {
					Json tmp = getDefaultArgumentImpl!(entryPoint,
							typeof(__traits(getMember, T, entryPoint)))
						(type, field);
					if(tmp.type != Json.Type.undefined
							&& tmp.type != Json.Type.null_)
					{
						return tmp;
					}
				}
			}}
			default: break;
		}
		defaultRet:
		return Json.init;
	}

	Json execute(Document doc, Json variables, ref Con context) @trusted {
		import std.algorithm.searching : canFind, find;
		OperationDefinition[] ops = this.getOperations(doc);

		Json ret = Json.emptyObject();
		ret[Constants.data] = Json.emptyObject();
		foreach(op; ops) {
			Json tmp = this.executeOperation(op, variables, doc, context);
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
			Document doc, ref Con context)
	{
		this.path ~= PathElement(op.name.value);
		scope(exit) {
			this.path = this.path[0 .. $ - 1];
		}
		bool dirSaysToContinue = continueAfterDirectives(op.d, variables);
		if(!dirSaysToContinue) {
			return returnTemplate();
		}
		if(op.ruleSelection == OperationDefinitionEnum.SelSet
				|| op.ot.tok.type == TokenType.query)
		{
			return this.executeQuery(op, variables, doc, context);
		} else if(op.ot.tok.type == TokenType.mutation) {
			return this.executeMutation(op, variables, doc, context);
		} else if(op.ot.tok.type == TokenType.subscription) {
			assert(false, "Subscription not supported yet");
		}
		assert(false, "Unexpected");
	}

	Json executeMutation(OperationDefinition op, Json variables,
			Document doc, ref Con context)
	{
		this.executationTraceLog.log("mutation");
		Json tmp = this.executeSelections(op.ss.sel,
				this.schema.member["mutationType"], Json.emptyObject(),
				variables, doc, context
			);
		return tmp;
	}

	Json executeQuery(OperationDefinition op, Json variables, Document doc,
			ref Con context)
	{
		this.executationTraceLog.log("query");
		Json tmp = this.executeSelections(op.ss.sel,
				this.schema.member["queryType"],
				Json.emptyObject(), variables, doc, context
			);
		return tmp;
	}

	Json executeSelections(Selections sel, GQLDType objectType,
			Json objectValue, Json variables, Document doc, ref Con context)
	{
		import graphql.traits : interfacesForType;
		Json ret = returnTemplate();
		this.executationTraceLog.logf("OT: %s, OJ: %s, VAR: %s",
				objectType.name, objectValue, variables);
		this.executationTraceLog.logf("TN: %s", interfacesForType!(T)(
				objectValue
					.getWithDefault!string("data.__typename", "__typename")
			));
		foreach(FieldRangeItem field;
				fieldRangeArr(
					sel,
					doc,
					interfacesForType!(T)(objectValue.getWithDefault!string(
							"data.__typename", "__typename")
						),
					variables)
			)
		{
			//Json args = getArguments(field, variables);
			bool dirSaysToContinue = continueAfterDirectives(
					field.f.dirs, variables);

			Json rslt = dirSaysToContinue
				? this.executeFieldSelection(field, objectType,
						objectValue, variables, doc, context
					)
				: Json.emptyObject();

			const string name = field.f.name.name.value;
			ret.insertPayload(name, rslt);
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType objectType,
			Json objectValue, Json variables, Document doc, ref Con context)
	{
		this.path ~= PathElement(field.name);
		scope(exit) {
			this.path = this.path[0 .. $ - 1];
		}
		this.executationTraceLog.logf("FRI: %s, OT: %s, OV: %s, VAR: %s",
				field.name, objectType.name, objectValue, variables
			);
		Json arguments = getArguments(field, variables);
		writefln("obj %s\nvar %s\narg %s", objectValue, variables, arguments);
		Json de;
		try {
			de = this.resolve(objectType.name,
					field.aka.empty ? field.name : field.aka,
				"data" in objectValue ? objectValue["data"] : objectValue,
				arguments, context
			);
		} catch(GQLDExecutionException e) {
			auto ret = Json.emptyObject();
			ret[Constants.data] = Json(null);
			ret[Constants.errors] = Json.emptyArray();
			ret.insertError(e.msg);
			return ret;
		}
		if(de.dataIsEmpty()) {
			return de;
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
				doc, context
			);
	}

	Json executeSelectionSet(SelectionSet ss, GQLDType objectType,
			Json objectValue, Json variables, Document doc, ref Con context)
	{
		Json rslt;
		if(GQLDMap map = objectType.toMap()) {
			this.executationTraceLog.logf("map %s %s", map.name, ss !is null);
			enforce(ss !is null && ss.sel !is null, format(
					"ss null %s, ss.sel null %s", ss is null,
					(ss is null) ? true : ss.sel is null));
			rslt = this.executeSelections(ss.sel, map, objectValue, variables,
					doc, context
				);
		} else if(GQLDNonNull nonNullType = objectType.toNonNull()) {
			this.executationTraceLog.logf("NonNull %s",
					nonNullType.elementType.name
				);
			rslt = this.executeSelectionSet(ss, nonNullType.elementType,
					objectValue, variables, doc, context
				);
			if(rslt.dataIsNull()) {
				this.executationTraceLog.logf("%s", rslt);
				rslt.insertError("NonNull was null");
			}
		} else if(GQLDNullable nullType = objectType.toNullable()) {
			this.executationTraceLog.logf("nullable %s", nullType.name);
			rslt = this.executeSelectionSet(ss, nullType.elementType,
					objectValue, variables, doc, context
				);
			this.executationTraceLog.logf("IIIIIS EMPTY %s rslt %s",
					rslt.dataIsEmpty(), rslt
				);
			if(rslt.dataIsEmpty()) {
				rslt["data"] = null;
				rslt.remove(Constants.errors);
			}
		} else if(GQLDList list = objectType.toList()) {
			this.executationTraceLog.logf("list %s", list.name);
			rslt = this.executeList(ss, list, objectValue, variables, doc,
					context
				);
		} else if(GQLDScalar scalar = objectType.toScalar()) {
			rslt = objectValue;
		}

		return rslt;
	}

	private void toRun(SelectionSet ss, GQLDType elemType, Json item,
			Json variables, ref Json ret, Document doc, ref Con context)
		@trusted
	{
		this.executationTraceLog.logf("ET: %s, item %s", elemType.name,
				item
			);
		Json tmp = this.executeSelectionSet(ss, elemType, item, variables,
				doc, context
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

	Json executeList(SelectionSet ss, GQLDList objectType,
			Json objectValue, Json variables, Document doc, ref Con context)
			@trusted
	{
		this.executationTraceLog.logf("OT: %s, OJ: %s, VAR: %s",
				objectType.name, objectValue, variables
			);
		assert("data" in objectValue, objectValue.toString());
		GQLDType elemType = objectType.elementType;
		this.executationTraceLog.logf("elemType %s", elemType);
		Json ret = returnTemplate();
		ret["data"] = Json.emptyArray();
		if(this.options.asyncList == AsyncList.yes) {
			Task[] tasks;
			foreach(Json item;
					objectValue["data"].type == Json.Type.array
						? objectValue["data"]
						: Json.emptyArray()
				)
			{
				tasks ~= runTask({
					this.toRun(ss, elemType, item, variables, ret, doc,
							context
						);
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
				this.path ~= PathElement(idx);
				++idx;
				scope(exit) {
					this.path = this.path[0 .. $ - 1];
				}
				this.toRun(ss, elemType, item, variables, ret, doc, context);
			}
		}
		return ret;
	}
}

import graphql.uda;

@GQLDUda(TypeKind.OBJECT)
private struct Query {
	import std.datetime : DateTime;

	GQLDCustomLeaf!DateTime current();
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
					GQLDCustomLeaf!(DateTime, toStringImpl));
	//static assert(is(a == exp), format("\n%s\n%s", a.stringof, exp.stringof));

	//pragma(msg, InheritedClasses!Schema);

	//auto g = new GraphQLD!(Schema,int)();
}
