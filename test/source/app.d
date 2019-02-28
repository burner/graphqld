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

Json returnTemplate() {
	Json ret = Json.emptyObject();
	ret["data"] = Json.emptyObject();
	ret["error"] = Json.emptyArray();
	return ret;
}

void insertPayload(ref Json result, string field, Json data) {
	enum d = "data";
	enum e = "error";
	if(d in data) {
		enforce(result[d].type == Json.Type.object);
		result[d][field] = data[d];
	}
	if(e in data) {
		enforce(result[e].type == Json.Type.array);
		if(!canFind(result[e].array(), data[e])) {
			result[e] ~= data[e];
		}
	}
}

class GraphQLD(T, QContext = DefaultContext) {
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context) @safe;

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

	Json execute(Document doc, Json variables) {
		this.doc = doc;
		OperationDefinition[] ops = this.getOperations(this.doc);
		logf("Vars %s", variables);

		auto selSet = ops
			.find!(op => op.ruleSelection == OperationDefinitionEnum.SelSet);
		if(!selSet.empty) {
			if(ops.length > 1) {
				throw new Exception(
					"If SelectionSet the number of Operations must be 1"
					);
			}
			return this.executeOperation(selSet.front, variables);
		}

		Json ret = returnTemplate();
		foreach(op; ops) {
			Json tmp = this.executeOperation(op, variables);
			logf("%s\n%s", ret, tmp);
			if(canFind([OperationDefinitionEnum.OT_N,
					OperationDefinitionEnum.OT_N_D,
					OperationDefinitionEnum.OT_N_V,
					OperationDefinitionEnum.OT_N_VD], op.ruleSelection))
			{
				logf("%s", op.name.value);
				ret["data"][op.name.value] = tmp["data"];
				foreach(err; tmp["error"]) {
					ret["error"] ~= err;
				}
			}
		}
		return ret;
	}

	static OperationDefinition[] getOperations(Document doc) {
		return opDefRange(doc).map!(op => op.def.op).array;
	}

	Json executeOperation(OperationDefinition op, Json variables) {
		if(op.ruleSelection == OperationDefinitionEnum.SelSet
				|| op.ot.tok.type == TokenType.query)
		{
			return this.executeQuery(op, variables);
		} else if(op.ot.tok.type == TokenType.mutation) {
			return this.executeMutation(op, variables);
		} else if(op.ot.tok.type == TokenType.subscription) {
			assert(false, "Subscription not supported yet");
		}
		assert(false, "Unexpected");
	}

	Json executeMutation(OperationDefinition op, Json variables) {
		log("mutation");
		FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		Json tmp = this.executeSelection(selSet,
						cast(GQLDMap!Con)this.schema.member["mutation"],
						Json.emptyObject(), variables
					);
		return tmp;
	}

	Json executeQuery(OperationDefinition op, Json variables) {
		log("query");
		FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		Json tmp = this.executeSelection(selSet,
						cast(GQLDMap!Con)this.schema.member["query"],
						Json.emptyObject(), variables
					);
		return tmp;
	}

	Json executeSelection(FieldRangeItem[] fields, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		logf("%s", objectType.toString());
		Json ret = returnTemplate();

		auto map = objectType.toMap();
		if(map is null) {
			ret["error"] ~= Json(format("%s does not convert to map",
									objectType.toString())
								);
			return ret;
		}
		logf("%(%s, %)", fields.map!(a => a.name));
		foreach(FieldRangeItem f; fields) {
			logf("field %s", f.name);
			if(map !is null && f.name in map.member) {
				auto fType = map.member[f.name];
				logf("found field %s %s", f.name,
						fType ? fType.toString() : "Unknown Type"
					);
				Json tmp = this.executeFieldSelection(f, map.member[f.name],
								objectValue, variables
							);
				logf("%s", tmp);
				foreach(key, value; tmp["data"].byKeyValue) {
					ret["data"][key] = value;
				}
				foreach(err; tmp["error"].array()) {
					ret["error"] ~= err;
				}
			} else if(map !is null && map.name == "query"
					&& f.name == "__schema")
			{
				Json tmp = this.executeFieldSelection(f, this.schema.__schema,
								objectValue, variables
							);
			} else if(map !is null && map.name == "query"
					&& f.name == "__type")
			{
				Json tmp = this.executeFieldSelection(f, this.schema.__type,
								objectValue, variables
							);
			} else {
				ret["error"] ~= Json(format("field %s not present in type %s",
										f.name, objectType.toString())
									);
			}
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		logf("%s %s", field.name, objectType.toString());
		Json arguments = getArguments(field, variables);
		logf("args %s", arguments);
		Json de = objectType.resolver(field.name, objectValue,
						arguments, this.dummy
					);
		logf("%s", de);
		Json ret = Json.emptyObject();
		ret["data"] = Json.emptyObject();
		ret["error"] = Json.emptyArray();
		if(GQLDScalar!Con scalar =
				this.schema.getReturnType(objectType, field.name).toScalar())
		{
			logf("scalar");
			ret.insertPayload(field.name, de);
			logf("%s", ret);
			return ret;
		} else if(GQLDMap!Con map =
				this.schema.getReturnType(objectType, field.name).toMap())
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
								"data" in de ? de["data"] : Json.emptyObject,
								arguments
							);
				ret.insertPayload(field.name, tmp);
				return ret;
			}
		} else if(GQLDNullable!Con nullType =
				this.schema.getReturnType(objectType, field.name).toNullable())
		{
			logf("nullable");
			if(!field.hasSelectionSet()) {
				ret["error"] ~= Json("No selection set found for "
										~ field.name
									);
			} else {
				if("data" !in de || de["data"].length == 0) {
					ret["data"][field.name] = null;
				} else {
					auto elemType = nullType.elementType;
					FieldRangeItem[] selSet = field.selectionSet().array;
					Json tmp = this.executeSelection(selSet, elemType,
									"data" in de ? de["data"] : Json.emptyObject,
									arguments
								);
					ret.insertPayload(field.name, tmp);
				}
			}
			return ret;
		} else if(GQLDList!Con list =
				this.schema.getReturnType(objectType, field.name).toList())
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
										item, arguments
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
								"data" in de ? de["data"] : Json.emptyObject,
								arguments
							);
				ret.insertPayload(field.name, tmp);
				return ret;
			}
		}
		return ret;
	}

	Json getArguments(FieldRangeItem item, Json variables) {
		auto ae = new ArgumentExtractor(variables);
		ae.accept(cast(const(Field))item.f);
		return ae.arguments;
	}
}

class ArgumentExtractor : Visitor {
	alias enter = Visitor.enter;
	alias exit = Visitor.exit;

	Json arguments;
	Json variables;

	string[] curNames;

	this(Json variables) {
		this.variables = variables;
		this.arguments = Json.emptyObject();
	}

	void assign(Json toAssign) {
		Json* arg = &this.arguments;
		assert(!this.curNames.empty);
		foreach(idx; 0 .. this.curNames.length - 1) {
			arg = &((*arg)[this.curNames[idx]]);
		}

		if(this.curNames.back in (*arg)
				&& ((*arg)[this.curNames.back]).type == Json.Type.array)
		{
			((*arg)[this.curNames.back]) ~= toAssign;
		} else {
			((*arg)[this.curNames.back]) = toAssign;
		}
	}

	override void enter(const(Argument) arg) {
		this.curNames ~= arg.name.value;
	}

	override void exit(const(Argument) arg) {
		this.curNames.popBack();
	}

	override void enter(const(Variable) var) {
		string varName = var.name.value;
		enforce(varName in this.variables,
				format("Variable with name %s required", varName)
			);
		this.assign(this.variables[varName]);
	}

	override void enter(const(Value) val) {
		switch(val.ruleSelection) {
			case ValueEnum.STR:
				this.assign(Json(val.tok.value));
				break;
			case ValueEnum.INT:
				this.assign(Json(to!long(val.tok.value)));
				break;
			case ValueEnum.FLOAT:
				this.assign(Json(to!double(val.tok.value)));
				break;
			case ValueEnum.T:
				this.assign(Json(true));
				break;
			case ValueEnum.F:
				this.assign(Json(false));
				break;
			case ValueEnum.ARR:
				this.assign(Json.emptyArray());
				break;
			default:
				throw new Exception(format("Value type %s not supported",
							val.ruleSelection
						));
		}
	}
}

GraphQLD!(Schema) graphqld;

void main() {
 	database = new Data();
	graphqld = new GraphQLD!Schema();
	graphqld.setResolver("query", "starships",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
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
					tmp["crewIds"] = serializeToJson(
											ship.crew.map!(c => c.id).array
										);
					tmp["series"] = serializeToJson(ship.series);

					ret["data"] ~= tmp;
				}
				return ret;
			}
		);

	graphqld.setResolver("query", "starship",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				assert("id" in args);
				long id = args["id"].get!long();
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyObject;
				ret["error"] = Json.emptyArray;
				auto theShip = database.ships.find!(s => s.id == id);
				if(!theShip.empty) {
					Starship ship = theShip.front;
					Json tmp = Json.emptyObject;
					static foreach(mem; [ "id", "designation", "size"]) {
						tmp[mem] = __traits(getMember, ship, mem);
					}
					tmp["commanderId"] = ship.commander.id;
					tmp["crewIds"] = serializeToJson(
											ship.crew.map!(c => c.id).array
										);
					tmp["series"] = serializeToJson(ship.series);

					ret["data"] = tmp;
				}
				logf("%s", ret);
				return ret;
			}
		);

	graphqld.setResolver("mutation", "addCrewman",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con) @trusted
			{
				assert("shipId" in args);
				long shipId = args["shipId"].get!long();
				assert("name" in args);
				string nname = args["name"].get!string();
				logf("%s %s", shipId, nname);

				Json ret = returnTemplate();

				auto theShip = database.ships.find!(s => shipId == s.id);
				if(!theShip.empty) {
					Starship ship = theShip.front;
					auto nh = new Humanoid(database.i++, nname, "Human");
					ship.crew ~= nh;
					nh.ship = nullable(ship);
					ret["data"]["id"] = nh.id;
					ret["data"]["name"] = nh.name;
					ret["data"]["shipId"] = ship.id;
				} else {
					ret["error"] ~= Json(format(
											"Ship with id %s does not exist",
											shipId
										));
				}

				return ret;
			}
		);
	graphqld.setResolver("query", "shipsselection",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con) @trusted
			{
				assert("ids" in args);
				Json[] jArr = args["ids"].array();
				long[] ids = jArr.map!(j => j.get!long()).array;
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyArray;
				ret["error"] = Json.emptyArray;
				auto theShips = database.ships.filter!(s => canFind(ids, s.id));
				foreach(ship; theShips) {
					Json tmp = Json.emptyObject;
					static foreach(mem; [ "id", "designation", "size"]) {
						tmp[mem] = __traits(getMember, ship, mem);
					}
					tmp["commanderId"] = ship.commander.id;
					tmp["crewIds"] = serializeToJson(
											ship.crew.map!(c => c.id).array
										);
					tmp["series"] = serializeToJson(ship.series);

					ret["data"] ~= tmp;
				}
				logf("%s", ret);
				return ret;
			}
		);

	graphqld.setResolver("Starship", "commander",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
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
			}
		);
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
	Json vars = Json.emptyObject();
	if("variables" in j) {
		vars = j["variables"];
	}
	writeln(j.toPrettyString());
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

	Json gqld = graphqld.execute(d, vars);
	writeln(gqld.toPrettyString());

	res.writeJsonBody(gqld);
}
