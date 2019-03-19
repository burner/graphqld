import std.array;
import std.stdio;
import std.traits;
import std.conv;
import std.typecons;
import std.typecons;
import std.algorithm;

import std.experimental.logger;
import std.experimental.logger.filelogger;

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
import schema;
import traits;
import argumentextractor;

Data database;

struct DefaultContext {
}

class GraphQLD(T, QContext = DefaultContext) {
	alias Con = QContext;
	alias QueryResolver = Json delegate(string name, Json parent,
			Json args, ref Con context) @safe;

	alias Schema = GQLDSchema!(T);

	Document doc;

	Schema schema;

	Con dummy;

	// [Type][field]
	QueryResolver[string][string] resolver;
	QueryResolver defaultResolver;

	this() {
		this.schema = toSchema2!(T)();
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
		this.setResolver("queryType", "__type",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("%s %s %s", name, parent, args);
					Json tr = typeResolver(name, parent, args, context);
					Json ret = returnTemplate();
					ret["data"] = tr["data"]["ofType"];
					logf("%s %s", tr.toPrettyString(), ret.toPrettyString());
					return ret;
				}
			);
		this.setResolver("queryType", "__schema", buildSchemaResolver!(T, Con)());
		this.setResolver("__Field", "type",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					import std.string : capitalize;
					Json ret = typeResolver(name, parent, args, context);
					logf("FIELDDDDD TYPPPPPE %s", ret.toPrettyString());
					return ret;
				}
			);
		this.setResolver("__InputValue", "type",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("%s %s %s", name, parent, args);
					Json tr = typeResolver(name, parent, args, context);
					Json ret = returnTemplate();
					ret["data"] = tr["data"]["ofType"];
					logf("%s %s", tr.toPrettyString(), ret.toPrettyString());
					return ret;
				}
			);
		this.setResolver("__Type", "ofType",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					Json ret = returnTemplate();
					Json ofType;
					if(parent.hasPathTo("ofType", ofType)) {
						ret["data"] = ofType;
					}
					logf("%s", ret);
					return ret;
				}
			);
		this.setResolver("__Type", "interfaces",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					Json ret = returnTemplate();
					if("kind" in parent
							&& parent["kind"].get!string() == "OBJECT")
					{
						ret["data"] = Json.emptyArray();
					}
					if("interfacesNames" !in parent) {
						return ret;
					}
					Json interNames = parent["interfacesNames"];
					if(interNames.type == Json.Type.array) {
						if(interNames.length > 0) {
							assert(ret["data"].type == Json.Type.array,
									format("%s", parent.toPrettyString())
								);
							ret["data"] = Json.emptyArray();
							foreach(Json it; interNames.byValue()) {
								string typeName = it.get!string();
								string typeCap = capitalize(typeName);
								static foreach(type; collectTypes!(T)) {{
									if(typeCap == typeToTypeName!(type)) {
										alias striped =
											stripArrayAndNullable!type;
										logf("%s %s", typeCap,
												striped.stringof);
										ret["data"] ~=
											typeToJsonImpl!(striped,T)();
										//ret["data"] ~= typeToJson!(type,T)();
									}
								}}
							}
						}
					}
					logf("__Type.interfaces result %s", ret);
					return ret;
				}
			);
		this.setResolver("__Type", "possibleTypes",
				delegate(string name, Json parent, Json args, ref Con context) {
					logf("name %s, parent %s, args %s", name, parent, args);
					Json ret = returnTemplate();
					if("possibleTypesNames" !in parent) {
						ret["data"] = Json(null);
						return ret;
					}
					Json pTypesNames = parent["possibleTypesNames"];
					if(pTypesNames.type == Json.Type.array) {
						log();
						ret["data"] = Json.emptyArray();
						foreach(Json it; pTypesNames.byValue()) {
							string typeName = it.get!string();
							string typeCap = capitalize(typeName);
							static foreach(type; collectTypes!(T)) {{
								if(typeCap == typeToTypeName!(type)) {
									alias striped = stripArrayAndNullable!type;
									logf("%s %s", typeCap, striped.stringof);
									ret["data"] ~= typeToJsonImpl!(striped,T)();
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
		logf("%s %s %s %s %s %s", type, field, defaultArgs, parent, args,
				joinedArgs
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
			//logf("Type %s %s", Type.stringof, type);
			if(typename == type) {
				switch(field) {
					static foreach(mem; __traits(allMembers, Type)) {
						static if(isCallable!(
								__traits(getMember, Type, mem))
							)
						{
							case mem: {
								//logf("mem %s %s", mem, field);
								//logf("%s %s", type, field);
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
								//logf("%s", ret);
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
						//logf("tmp %s", tmp);
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
					//logf("%s", entryPoint);
					Json tmp = getDefaultArgumentImpl!(entryPoint,
							typeof(__traits(getMember, T, entryPoint)))(type, field
						);
					if(tmp.type != Json.Type.undefined && tmp.type != Json.Type.null_) {
						//logf("tmp %s", tmp);
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
		//logf("Vars %s", variables);

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
				/*foreach(key, value; tmp.byKeyValue()) {
					if(key in ret["data"]) {
						logf("key %s already present", key);
						continue;
					}
					ret["data"][key] = value;
				}*/
				if(tmp.type == Json.Type.object && "data" in tmp) {
					foreach(key, value; tmp["data"].byKeyValue()) {
						if(key in ret["data"]) {
							logf("key %s already present", key);
							continue;
						}
						ret["data"][key] = value;
					}
				}
				//logf("%s", op.name.value);
				//ret["data"][op.name.value] = tmp["data"];
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
				this.schema.member["mutationType"],
				Json.emptyObject(), variables
			);
		return tmp;
	}

	Json executeQuery(OperationDefinition op, Json variables) {
		log("query");
		Json tmp = this.executeSelections(op.ss.sel,
				this.schema.member["queryType"],
				Json.emptyObject(), variables
			);
		return tmp;
	}

	Json executeSelections(Selections sel, GQLDType objectType,
			Json objectValue, Json variables)
	{
		Json ret = returnTemplate();
		logf("OT: %s, OJ: %s, VAR: %s", objectType.name,
				objectValue, variables);
		logf("TN: %s", interfacesForType!(T)(objectValue
				.getWithDefault!string("data.__typename", "__typename")
			));
		foreach(FieldRangeItem field;
				fieldRangeArr(sel, this.doc, interfacesForType!(T)(objectValue
					.getWithDefault!string("data.__typename", "__typename")))
			)
		{
			//logf("Field: %s, OT: %s, OJ: %s", field.name, objectType.name,
			//		/*objectValue*/""
			//	);
			Json rslt = this.executeFieldSelection(field, objectType,
					objectValue, variables
				);
			//logf("RSLT: %s", rslt);
			ret.insertPayload(field.name, rslt);
		}
		return ret;
	}

	Json executeFieldSelection(FieldRangeItem field, GQLDType objectType,
			Json objectValue, Json variables)
	{
		logf("FRI: %s, OT: %s, OV: %s, VAR: %s", field.name,
				objectType.name, objectValue, variables
			);
		//logf("TESSSS %s", "data" in objectValue
		//		? objectValue["data"] : objectValue
		//	);
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
		logf("retType %s, de: %s", retType.name, de);
		//enforce(field.f.ss !is null);
		return this.executeSelectionSet(field.f.ss, retType, de, arguments);
	}

	Json executeSelectionSet(SelectionSet ss, GQLDType objectType,
			Json objectValue, Json variables)
	{
		//logf("OT: %s, OJ: %s, VAR: %s", objectType.toString(), objectValue,
		//		variables
		//	);
		Json rslt;
		if(GQLDMap map = objectType.toMap()) {
			logf("map %s %s", map.name, ss !is null);
			rslt = this.executeSelections(ss.sel, map, objectValue, variables);
		} else if(GQLDNonNull nonNullType = objectType.toNonNull()) {
			logf("NonNull %s", nonNullType.elementType.name);
			rslt = this.executeSelectionSet(ss, nonNullType.elementType,
					objectValue, variables
				);
			if(rslt.dataIsNull()) {
				logf("%s", rslt);
				rslt["error"] ~= Json("NonNull was null");
			}
		} else if(GQLDNullable nullType = objectType.toNullable()) {
			logf("nullable %s", nullType.name);
			rslt = this.executeSelectionSet(ss, nullType.elementType,
					objectValue, variables
				);
			logf("IIIIIS EMPTY %s rslt %s", rslt.dataIsEmpty(), rslt);
			if(rslt.dataIsEmpty()) {
				//logf("NULLLLLLLLLLLL %s %s", rslt, rslt.dataIsEmpty());
				rslt["data"] = null;
				rslt.remove("error");
			} else {
				//logf("NNNNNNNNNNNNNN %s", rslt);
			}
		} else if(GQLDList list = objectType.toList()) {
			logf("list %s", list.name);
			rslt = this.executeList(ss, list, objectValue, variables);
		} else if(GQLDScalar scalar = objectType.toScalar()) {
			//logf("scalar %s", scalar.name);
			rslt = objectValue;
		}

		//logf("RSLT %s", rslt);
		return rslt;
	}

	Json executeList(SelectionSet ss, GQLDList objectType,
			Json objectValue, Json variables)
	{
		logf("OT: %s, OJ: %s, VAR: %s", objectType.name, /*objectValue*/"",
				variables
			);
		assert("data" in objectValue, objectValue.toString());
		auto elemType = objectType.elementType;
		logf("elemType %s", elemType);
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
			//logf("tmp %s", tmp);
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

GraphQLD!(Schema) graphqld;

void main() {
	sharedLog = new std.experimental.logger.FileLogger("app.log");
 	database = new Data();
	graphqld = new GraphQLD!Schema();
	writeln(graphqld.schema);
	DefaultContext dc;
	//auto sr = buildSchemaResolver!(Schema2, DefaultContext);
	//writeln(sr("", Json.emptyObject(), Json.emptyObject(),
	//			dc)["data"].toPrettyString()
	//	);
	graphqld.setResolver("queryType", "starships",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con)
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
					ref DefaultContext con)
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
	graphqld.setResolver("queryType", "starship",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con)
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

	graphqld.setResolver("mutationType", "addCrewman",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @trusted
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
	graphqld.setResolver("queryType", "shipsselection",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @trusted
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
					ref DefaultContext con)
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
					ref DefaultContext con)
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
	if("Origin" in req.headers) {
		res.headers.addField("Access-Control-Allow-Origin",
				//req.headers["Origin"]
				//"http://localhost:8080/"
				"*"
			);
	}
	res.headers.addField("Access-Control-Allow-Credentials", "true");
    res.headers.addField("Access-Control-Allow-Methods",
			"POST, GET, OPTIONS, DELETE"
		);
	res.headers.addField("Access-Control-Allow-Headers",
                "Origin, X-Requested-With, Content-Type, Accept, " ~ "X-CSRF-TOKEN");
	Json j = req.json;
	writefln("input %s req %s headers %s", j, req.toString(), req.headers);
	string toParse;
	if(j.type == Json.Type.object && "query" in j) {
		toParse = j["query"].get!string();
	} else if(j.type == Json.Type.object && "mutation" in j) {
		toParse = j["mutation"].get!string();
	} else {
		toParse = req.headers["Referer"].urlDecode();
		string toFind = "?query=";
		auto idx = toParse.indexOf(toFind);
		if(idx != -1) {
			toParse = toParse[idx + toFind.length .. $];
		}
		writeln(toParse);
	}
	Json vars = Json.emptyObject();
	if(j.type == Json.Type.object && "variables" in j) {
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
	writeln(toParse);
	pragma(msg, "745 ", is(Schema : Android));
}
