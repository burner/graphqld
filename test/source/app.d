import core.time : seconds;
import std.algorithm.searching : canFind;
import std.array;
import std.stdio;
import std.traits;
import std.conv;
import std.typecons;
import std.typecons;
import std.algorithm;
import std.getopt;
import std.regex;

version(LDC) {
	import std.experimental.logger;
} else {
	import std.logger;
}

import vibe.vibe;
import vibe.core.core;
import vibe.data.json;

import graphql.parser;
import graphql.builder;
import graphql.lexer;
import graphql.ast;

import graphql.helper;
import graphql.schema;
import graphql.traits;
import graphql.argumentextractor;
import graphql.schema.toschemafile;
import graphql.exception;
import graphql.graphql;
import graphql.testschema;

import testdata;
import testdata2;

Data database;

GraphQLD!(Schema,CustomContext) graphqld;

struct CustomContext {
	int userId;
}

void testSchemaDump(string fname, string newSchemaText) {
	import std.file : writeFile = write, readText, FileException;
	string oldSchemaText;
	try {
		oldSchemaText = replaceAll(readText(fname), regex(r"\r"), "");
	} catch (FileException) {
		oldSchemaText = newSchemaText;
	}
	// note: if this assertion fails because you deliberately changed the
	// output format of schemaToString, simply remove the old schema[2].gql
	auto oSplit = oldSchemaText.split("\n");
	auto nSplit = newSchemaText.split("\n");
	//writeln(newSchemaText);
	foreach(lineIdx; 0 .. min(oSplit.length, nSplit.length)) {
		assert(oSplit[lineIdx] == nSplit[lineIdx]
				, format("line %s + 1 differed\ngot: %s\nexp: %s"
					, lineIdx, nSplit[lineIdx], oSplit[lineIdx]));
	}

	assert(oSplit.length == nSplit.length,
			format("Num lines old schema %s, num lines new schema %s"
				, oSplit.length, nSplit.length));
	writeFile(fname, newSchemaText);
}

void main() {
 	database = new Data();
	GQLDOptions opts;
	opts.asyncList = AsyncList.no;
	graphqld = new GraphQLD!(Schema,CustomContext)(opts);
	version(LDC) {
		graphqld.defaultResolverLog.logLevel = std.experimental.logger.LogLevel.off;
		graphqld.resolverLog.logLevel = std.experimental.logger.LogLevel.off;
		//graphqld.executationTraceLog = new std.experimental.logger.FileLogger("exec.log");
		graphqld.executationTraceLog.logLevel = std.experimental.logger.LogLevel.off;
	} else {
		graphqld.defaultResolverLog.logLevel = std.logger.LogLevel.off;
		graphqld.resolverLog.logLevel = std.logger.LogLevel.off;
		//graphqld.executationTraceLog = new std.experimental.logger.FileLogger("exec.log");
		graphqld.executationTraceLog.logLevel = std.logger.LogLevel.off;
	}

	testSchemaDump("schema.gql", schemaToString(graphqld));
	testSchemaDump("schema2.gql", schemaToString!Schema2());

	graphqld.setResolver("queryType", "search",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
			{
				import std.datetime;
				Json* data = "name" in args;
				const string argsName = data !is null ? data.get!string() : "";

				foreach(c; database.chars) {
					if(c.name == argsName) {
						Json ret = characterToJson(c);
						return ret;
					}
				}

				foreach(s; database.ships) {
					if(s.name == argsName) {
						Json ret = starshipToJson(s);
						return ret;
					}
				}

				throw new GQLDExecutionException(format(
					"No data with name '%s' found in database", argsName));
			}
		);

	graphqld.setResolver("queryType", "currentTime",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
			{
				import std.datetime;
				SysTime ct = Clock.currTime();
				DateTime dt = cast(DateTime)ct;
				Json ret = Json.emptyObject;
				ret["data"] = Json(dt.toISOExtString());
				return ret;
			}
		);

	graphqld.setResolver("queryType", "starships",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
			{
				//logf("%s", args);
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyArray;
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

	graphqld.setResolver("queryType", "starshipDoesNotExist",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
			{
				Json ret = Json.emptyObject();
				if(name == "starshipDoesNotExist") {
					throw new GQLDExecutionException(
							"That ship does not exists");
				}
				return ret;
			}
		);

	graphqld.setResolver("queryType", "alwaysEmpty",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
			{
				Json ret = Json.emptyObject();
				ret["data"] = Json.emptyArray;
				return ret;
			}
		);
	graphqld.setResolver("queryType", "resolverWillThrow",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
			{
				if(name == "resolverWillThrow") {
					throw new GQLDExecutionException("you can not pass");
				} else {
					Json ret = Json.emptyObject();
					ret["data"] = "foo";
					return ret;
				}
			}
		);

	graphqld.setResolver("queryType", "starship",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @safe
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
				}
				//logf("%s", ret);
				return ret;
			}
		);

	graphqld.setResolver("mutationType", "addCrewman",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @trusted
			{
				long shipId;
				bool ok = hasPathTo(args, "input.shipId", shipId);
				string nname;
				ok = hasPathTo(args, "input.name", nname);
				//logf("%s %s %s", shipId, nname);

				Json ret;

				auto theShip = database.ships.find!(s => shipId == s.id);
				if(!theShip.empty) {
					Starship ship = theShip.front;
					auto nh = new HumanoidImpl(database.i++, nname, "Human",
							Date(1986, 7, 2));
					ship.crew ~= nh;
					nh.ship = nullable(ship);
					ret = characterToJson(nh);
				} else {
					ret = Json.emptyObject();
					ret.insertError(format("Ship with id %s does not exist",
							shipId)
						);
				}

				return ret;
			}
		);
	graphqld.setResolver("queryType", "shipsselection",
			delegate(string name, Json parent, Json args,
					ref CustomContext con) @trusted
			{
				assert("ids" in args);
				Json[] jArr = args["ids"].array();
				long[] ids = jArr.map!(j => j.get!long()).array;
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyArray;
				auto theShips = database.ships.filter!(s => canFind(ids, s.id));
				foreach(ship; theShips) {
					Json tmp = starshipToJson(ship);
					ret["data"] ~= tmp["data"];
				}
				//logf("%s", ret);
				return ret;
			}
		);

	graphqld.setResolver("Starship", "commander",
			delegate(string name, Json parent, Json args,
					ref CustomContext con)
			{
				Json ret = Json.emptyObject;
				ret["data"] = Json.emptyObject;
				long commanderId = parent["commanderId"].to!long();
				foreach(c; database.chars) {
					if(c.id == commanderId) {
						ret["data"] = characterToJson(c)["data"];
						break;
					}
				}
				//logf("cid %s, %s", commanderId, ret["data"]);
				return ret;
			}
		);

	graphqld.setResolver("Starship", "crew",
			delegate(string name, Json parent, Json args,
					ref CustomContext con)
			{
				import std.algorithm.searching : canFind;
				Json ret = Json.emptyObject();
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
				//logf("%s", ret["data"].toPrettyString());
				return ret;
			}
		);

	graphqld.setResolver("Character", "alsoAllwaysNull",
			delegate(string name, Json parent, Json args,
					ref CustomContext con)
			{
				Json ret = Json.emptyObject();
				ret["data"] = Json(null);
				return ret;
			}
		);

	graphqld.setResolver("Character", "allwaysNull",
			delegate(string name, Json parent, Json args,
					ref CustomContext con)
			{
				Json ret = Json.emptyObject();
				ret["data"] = Json(null);
				return ret;
			}
		);

	graphqld.setResolver("Character", "ship",
			delegate(string name, Json parent, Json args,
					ref CustomContext con)
			{
				Json ret = Json.emptyObject();
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
				//logf("%s", ret);
				return ret;
			}
		);

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	bool onlyRunTests = false;
	bool doNotRunTests = false;
	string[] args = new string[0];
	finalizeCommandLineOptions(&args);
	getopt(args,
			"o|onlyRunTests", &onlyRunTests,
			"doNotRunTests", &doNotRunTests);
	writefln("args %s\nonlyRunTests %s\ndoNotRunTests %s", args, onlyRunTests,
			doNotRunTests
		);

	lowerPrivileges();

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");

	Task t;
	if(!doNotRunTests) {
	t = runTask(() @safe nothrow {
			try {
			() @trusted {
			import std.exception : enforce;
			import testqueries;
			foreach(tqIdx, TestQuery q; queries) {
				writefln("%s", tqIdx);
				sleep(1.seconds);
				bool hasThrown;
				//Task qt = runTask({
				try {
					requestHTTP("http://127.0.0.1:8080",
						(scope req) {
							req.method = HTTPMethod.POST;
							Json b = Json.emptyObject();
							b["query"] = Json(q.query);
							if(!q.variables.empty) {
								b["variables"] = parseJsonString(q.variables);
							}
							req.writeJsonBody(b);
						},
						(scope res) {
							Json ret = parseJsonString(
									res.bodyReader.readAllUTF8()
								);
							if(q.st == ShouldThrow.yes) {
								enforce("errors" in ret &&
										ret["errors"].empty,
										format("%s", ret.toPrettyString())
									);
								Json p = parseJsonString(q.expectedResult);
								writefln("%s\n%s", p.toPrettyString(),
										ret.toPrettyString());
								//assert(p == ret, format(
								//			"got: %s\nexpeteced: %s",
								//			p.toPrettyString(),
								//			ret.toPrettyString()));
							} else {
								enforce("errors" !in ret,
										//&& ret["errors"].length == 0,
										format("%s", ret.toPrettyString())
									);
								enforce("data" in ret
										&& ret["data"].length != 0,
										format("%s", ret.toPrettyString())
									);
								if(!q.expectedResult.empty) {
									Json p = parseJsonString(q.expectedResult);
									//assert(p == ret["data"], format(
									//			"got: %s\nexpeteced: %s",
									//			p.toPrettyString(),
									//			ret["data"].toPrettyString()));
								}
							}
						}
					);
				} catch(Exception e) {
					hasThrown = true;
					if(q.st == ShouldThrow.no) {
						writefln("IM DIENING NOW %s %s %s\n%s", tqIdx, __LINE__, e,
								q
							);
						assert(false, format("%s %s", tqIdx, e.msg));
					} else {
						if(!q.expectedResult.empty) {
							Json c = parseJsonString(e.msg);
							Json exp;
							try {
								exp = parseJsonString(q.expectedResult);
							} catch(Exception e) {
							}
							//assert(exp == c || canFind(e.msg, q.expectedResult)
							//		, format("expec: %s\nfound: %s",
							//		exp == Json(null)
							//			? q.expectedResult
							//			: exp.toPrettyString()
							//		, c.toPrettyString()));
						}
					}
				}
				if(q.st == ShouldThrow.yes && !hasThrown) {
					writefln("I SHOULD HAVE THROWN NOW %s %s %s\n%s", tqIdx,
							__LINE__, e, q
						);
					assert(false, format("%s", tqIdx));
				}
				//});
				//qt.join();
			}
			writeln("Automated tests are done, use graphiql-app for further"
					~ " manual tests");
			if(onlyRunTests) {
				import vibe.core.core;
				exitEventLoop(true);
			}
		}();
		} catch(Exception e) {}
	});
	}
	runEventLoop();
	t.join();
	import core.stdc.stdlib;
	exit(0);
}

void hello(HTTPServerRequest req, HTTPServerResponse res) {
	if("Origin" in req.headers) {
		res.headers.addField("Access-Control-Allow-Origin", "*");
	}
	res.headers.addField("Access-Control-Allow-Credentials", "true");
    res.headers.addField("Access-Control-Allow-Methods",
			"POST, GET, OPTIONS, DELETE"
		);
	res.headers.addField("Access-Control-Allow-Headers",
                "Origin, X-Requested-With, Content-Type, Accept, " ~ "X-CSRF-TOKEN");

	// DOCUMENTATION
	//
	// graphql requests can be passed differently depending if it is a GET
	// or POST request
	// The variable `toParse` will contain the graphql query/mutation after
	// the next few lines
	//
	//

	Json j = req.json;
	//writefln("input %s req %s headers %s", j, req.toString(), req.headers);
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
		//writeln(toParse);
	}

	// DOCUMENTATION
	//
	// graphql requests can be depended on variables passed in form of json.
	// The next few lines will extract available variables and store them
	// in the variable named `vars`
	//
	//

	Json vars = Json.emptyObject();
	if(j.type == Json.Type.object && "variables" in j) {
		vars = j["variables"];
	}
	writeln(vars.toPrettyString());

	// DOCUMENTATION
	//
	// graphql is a programming language/query language.
	// It is common to split the recognition of such a language into two steps.
	// The lexing, and the parsing.
	// The lexer results is passed into the parser.
	// This is done on the next to lines.
	// The string in `toParse` we extracted earlier is passed into the lexer.
	//
	//

	auto l = Lexer(toParse);
	auto p = Parser(l);

	try {
		import graphql.validation.querybased;
		import graphql.validation.schemabased;

		// DOCUMENTATION
		//
		// `parseDocument()` actually parses the graphql string.
		// If this throws, in case of a invalid graphql program we need to
		// report this in a way that graphql clients expect.
		// This is done in the catch block.
		//
		//
		Document d = p.parseDocument();


		const(Document) cd = d;

		// DOCUMENTATION
		//
		// As with most programming language the graphql program has to be
		// checked for semantic correctness.
		// This is done in the next few lines
		//
		//
		QueryValidator fv = new QueryValidator(d);
	    fv.accept(cd);
	    noCylces(fv.fragmentChildren);
	    allFragmentsReached(fv);
		SchemaValidator!Schema sv = new SchemaValidator!Schema(d,
				graphqld.schema
			);
		sv.accept(cd);


		// DOCUMENTATION
		//
		// The next few lines actually execute the graphql program.
		// The result will be the json that can be returned to the graphql
		// client.
		//
		//
		CustomContext con;
		Json gqld = graphqld.execute(d, vars, con);

		//writeln(gqld.toPrettyString());

		// DOCUMENTATION
		//
		// Write the resulting json to the vibe.d server response.
		// This is the end of the graphqld execution cycle
		//
		res.writeJsonBody(gqld);
		return;
	} catch(Throwable e) {
		auto app = appender!string();
		while(e) {
			writeln(e.toString());
			app.put(e.toString());
			e = cast(Exception)e.next;
		}
		//writefln("\n\n\n\n#####\n%s\n#####\n\n\n\n", app.data);
		// DOCUMENTATION
		//
		// If the lexing/parsing or validating failed we need to let the graphql
		// client know.
		// The Exception text is inserted into the json by the helper function
		// `insertError`.
		// The json is then returned
		//
		Json ret = Json.emptyObject;
		ret.insertError(app.data);
		res.writeJsonBody(ret);
		return;
	}
}
