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

void main() {
	server = new GraphqlServer();
 	database = new Data();

	Json sch = toSchema!Schema();
	writeln(sch.toPrettyString());

	// starships resolver
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

	auto dr = opDefRange(d);
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
	}
	//writeln(ret);

	res.writeJsonBody(ret);
}
