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

struct DefaultContext {
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

bool dataIsEmpty(ref Json data) {
	enum d = "data";
	if(d in data) {
		if(data[d].type == Json.Type.object) {
			foreach(key, value; data[d].byKeyValue()) {
				if(value.type != Json.Type.object || value.length > 0) {
					return false;
				}
			}
		}
	}
	return true;
}

class GraphQLD(T, QContext = DefaultContext) {
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context) @safe;

	Document doc;

	alias Schema = GQLDSchema!(T, Con);
	Schema schema;

	Con dummy;

	this() {
		this.schema = toSchema2!(T,Con)();
		writeln(this.schema.toString());
	}

	void setResolver(string first, string second, QueryResolver resolver) {
		GQLDMap!(Con) fMap;
		if(first in this.schema.member) {
			logf("schema %s %s", first, second);
			fMap = this.schema.member[first].toMap();
		} else if(first in this.schema.types) {
			logf("types %s %s", first, second);
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
		assert(false);
		/*FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		Json tmp = this.executeSelection(selSet,
						cast(GQLDMap!Con)this.schema.member["mutation"],
						Json.emptyObject(), variables
					);
		return tmp;*/
	}

	Json executeQuery(OperationDefinition op, Json variables) {
		log("query");
		//FieldRangeItem[] selSet = fieldRange(op, this.doc).array;
		//Json tmp = this.executeSelection(selSet,
		//				cast(GQLDMap!Con)this.schema.member["query"],
		//				Json.emptyObject(), variables
		//			);
		Json tmp = this.executeSelections(op.ss.sel, this.schema.member["query"],
				Json.emptyObject(), variables
			);
		return tmp;
	}

	Json executeSelections(Selections sel, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		Json ret = returnTemplate();
		logf("OT: %s, OJ: %s, VAR: %s", objectType.name,
				objectValue, variables);
		foreach(FieldRangeItem field; fieldRangeArr(sel, this.doc)) {
			//auto retType = this.schema.getReturnType(objectType, field.name);
			logf("Field: %s, OT: %s, OJ: %s", field.name, objectType.name,
					objectValue
				);
			Json rslt = this.executeFieldSelection(field, objectType,
					objectValue, variables
				);
			logf("RSLT: %s", rslt);
			ret.insertPayload(field.name, rslt);
			//ret["data"][field.name] = rslt;
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		logf("FRI: %s, OT: %s, OV: %s, VAR: %s", field.name,
				objectType.name, objectValue, variables
			);
		Json arguments = getArguments(field, variables);
		Json de = objectType.call(field.name,
				"data" in objectValue ? objectValue["data"] : objectValue,
				arguments, this.dummy
			);
		auto retType = this.schema.getReturnType(objectType, field.name);
		//auto retType = objectType;
		logf("de: %s, retType %s", de, retType.name);
		return this.executeSelectionSet(field.f.ss, retType, de, arguments);
	}

	Json executeSelectionSet(SelectionSet ss, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		logf("OT: %s, OJ: %s, VAR: %s", objectType.toString(), objectValue,
				variables
			);
		Json rslt;
		if(GQLDMap!Con map = objectType.toMap()) {
			logf("map %s %s", map.name, ss !is null);
			rslt = this.executeSelections(ss.sel, map, objectValue, variables);
		} else if(GQLDNullable!Con nullType = objectType.toNullable()) {
			logf("nullable %s", nullType.name);
			rslt = this.executeSelectionSet(ss, nullType.elementType,
					objectValue, variables
				);
			if(rslt.dataIsEmpty) {
				rslt["data"] = null;
			}
		} else if(GQLDList!Con list = objectType.toList()) {
			logf("list %s", list.name);
			rslt = this.executeList(ss, list, objectValue, variables);
		} else if(GQLDScalar!Con scalar = objectType.toScalar()) {
			logf("scalar %s", scalar.name);
			rslt = objectValue;
		}

		logf("RSLT %s", rslt);
		return rslt;
	}

	Json executeList(SelectionSet ss, GQLDList!Con objectType,
			Json objectValue, Json variables)
	{
		logf("OT: %s, OJ: %s, VAR: %s", objectType.name, objectValue,
				variables
			);
		assert("data" in objectValue, objectValue.toString());
		assert(objectValue["data"].type == Json.Type.array);
		auto elemType = objectType.elementType;
		Json ret = returnTemplate();
		ret["data"] = Json.emptyArray();
		foreach(Json item; objectValue["data"]) {
			logf("ET: %s, item %s", elemType.name, item);
			Json tmp = this.executeSelectionSet(ss, elemType, item, variables);
			if("data" in tmp) {
				ret["data"] ~= tmp["data"];
			}
			foreach(err; tmp["error"]) {
				ret["error"] ~= err;
			}
		}
		return ret;
	}




	/*Json executeSelection(FieldRangeItem[] fields, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		logf("fields %(%s, %), objectType %s, objectValue %s, variables %s",
				fields.map!(f => f.name), objectType.toShortString(),
				objectValue, variables);
		Json ret = returnTemplate();

		GQLDNullable!Con nullType = objectType.toNullable();
		if(nullType) {
			auto elemType = nullType.elementType;
			logf("nullable ot %s, et %s", objectType.toShortString(),
					elemType.toShortString()
				);
			//FieldRangeItem[] selSet = field.selectionSet().array;
			Json tmp = this.executeSelection(fields, elemType, objectValue,
							variables);
			logf("tmp %s isEmpty %s", tmp, tmp.dataIsEmpty());
			if(tmp.dataIsEmpty) {
				ret["data"] = null;
			} else {
				foreach(key, value; tmp["data"].byKeyValue) {
					ret["data"][key] = value;
				}
				foreach(err; tmp["error"].array()) {
					ret["error"] ~= err;
				}
			}
			return ret;
		}

		GQLDMap!Con map = objectType.toMap();
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
		logf("field %s, objectType %s, objectValue %s, variables %s",
				field.name, objectType.toShortString(), objectValue,
				variables);
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
								"data" in de ? de["data"] : objectValue,
								arguments
							);
				ret.insertPayload(field.name, tmp);
				return ret;
			}
		} else if(GQLDList!Con list =
				this.schema.getReturnType(objectType, field.name).toList())
		{
			logf("list %s", de);
			if(!field.hasSelectionSet()) {
				ret["error"] ~= Json("No selection set found for "
										~ field.name
									);
			} else {
				auto elemType = list.elementType;
				assert(de["data"].type == Json.Type.array);
				FieldRangeItem[] selSet = field.selectionSet().array;
				logf("%(%s, %)", selSet.map!(s => s.name));
				Json tmp = Json.emptyArray();
				foreach(Json item; de["data"]) {
					logf("%s %s", item, elemType.name);
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
				logf("selSet [%(%s, %)], objectType %s",
						selSet.map!(a => a.name), objectType.toShortString());
				auto type = this.schema.getReturnType(objectType, field.name);
				logf("type %s", type ? type.toShortString() : "null");
				Json tmp = this.executeSelection(selSet,
						type ? type : objectType,
						"data" in de ? de["data"] : objectValue,
						arguments
					);
				ret.insertPayload(field.name, tmp);
				return ret;
			}
		}
		return ret;
	}*/

	/*
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
					//FieldRangeItem[] selSet = field.selectionSet().array;
					Json tmp = this.executeFieldSelection(field, elemType,
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
			logf("list %s", de);
			if(!field.hasSelectionSet()) {
				ret["error"] ~= Json("No selection set found for "
										~ field.name
									);
			} else {
				auto elemType = list.elementType;
				assert(de["data"].type == Json.Type.array);
				FieldRangeItem[] selSet = field.selectionSet().array;
				logf("%(%s, %)", selSet.map!(s => s.name));
				Json tmp = Json.emptyArray();
				foreach(Json item; de["data"]) {
					logf("%s %s", item, elemType.name);
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
*/

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
	writeln(graphqld.schema);
	graphqld.setResolver("query", "starships",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyArray;
				ret["error"] = Json.emptyArray;
				foreach(ship; database.ships[0 .. 1]) {
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
