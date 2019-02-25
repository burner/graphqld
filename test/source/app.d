import std.array;
import std.stdio;
import std.traits;
import std.conv;
import std.typecons;
import std.typecons;
import std.algorithm;

import vibe.vibe;
import vibe.data.json;

import parser;
import builder;
import lexer;
import ast;
import tokenmodule;
import visitor;
import treevisitor;

import testdata;
import schema;

Data database;

struct StackElem {
	Json json;
	string name;
	bool isQuery;
	//const(Field) field;

	bool isArray() const {
		return this.json.type == Json.Type.object
			&& "data" in this.json
			&& this.json["data"].type == Json.Type.array;
	}

	void makeSureExists() {
		if(this.json.type != Json.Type.object) {
			this.json = Json.emptyObject();
		}
	}

	void putData(Json data) {
		this.makeSureExists();
		this.json["data"] = data;
	}

	void putError(Json data) {
		this.makeSureExists();
		this.json["error"] = data;
	}
}

string pathStackToResolve(StackElem[] stack) {
	return stack.map!(e => to!string(e.name))
			.filter!(e => !e.empty)
			.joiner(".")
			.to!string();
}

void push(ref StackElem[] stack) {
	StackElem elem;
	stack ~= elem;
}

Json getParentData(ref StackElem[] stack) {
	return (stack.length > 1) ? stack[$ - 1].json : Json.emptyObject;
}

class Resolver(Impl) : Visitor {
	alias enter = Visitor.enter;
	alias exit = Visitor.exit;

	Impl impl;
	StackElem[] stack;
	Json ret;

	this(Impl impl) {
		this.impl = impl;
	}

	Json resolve(Document doc) {
		return this.resolve(cast(const(Document))doc);
	}

	Json resolve(const(Document) doc) {
		this.ret = Json.emptyObject();
		this.ret["data"] = Json.emptyObject();
		this.ret["error"] = Json.emptyObject();

		this.accept(doc);
		return ret;
	}

	override void enter(const(Selection) sel) {
		this.stack.push();
	}

	override void exit(const(Selection) sel) {
		this.stack.popBack();
	}

	override void enter(const(Field) sel) {
		this.stack.back.name = sel.name.name.value;
		string p = this.stack.pathStackToResolve();
		QueryReturnValue qrv =
			this.impl.executeQuery(p, this.stack.getParentData(),
				Json.emptyObject
			);
		writefln("%s %s",p, qrv);
		if(qrv.data.type != Json.Type.undefined) {
			this.stack.back.putData(qrv.data["data"]);
		}
	}
}

struct QueryReturnValue {
	Json data;
	Json error;

	static QueryReturnValue opCall() {
		QueryReturnValue ret;
		ret.data = Json.emptyObject;
		ret.error = Json.emptyObject;
		return ret;
	}
}

struct DefaultContext {
}

Document parseGraph(HTTPServerRequest req) {
	Json j = req.json;
	enforce("query" in j);
	string toParse = j["query"].get!string();
	auto l = Lexer(toParse);
	auto p = Parser(l);
	return p.parseDocument();
}

class GraphqlServerImpl(QContext) {
	alias QueryContext = QContext;
	alias QueryResolver = QueryReturnValue delegate(Json parent,
			Json args, QueryContext context);

	Resolver!(typeof(this)) resolver;
	QueryResolver[string] queryResolver;
	QueryContext context;

	this() {
		this.resolver = new Resolver!(typeof(this))(this);
	}

	QueryReturnValue executeQuery(string path, Json parent, Json args)
	{
		QueryReturnValue value;
		if(path in this.queryResolver) {
			value = this.queryResolver[path](parent, args, context);
		}
		return value;
	}

	void entryPoint(HTTPServerRequest req, HTTPServerResponse res) {
		Json ret = Json.emptyObject();
		ret["data"] = Json.emptyObject();
		ret["error"] = Json.emptyArray();
		scope(exit) {
			writeln(ret);
			//res.writeJsonBody(ret);
		}

		Document ast;
		try {
			ast = parseGraph(req);
		} catch(Exception e) {
			ret["error"] ~= e.toString();
			ast = null;
		}

		if(ast is null) {
			return;
		}

		resolver.accept(cast(const(Document))ast);
	}
}

alias GraphqlServer = GraphqlServerImpl!(DefaultContext);

GraphqlServer server;

class GraphQLD(T, QContext = DefaultContext) {
	alias QueryContext = QContext;
	alias QueryResolver = Json delegate(Json parent,
			Json args, QueryContext context);

	QueryResolver[string][string] resolver;

	Json jsonSchema;
	Document doc;

	QueryContext dummy;

	this() {
		this.jsonSchema = toSchema!T();
		writeln(this.jsonSchema.toPrettyString());
	}

	Json execute(Document doc) {
		this.doc = doc;
		OperationDefinition opDef = this.getOperation(this.doc, "");
		return this.executeRequest(opDef, Json.emptyObject(),
				Json.emptyObject()
			);
	}

	void setResolver(string type, string field, QueryResolver qr) {
		if(type !in this.resolver) {
			this.resolver[type] = QueryResolver[string].init;
		}
		this.resolver[type][field] = qr;
	}

	OperationDefinition[] getOperations(Document doc) {
		return opDefRange(doc).map!(op => op.def.op).array;
	}

	OperationDefinition getOperation(Document doc, string name) {
		OperationDefinition[] ops = this.getOperations(doc);
		if(name.empty) {
			if(ops.length == 1) {
				return ops.front;
			}
			throw new Exception("name required");
		}
		auto ret = ops.find!(op => op.name.value == name)();
		if(ret.empty) {
			throw new Exception("operation not found");
		}
		return ret.front;
	}

	Json executeRequest(OperationDefinition op, Json coervedVariablesValues,
			Json initialValue)
	{
		if(op.ruleSelection == OperationDefinitionEnum.SelSet
				|| op.ot.tok.type == TokenType.query)
		{
			return this.executeQuery(op, coervedVariablesValues, initialValue);
		} else if(op.ot.tok.type == TokenType.mutation) {
			assert(false, "Mutation not supported yet");
		} else if(op.ot.tok.type == TokenType.subscription) {
			assert(false, "Subscription not supported yet");
		}
		assert(false, "Unexpected");
	}

	Json executeQuery(OperationDefinition op, Json coervedVariablesValues,
			Json initialValue)
	{
		Json ret = Json.emptyObject();
		ret["data"] = Json.emptyObject();
		ret["error"] = Json.emptyArray();
		assert("query" in jsonSchema);
		Json queryType = jsonSchema["query"];

		FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		Json selSetRet = this.executeSelectionSet(selSet, queryType,
				coervedVariablesValues, initialValue);
		ret["data"] = selSetRet;

		return ret;
	}

	Json executeSelectionSet(FieldRangeItem[] selectionSet, Json objectType,
			Json coervedVariablesValues, Json initialValue)
	{
		Json ret = Json.emptyObject;
		foreach(FieldRangeItem field; selectionSet) {
			string fieldName = field.aka.empty ? field.name : field.aka;

			string objectTypeName = objectType["name"].get!string();
			if(field.name in this.resolver[objectTypeName]) {
				Json responseValue = this.executeField(objectType, initialValue,
						field, coervedVariablesValues);
				ret[fieldName] = responseValue;
			}
		}
		return ret;
	}

	Json executeField(Json objectType, Json objectValue, FieldRangeItem field,
			Json coervedVariablesValues)
	{
		Json arguments = Json.emptyObject(); // this.coerceArgumentValue
		Json resolvedValue = this.resolveFieldValue(field, objectValue,
				objectType, arguments);
		return this.completeValue(field, resolvedValue,
				objectType["members"][field.name]["type"],
				coervedVariablesValues);
	}

	// Calling the callback in here
	Json resolveFieldValue(FieldRangeItem field, Json objectValue,
			Json objectType, Json arguments)
	{
		string objectTypeName = objectType["name"].get!string();
		writefln("%s %s %s", __LINE__, objectTypeName,
				objectType.toPrettyString()
			);
		assert(objectTypeName in this.resolver);
		assert(field.name in this.resolver[objectTypeName]);
		Json tmp = this.resolver[objectTypeName][field.name]
			(objectValue, arguments, this.dummy);
		return this.completeValue(field, tmp["data"],
				objectType["members"][field.name]["type"],
				arguments
			);
	}

	Json completeValue(FieldRangeItem field, Json objectValue,
			Json objectType, Json coervedVariablesValues)
	{
		/*if(!objectType.isNullable()) {
			Json completed = this.completeValue(field, objectValue,
					objectType.removeNullable(), coervedVariablesValues
				);
			if(completed.type == Json.Type.undefined
					|| completed.type == Json.Type.null_)
			{
				throw new Exception(
						"Can not return null value for non-nullable"
					);
			}
			return completed;
		}

		if(objectValue.type == Json.Type.undefined
				|| objectValue.type == Json.Type.null_)
		{
			return objectValue;
		}

		if(objectType.isList()) {
			return this.completeListValue(field, objectValue,
					objectType, coervedVariablesValues
				);
		}

		if(objectType.isLeaf()) {
			return objectValue;
		}

		if(objectType.isObject()) {
			return this.completeObjectValue(field, objectType, objectValue,
					coervedVariablesValues
				);
		}
		assert(false, "Should never happen");
		*/
		if(objectType.isList()) {
			Json ret = Json.emptyArray();
			Json subObjectType = this.schema.getTypeByName(
					objectType.typeName()
				);
			foreach(item; objectValue.array()) {
				ret ~= completeValue(field, item, subObjectType,
							coervedVariablesValues
						);
			}
			return ret;
		}
	}

	Json completeObjectValue(FieldRangeItem field, Json objectValue,
			Json objectType, Json coervedVariablesValues)
	{
		writefln("%s %s %s", __LINE__, objectType.toPrettyString(),
				objectValue.toPrettyString());

		return this.collectAndExecuteSubfields(field, objectValue, objectType,
				coervedVariablesValues
			);

	}

	Json collectAndExecuteSubfields(FieldRangeItem field, Json objectValue,
			Json objectType, Json coervedVariablesValues)
	{
	}

	/*Json completeValue(FieldRangeItem field, Json objectValue,
			Json objectType, Json coervedVariablesValues)
	{
		writefln("<<<%s %s %s>>>", __LINE__, objectValue.toPrettyString(),
				objectType.toPrettyString());
		Json ret;
		if(objectType.isList()) {
			string innerTypeName = objectType.typeName();
			Json innerType = this.jsonSchema.getTypeByName(innerTypeName);
			writefln("%s %s %s", __LINE__, innerTypeName,
					innerType.toPrettyString()
				);
			ret = Json.emptyArray();
			if(field.hasSelectionSet()) {
				foreach(item; objectValue.array()) {
					writefln("%s %s", __LINE__, item.toPrettyString());
					Json tmp = Json.emptyObject();
					foreach(FieldRangeItem s; field.selectionSet()) {
						writefln("%s %s %s %s", __LINE__, s.name,
								innerType["members"].type,
								innerType["members"].toPrettyString());
						if(s.name in innerType["members"]) {
							writefln("%s %s %s", __LINE__, item.toPrettyString(),
									item[s.name]);
							tmp[s.name] = item[s.name];
						}
					}
					ret ~= tmp;
				}
			}
		}
		writefln("%s %s", __LINE__, ret.toPrettyString());
		return ret;
	}*/

}

GraphQLD!(Schema) graphqld;

void main() {
	server = new GraphqlServer();
	graphqld = new GraphQLD!Schema();
 	database = new Data();

	//Json sch = toSchema!Schema();
	//writeln(sch.toPrettyString());

	// starships resolver
	graphqld.setResolver("query", "starships", delegate(Json parent,
			Json args, GraphqlServer.QueryContext context)
	{
		Json ret = Json.emptyObject;
		ret["data"] = Json.emptyObject;
		ret["data"] = Json.emptyArray;
		foreach(ship; database.ships) {
			Json tmp = Json.emptyObject;
			static foreach(mem; [ "id", "designation", "size"]) {
				tmp[mem] = __traits(getMember, ship, mem);
			}
			tmp["commanderId"] = ship.commander.id;
			tmp["crewIds"] = serializeToJson(ship.crew.map!(c => c.id).array);
			tmp["series"] = serializeToJson(ship.series);

			ret["data"] ~= tmp;
		}
		return ret;
	});

	server.queryResolver["starships"] = delegate(Json parent,
			Json args, GraphqlServer.QueryContext context)
	{
		QueryReturnValue ret;
		ret.data = Json.emptyObject;
		ret.data["data"] = Json.emptyArray;
		foreach(ship; database.ships) {
			Json tmp = Json.emptyObject;
			static foreach(mem; [ "id", "designation", "size"]) {
				tmp[mem] = __traits(getMember, ship, mem);
			}
			ret.data["data"] ~= tmp;
		}
		return ret;
	};

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	runApplication();
}

void hello(HTTPServerRequest req, HTTPServerResponse res) {
	server.entryPoint(req, res);
	Json j = req.json;
	string toParse;
	if("query" in j) {
		toParse = j["query"].get!string();
	} else {
		toParse = j["mutation"].get!string();
	}
	auto l = Lexer(toParse);
	auto p = Parser(l);
	Document d;
	Json ret = Json.emptyObject;
	ret["data"] = Json.emptyObject;
	ret["error"] = Json.emptyArray;
	try {
		d = p.parseDocument();
	} catch(Throwable e) {
		auto app = appender!string();
		while(e) {
			app.put(e.toString());
			e = cast(Exception)e.next;
		}
		ret["error"] ~= Json(app.data);
		res.writeBody("Failed to parse " ~ app.data);
		return;
	}

	auto tv = new TreeVisitor(0);
	tv.accept(cast(const(Document))d);

	Json gqld = graphqld.execute(d);
	writeln(gqld.toPrettyString());

	/*auto dr = opDefRange(d);
	foreach(it; dr) {
		//writeln("Def range ", it.fieldRange().empty);
		foreach(jt; it.fieldRange()) {
			//writeln("\tField Range ", jt.name, " ", jt.hasSelectionSet());
			switch(jt.name) {
				case "starships":
					if("starships" !in ret["data"]) {
						ret["data"]["starships"] = Json.emptyArray;
					}
					database.ships.each!(
						delegate(Starship s) {
							Json tmp = Json.emptyObject;
							foreach(ss; jt.selectionSet()) {
								static foreach(shipF; FieldNameTuple!(Starship)) {{
									alias Type = typeof(__traits(getMember, s, shipF));
									static if(isSomeString!(Type) || !isArray!(Type)) {
										if(ss.name() == shipF) {
											tmp[ss.name()] = serializeToJson(__traits(getMember, s, shipF));
										}
									}
								}}
							}
							ret["data"]["starships"] ~= tmp;
						}
					);
					break;
				default:
					//writeln(jt.name);
					break;
			}
			if(jt.hasSelectionSet()) {
				foreach(kt; jt.selectionSet()) {
					//writeln("\t\tSelection Set ", kt.name());
				}
			}
		}
	}*/
	//writeln(ret);

	res.writeJsonBody(gqld);
}
