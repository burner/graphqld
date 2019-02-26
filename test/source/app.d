import std.array;
import std.stdio;
import std.traits;
import std.conv;
import std.typecons;
import std.typecons;
import std.algorithm;

import std.experimental.logger;

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
			return this.executeQuery(op, this.jsonSchema["query"],
					Json.emptyObject()
				);
		} else if(op.ot.tok.type == TokenType.mutation) {
			assert(false, "Mutation not supported yet");
		} else if(op.ot.tok.type == TokenType.subscription) {
			assert(false, "Subscription not supported yet");
		}
		assert(false, "Unexpected");
	}

	Json executeQuery(OperationDefinition op, Json objectType,
			Json objectValue)
	{
		logf("%s", objectType["name"]);
		FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		Json tmp = this.executeSelection(selSet, objectType, objectValue);
		Json ret = Json.emptyObject();
		ret["data"] = tmp;
		ret["error"] = Json.emptyArray();
		return ret;
	}

	Json executeSelection(FieldRangeItem[] fields, Json objectType,
			Json objectValue)
	{
		logf("%s", objectType.jsonTypeToString());
		Json ret = Json.emptyObject();
		foreach(FieldRangeItem f; fields) {
			logf("field %s", f.name);
			Json tmp = executeFieldSelection(f, objectType, objectValue);
			ret[f.name] = tmp[f.name];
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, Json objectType,
			Json objectValue)
	{
		string objectTypeName = objectType["name"].get!string();
		logf("%s %s %s", objectTypeName, field.name,
				objectType.jsonTypeToString()
			);
		Json value;
		if(objectTypeName in this.resolver
				&& field.name in this.resolver[objectTypeName])
		{
			value = this.resolver[objectTypeName][field.name]
						(objectValue, Json.emptyObject, this.dummy);
		} else if(field.name in objectValue) {
			value = objectValue[field.name];
		} else {
			writeln("error");
			Json ret = Json.emptyObject();
			ret["error"] = Json.emptyArray();
			ret["error"] ~=
				format("%s %s", objectType.jsonTypeToString(), field.name);
			return ret;
		}
		if(field.hasSelectionSet()) {
			FieldRangeItem[] fsa = field.selectionSet().array;
			assert(objectTypeName in this.jsonSchema);
			assert("members" in this.jsonSchema[objectTypeName]);
			assert(field.name in this.jsonSchema[objectTypeName]["members"]);
			assert("type" in
					this.jsonSchema[objectTypeName]["members"][field.name]
				);
			assert("data" in value);
			value = this.executeSelectionSet(fsa,
					this.jsonSchema.getTypeByName(
						this.jsonSchema[objectTypeName]["members"][field.name]["type"]
							["name"].get!string()
					),
					value["data"]
				);
		}

		Json ret = Json.emptyObject();
		ret[field.name] = value;
		return ret;
	}

	Json executeSelectionSet(FieldRangeItem[] fields, Json objectType,
			Json objectValue)
	{
		logf("%s %s", objectType.jsonTypeToString(), objectType);
		if(objectType.isList()) {
			logf("list");
			return this.executeList(fields, objectType, objectValue);
		} else if(objectType.isObject()) {
			logf("object");
			return this.executeSelection(fields, objectType, objectValue);
		} else if(objectType.isLeaf()) {
			return objectValue;
		}
		assert(false);
	}

	Json executeList(FieldRangeItem[] fields, Json objectType,
			Json objectValue)
	{
		assert(objectValue.type == Json.Type.array);
		string objectTypeName = objectType["name"].get!string();
		Json itemType = this.jsonSchema.getTypeByName(objectTypeName);
		logf("%s", itemType.jsonTypeToString());

		Json ret = Json.emptyArray();
		foreach(Json item; objectValue) {
			ret ~= this.executeSelectionSet(fields, itemType, item);
		}
		return ret;
	}
}

GraphQLD!(Schema) graphqld;

void main() {
	graphqld = new GraphQLD!Schema();
 	database = new Data();

	//Json sch = toSchema!Schema();
	//writeln(sch.toPrettyString());

	// starships resolver
	graphqld.setResolver("query", "starships", delegate(Json parent,
			Json args, typeof(graphqld).QueryContext context)
	{
		Json ret = Json.emptyObject;
		ret["data"] = Json.emptyArray;
		ret["error"] = Json.emptyArray;
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

	graphqld.setResolver("Starship", "commander", delegate(Json parent,
			Json args, typeof(graphqld).QueryContext context)
	{
		Json ret = Json.emptyObject;
		ret["data"] = Json.emptyObject;
		ret["error"] = Json.emptyArray;
		foreach(c; database.chars) {
			if(c.id == parent["commanderId"]) {
				ret["data"]["id"] = c.id;
				ret["data"]["name"] = c.name;
				ret["data"]["series"] = serializeToJson(c.series);
				ret["data"]["commandsIds"] =
					serializeToJson(c.commands.map!(crew => crew.id).array);
			}
		}
		return ret;
	});

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	runApplication();
}

void hello(HTTPServerRequest req, HTTPServerResponse res) {
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

	res.writeJsonBody(gqld);
}
