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
import testdata2;
import schema;
import schema2;

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
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context);

	Document doc;

	alias Schema = GQLDSchema!(Con);
	Schema schema;

	Con dummy;

	this() {
		this.schema = toSchema2!(T,Con)();
		writeln(this.schema.toString());
	}

	void setResolver(string first, string second, QueryResolver resolver) {
		GQLDMap!(Con) fMap;
		if(first in this.schema.member) {
			fMap = this.schema.member[first].toMap();
		} else if(first in this.schema.types) {
			fMap = this.schema.types[first].toMap();
		}

		if(fMap is null || second !in fMap.member) {
			throw new Exception(format("Schema has no entry for %s %s",
							first, second)
						);
		}
		fMap.member[second].resolver = resolver;
	}

	Json execute(Document doc) {
		this.doc = doc;
		OperationDefinition[] ops = this.getOperations(this.doc);

		auto selSet = ops
			.find!(op => op.ruleSelection == OperationDefinitionEnum.SelSet);
		if(!selSet.empty) {
			if(ops.length > 1) {
				throw new Exception(
					"If SelectionSet the number of Operations must be 1"
					);
			}
			return this.executeOperation(selSet.front);
		}
		assert(false);
	}

	static OperationDefinition[] getOperations(Document doc) {
		return opDefRange(doc).map!(op => op.def.op).array;
	}

	Json executeOperation(OperationDefinition op)
	{
		if(op.ruleSelection == OperationDefinitionEnum.SelSet
				|| op.ot.tok.type == TokenType.query)
		{
			return this.executeQuery(op);
		} else if(op.ot.tok.type == TokenType.mutation) {
			assert(false, "Mutation not supported yet");
		} else if(op.ot.tok.type == TokenType.subscription) {
			assert(false, "Subscription not supported yet");
		}
		assert(false, "Unexpected");
	}

	Json executeQuery(OperationDefinition op) {
		log();
		FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		Json tmp = this.executeSelection(selSet,
						cast(GQLDMap!Con)this.schema.member["query"],
						Json.emptyObject()
					);
		return tmp;
	}

	Json executeSelection(FieldRangeItem[] fields, GQLDType!Con objectType,
			Json objectValue)
	{
		logf("%s", objectType.toString());
		Json ret = Json.emptyObject();
		ret["data"] = Json.emptyObject();
		ret["error"] = Json.emptyArray();
		auto map = objectType.toMap();
		if(map is null) {
			ret["error"] ~= Json(format("%s does not convert to map",
									objectType.toString())
								);
			return ret;
		}
		foreach(FieldRangeItem f; fields) {
			logf("field %s", f.name);
			if(map !is null && f.name in map.member) {
				auto fType = map.member[f.name];
				logf("found field %s %s", f.name,
						fType ? fType.toString() : "Unknown Type"
					);
				Json tmp = this.executeFieldSelection(f,
								map.member[f.name],
								objectValue
							);
				logf("%s", tmp);
				foreach(key, value; tmp["data"].byKeyValue) {
					ret["data"][key] = value;
				}
				foreach(err; tmp["error"].array()) {
					ret["error"] ~= err;
				}
			} else {
				ret["error"] ~= Json(format("field %s not present in type %s",
										f.name, objectType.toString())
									);
			}
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType!Con objectType,
			Json objectValue)
	{
		logf("%s %s", field.name, objectType.toString());
		Json de = objectType.resolver(field.name, objectValue,
						Json.emptyObject(), this.dummy
					);
		logf("%s", de);
		Json ret = Json.emptyObject();
		ret["data"] = Json.emptyObject();
		ret["error"] = Json.emptyArray();
		if(GQLDScalar!Con scalar =
				objectType.getReturnType(field.name).toScalar())
		{
			logf("scalar");
			if("data" in de) {
				ret["data"][field.name] = de["data"];
			}
			if("error" in de) {
				ret["error"] ~= de["error"];
			}
			logf("%s", ret);
			return ret;
		} else if(GQLDMap!Con map =
				objectType.getReturnType(field.name).toMap())
		{
			logf("map %s", map.toString());
			if(!field.hasSelectionSet()) {
				ret["error"] ~= Json("No selection set found for "
										~ field.name
									);
			} else {
				FieldRangeItem[] selSet = field.selectionSet().array;
				logf("selSet [%(%s, %)]", selSet.map!(a => a.name));
				Json tmp = this.executeSelection(selSet, map,
								"data" in de ? de["data"] : Json.emptyObject
							);
				if("data" in tmp) {
					ret["data"][field.name] = tmp["data"];
				}
				if("error" in de) {
					ret["error"] ~= tmp["error"];
				}
				return ret;
			}
		} else if(GQLDList!Con list =
				objectType.getReturnType(field.name).toList())
		{
			logf("list");
			if(!field.hasSelectionSet()) {
				ret["error"] ~= Json("No selection set found for "
										~ field.name
									);
			} else {
				auto elemType = list.elementType;
				assert(de["data"].type == Json.Type.array);
				FieldRangeItem[] selSet = field.selectionSet().array;
				Json tmp = Json.emptyArray();
				foreach(Json item; de["data"]) {
					Json itemRet = this.executeSelection(selSet, elemType,
										item
									);
					if("data" in itemRet) {
						tmp ~= itemRet["data"];
					}
					if("error" in de) {
						ret["error"] ~= itemRet["error"];
					}
				}
				ret["data"][field.name] = tmp;
				return ret;
			}
		} else {
			logf("else de %s", de);
			if(!field.hasSelectionSet()) {
				ret["error"] ~= Json("No selection set found for "
										~ field.name
									);
			} else {
				FieldRangeItem[] selSet = field.selectionSet().array;
				logf("selSet [%(%s, %)]", selSet.map!(a => a.name));
				Json tmp = this.executeSelection(selSet, objectType,
								"data" in de ? de["data"] : Json.emptyObject
							);
				if("data" in tmp) {
					ret["data"][field.name] = tmp["data"];
				}
				if("error" in de) {
					ret["error"] ~= tmp["error"];
				}
				return ret;
			}
		}
		return ret;
	}
}

GraphQLD!(Schema2) graphqld;

void main() {
	graphqld = new GraphQLD!Schema2();
	graphqld.setResolver("query", "foo",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				Json ret = Json.emptyObject;
				ret["data"] = 1337;
				return ret;
			}
		);
	graphqld.setResolver("query", "bar",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				Json ret = Json.emptyObject;
				ret["data"] = 7331;
				return ret;
			}
		);
	graphqld.setResolver("query", "small",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyObject;
				ret["data"]["id"] = 13;
				ret["data"]["name"] = "Hello Graphql";
				return ret;
			}
		);
	graphqld.setResolver("query", "manysmall",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				logf("many small resolver");
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyArray();
				foreach(i; 0 .. 3) {
					Json tmp = Json.emptyObject();
					tmp["id"] = i;
					tmp["name"] = format("Hello %s", i);
					ret["data"] ~= tmp;
				}
				return ret;
			}
		);
	graphqld.setResolver("Small", "child",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				logf("Small child resolver %s", parent);
				Json ret = Json.emptyObject;
				ret["error"] = Json.emptyArray();
				ret["data"] = Json.emptyObject();
				assert("id" in parent);
				ret["data"]["id"] = parent["id"].get!long() * 1000;

				assert("name" in parent);
				ret["data"]["name"] = parent["name"].get!string() ~ " child";
				return ret;
			}
		);
 	//database = new Data();

	//Json sch = toSchema!Schema();
	//writeln(sch.toPrettyString());

	// starships resolver

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
