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

import helper;
import testdata;
import testdata2;
import schema2;
import traits;

Data database;

struct DefaultContext {
}

class GraphQLD(T, QContext = DefaultContext) {
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context) @safe;

	alias Schema = GQLDSchema!(T, Con);

	Document doc;

	Schema schema;

	Con dummy;

	// [Type][field]
	QueryResolver[string][string] resolver;
	QueryResolver defaultResolver;

	this() {
		this.schema = toSchema2!(T,Con)();
		this.defaultResolver = delegate(string name, Json parent, Json args,
									ref Con context)
			{
				import std.format;
				logf("name: %s, parent: %s, args: %s", name, parent, args);
				Json ret = Json.emptyObject();
				ret["data"] = Json.emptyObject();
				ret["error"] = Json.emptyArray();
				if(parent.type != Json.Type.null_ && name in parent) {
					ret["data"] = parent[name];
				} else {
					ret["error"] = Json(format("no field name '%s' found",
										name)
									);
				}
				logf("default ret %s", ret);
				return ret;
			};
		auto typeResolver = buildTypeResolver!(T, Con)();
		this.setResolver("query", "__type", typeResolver);
		this.setResolver("query", "__schema", buildSchemaResolver!(T, Con)());
		this.setResolver("__field", "type",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					import std.string : capitalize;
					Json ret = typeResolver(name, parent, args, context);
					logf("FIELDDDDD TYPPPPPE %s", ret.toPrettyString());
					return ret;
				}
			);
		this.setResolver("__type", "interfaces",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					assert("interfacesNames" in parent);
					Json interNames = parent["interfacesNames"];
					Json ret = returnTemplate();
					if(interNames.type == Json.Type.array) {
						ret["data"] = Json.emptyArray();
						foreach(Json it; interNames.byValue()) {
							string typeName = it.get!string();
							string typeCap = capitalize(typeName);
							static foreach(type; collectTypes!(T)) {{
								if(typeCap == typeToTypeName!(type)) {
									ret["data"] ~= typeToJson!type();
								}
							}}
						}
					} else {
						ret["data"] = Json(null);
					}
					return ret;
				}
			);
		this.setResolver("__type", "possibleTypes",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					assert("possibleTypesNames" in parent);
					Json pTypesNames = parent["possibleTypesNames"];
					Json ret = returnTemplate();
					if(pTypesNames.type == Json.Type.array) {
						log();
						ret["data"] = Json.emptyArray();
						foreach(Json it; pTypesNames.byValue()) {
							string typeName = it.get!string();
							string typeCap = capitalize(typeName);
							static foreach(type; collectTypes!(T)) {{
								if(typeCap == typeToTypeName!(type)) {
									ret["data"] ~= typeToJson!type();
								}
							}}
						}
					} else {
						log();
						ret["data"] = Json(null);
					}
					return ret;
				}
			);
		this.setResolver("__type", "ofType",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name,
							parent.toPrettyString(), args
						);
					Json ret;
					if("ofTypeName" in parent
							&& parent["ofTypeName"].type != Json.Type.null_)
					{
						parent["name"] = parent["ofTypeName"];
						ret = typeResolver(name, parent, args, context);
					} else {
						ret = returnTemplate();
						ret["data"] = emptyType();
					}
					logf("ref %s", ret["data"].toPrettyString());
					return ret;
				}
			);

		writeln(this.schema.toString());
	}

	void setResolver(string first, string second, QueryResolver resolver) {
		if(first !in this.resolver) {
			this.resolver[first] = QueryResolver[string].init;
		}
		this.resolver[first][second] = resolver;
	}

	Json resolve(string type, string field, Json parent, Json args,
			ref Con context)
	{
		Json defaultArgs = this.getDefaultArguments(type, field);
		Json joinedArgs = joinJson(args, defaultArgs);
		logf("%s %s %s %s", defaultArgs, parent, args, joinedArgs);
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
			logf("Type %s %s", Type.stringof, type);
			if(typename == type) {
				switch(field) {
					static foreach(mem; __traits(allMembers, Type)) {
						static if(isCallable!(
								__traits(getMember, Type, mem))
							)
						{
							case mem: {
								logf("mem %s %s", mem, field);
								logf("%s %s", type, field);
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
								logf("%s", ret);
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
		switch(type) {
			static foreach(Type; collectTypes!(T)) {{
				case Type.stringof: {
					Json tmp = getDefaultArgumentImpl!(Type.stringof, Type)(
							type, field
						);
					if(tmp.type != Json.Type.undefined
							&& tmp.type != Json.Type.null_)
					{
						logf("tmp %s", tmp);
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
					logf("%s", entryPoint);
					Json tmp = getDefaultArgumentImpl!(entryPoint,
							typeof(__traits(getMember, T, entryPoint)))(type, field
						);
					if(tmp.type != Json.Type.undefined && tmp.type != Json.Type.null_) {
						logf("tmp %s", tmp);
						return tmp;
					}
				}
			}}
			default: break;
		}
		defaultRet:
		return Json.init;
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
		Json tmp = this.executeSelections(op.ss.sel,
				this.schema.member["mutation"],
				Json.emptyObject(), variables
			);
		return tmp;
	}

	Json executeQuery(OperationDefinition op, Json variables) {
		log("query");
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
				/*objectValue*/"", variables);
		foreach(FieldRangeItem field; fieldRangeArr(sel, this.doc)) {
			logf("Field: %s, OT: %s, OJ: %s", field.name, objectType.name,
					/*objectValue*/""
				);
			Json rslt = this.executeFieldSelection(field, objectType,
					objectValue, variables
				);
			//logf("RSLT: %s", rslt);
			ret.insertPayload(field.name, rslt);
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType!Con objectType,
			Json objectValue, Json variables)
	{
		logf("FRI: %s, OT: %s, OV: %s, VAR: %s", field.name,
				objectType.name, objectValue, variables
			);
		logf("TESSSS %s", "data" in objectValue
				? objectValue["data"] : objectValue
			);
		Json arguments = getArguments(field, variables);
		Json de = this.resolve(objectType.name, field.name,
				"data" in objectValue ? objectValue["data"] : objectValue,
				arguments, this.dummy
			);
		auto retType = this.schema.getReturnType(objectType, field.name);
		if(retType is null) {
			logf("ERR %s %s", objectType.name, field.name);
			Json ret = Json.emptyObject();
			ret["error"] = Json.emptyArray();
			ret["error"] ~= Json(format(
					"No return type for member '%s' of type '%s' found",
					field.name, objectType.name
				));
			return ret;
		}
		logf("de: %s, retType %s", /*de*/"", retType.name);
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
			if(rslt.dataIsEmpty()) {
				logf("NULLLLLLLLLLLL %s %s", rslt, rslt.dataIsEmpty());
				rslt["data"] = null;
				rslt.remove("error");
			} else {
				logf("NNNNNNNNNNNNNN %s", rslt);
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
		auto elemType = objectType.elementType;
		Json ret = returnTemplate();
		ret["data"] = Json.emptyArray();
		foreach(Json item;
				objectValue["data"].type == Json.Type.array
					? objectValue["data"]
					: Json.emptyArray()
			)
		{
			logf("ET: %s, item %s", elemType.name, item);
			Json tmp = this.executeSelectionSet(ss, elemType, item, variables);
			logf("tmp %s", tmp);
			if(tmp.type == Json.Type.object) {
				if("data" in tmp) {
					ret["data"] ~= tmp["data"];
				}
				foreach(err; tmp["error"]) {
					ret["error"] ~= err;
				}
			} else if(!tmp.dataIsEmpty() && tmp.isScalar()) {
				ret["data"] ~= tmp;
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
	alias accept = Visitor.accept;

	Json arguments;
	Json variables;

	string[] curNames;

	this(Json variables) {
		this.variables = variables;
		this.arguments = Json.emptyObject();
	}

	void assign(Json toAssign) {
		Json* arg = &this.arguments;
		//logf("%(%s.%) %s %s", this.curNames, this.arguments, toAssign);
		assert(!this.curNames.empty);
		foreach(idx; 0 .. this.curNames.length - 1) {
			arg = &((*arg)[this.curNames[idx]]);
		}

		if(this.curNames.back in (*arg)
				&& ((*arg)[this.curNames.back]).type == Json.Type.array)
		{
			((*arg)[this.curNames.back]) ~= toAssign;
		} else if((*arg).type == Json.Type.object) {
			((*arg)[this.curNames.back]) = toAssign;
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

	override void accept(const(ObjectValues) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectValuesEnum.V:
				this.curNames ~= obj.name.value;
				obj.val.visit(this);
				this.curNames.popBack();
				break;
			case ObjectValuesEnum.Vsc:
				this.curNames ~= obj.name.value;
				obj.val.visit(this);
				this.curNames.popBack();
				obj.follow.visit(this);
				break;
			case ObjectValuesEnum.Vs:
				this.curNames ~= obj.name.value;
				obj.val.visit(this);
				this.curNames.popBack();
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	override void enter(const(Variable) var) {
		string varName = var.name.value;
		enforce(varName in this.variables,
				format("Variable with name %s required", varName)
			);
		this.assign(this.variables[varName]);
	}

	override void enter(const(Value) val) {
		final switch(val.ruleSelection) {
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
			case ValueEnum.O:
				this.assign(Json.emptyObject());
				break;
			case ValueEnum.E:
				this.assign(Json(val.tok.value));
				break;
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
				logf("%s", args);
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyArray;
				ret["error"] = Json.emptyArray;
				float overSize = args["overSize"].to!float();
				foreach(ship; database.ships) {
					if(ship.size > overSize) {
						Json tmp = starshipToJson(ship);
						ret["data"] ~= tmp;
					}
				}
				return ret;
			}
		);

	graphqld.setResolver("Character", "ship",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				Json ret = returnTemplate();
				if("shipId" !in parent
						|| parent["shipId"].type != Json.Type.int_)
				{
					ret["data"] = Json(null);
					return ret;
				}
				long shipId = parent["shipId"].get!long();
				auto theShip = database.ships.find!(s => s.id == shipId);
				if(!theShip.empty) {
					Starship ship = theShip.front;
					ret = starshipToJson(ship);
				}
				logf("%s", ret);
				return ret;
			}
		);
	graphqld.setResolver("query", "starship",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				assert("id" in args);
				long id = args["id"].get!long();
				Json ret;
				auto theShip = database.ships.find!(s => s.id == id);
				if(!theShip.empty) {
					Starship ship = theShip.front;
					ret = starshipToJson(ship);
				} else {
					ret = Json.emptyObject;
					ret["data"] = Json.emptyObject;
					ret["error"] = Json.emptyArray;
				}
				logf("%s", ret);
				return ret;
			}
		);

	graphqld.setResolver("mutation", "addCrewman",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con) @trusted
			{
				logf("args %s", args);
				assert("shipId" in args);
				long shipId = args["shipId"].get!long();
				assert("name" in args);
				string nname = args["name"].get!string();
				logf("%s %s", shipId, nname);

				Json ret = returnTemplate();

				auto theShip = database.ships.find!(s => shipId == s.id);
				if(!theShip.empty) {
					Starship ship = theShip.front;
					auto nh = new HumanoidImpl(database.i++, nname, "Human");
					ship.crew ~= nh;
					nh.ship = nullable(ship);
					ret = characterToJson(nh);
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
					Json tmp = starshipToJson(ship);
					ret["data"] ~= tmp["data"];
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
				long commanderId = parent["commanderId"].to!long();
				foreach(c; database.chars) {
					if(c.id == commanderId) {
						ret["data"] = characterToJson(c)["data"];
						break;
					}
				}
				logf("cid %s, %s", commanderId, ret["data"]);
				return ret;
			}
		);

	graphqld.setResolver("Starship", "crew",
			delegate(string name, Json parent, Json args,
					ref typeof(graphqld).Con con)
			{
				import std.algorithm.searching : canFind;
				Json ret = returnTemplate();
				if("crewIds" in parent) {
					ret["data"] = Json.emptyArray();
					long[] crewIds = parent["crewIds"]
						.deserializeJson!(long[])();
					foreach(c; database.chars) {
						if(canFind(crewIds, c.id)) {
							ret["data"] ~= characterToJson(c);
						}
					}
				}
				logf("%s", ret["data"].toPrettyString());
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
			writeln(e.toString());
			app.put(e.toString());
			e = cast(Exception)e.next;
		}
		ret["error"] ~= Json(app.data);
		res.writeJsonBody(ret);
		return;
	}

	//auto tv = new TreeVisitor(0);
	//tv.accept(cast(const(Document))d);

	Json gqld = graphqld.execute(d, vars);
	writeln(gqld.toPrettyString());

	res.writeJsonBody(gqld);
}
