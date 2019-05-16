import core.time : seconds;
import std.array;
import std.stdio;
import std.traits;
import std.conv;
import std.typecons;
import std.typecons;
import std.algorithm;
import std.getopt;

import std.experimental.logger;
import std.experimental.logger.filelogger;

import vibe.vibe;
import vibe.data.json;

import graphql.parser;
import graphql.builder;
import graphql.lexer;
import graphql.ast;

import graphql.helper;
import graphql.schema;
import graphql.traits;
import graphql.argumentextractor;
import graphql.graphql;
import graphql.testschema;

import testdata;
import testdata2;

Data database;

GraphQLD!(Schema,CustomContext) graphqld;

struct CustomContext {
	int userId;
}

void main(string[] args) {
	bool onlyRunTests;
	getopt(args, "o|onlyRunTests", &onlyRunTests);
	writeln("onlyRunTests %s", onlyRunTests);
 	database = new Data();
	GQLDOptions opts;
	opts.asyncList = AsyncList.no;
	graphqld = new GraphQLD!(Schema,CustomContext)(opts);

	writeln(graphqld.schema);

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
				logf("%s", args);
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
				logf("%s", ret);
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
				logf("%s", ret);
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
				logf("cid %s, %s", commanderId, ret["data"]);
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
				logf("%s", ret["data"].toPrettyString());
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
				logf("%s", ret);
				return ret;
			}
		);

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	Task t = runTask({
			import std.exception : enforce;
			import testqueries;
			foreach(TestQuery q; queries) {
				sleep(1.seconds);
				bool hasThrown;
				//Task qt = runTask({
				try {
					requestHTTP("http://127.0.0.1:8080",
						(scope req) {
							req.method = HTTPMethod.POST;
							Json b = Json.emptyObject();
							b["query"] = Json(q.query);
							req.writeJsonBody(b);
						},
						(scope res) {
							Json ret = parseJsonString(
									res.bodyReader.readAllUTF8()
								);
							if(q.st == ShouldThrow.yes) {
								enforce("error" in ret
										&& ret["error"].length != 1,
										format("%s", ret.toPrettyString())
									);
							} else {
								enforce("error" in ret
										&& ret["error"].length == 0,
										format("%s", ret.toPrettyString())
									);
								enforce("data" in ret
										&& ret["data"].length != 0,
										format("%s", ret.toPrettyString())
									);
								if(!q.expectedResult.empty) {
									Json p = parseJsonString(q.expectedResult);
									assert(p == ret["data"], format(
												"got: %s\nexpeteced: %s",
												p.toPrettyString(),
												ret["data"].toPrettyString()));
								}
							}
						}
					);
				} catch(Exception e) {
					hasThrown = true;
					if(q.st == ShouldThrow.no) {
						writefln("IM DIENING NOW %s %s\n%s", __LINE__, e, q);
						assert(false, e.msg);
					}
				}
				if(q.st == ShouldThrow.yes && !hasThrown) {
					writefln("I SHOULD HAVE THROWN NOW %s %s\n%s", __LINE__, e,
							q
						);
					assert(false);
				}
				//});
				//qt.join();
				sleep(3.seconds);
			}
			writeln("Automated tests are done, use graphiql-app for further"
					~ " manual tests");
			if(onlyRunTests) {
				import core.stdc.stdlib : exit;
				exit(0);
			}
		});
	runApplication();
	t.join();
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

	try {
		import graphql.validation.querybased;
		import graphql.validation.schemabased;
		Document d = p.parseDocument();
		const(Document) cd = d;
		QueryValidator fv = new QueryValidator(d);
	    fv.accept(cd);
	    noCylces(fv.fragmentChildren);
	    allFragmentsReached(fv);
		SchemaValidator!Schema sv = new SchemaValidator!Schema(d,
				graphqld.schema
			);
		sv.accept(cd);
		CustomContext con;
		Json gqld = graphqld.execute(d, vars, con);

		res.writeJsonBody(gqld);
		return;
	} catch(Throwable e) {
		auto app = appender!string();
		while(e) {
			writeln(e.toString());
			app.put(e.toString());
			e = cast(Exception)e.next;
		}
		Json ret = Json.emptyObject;
		ret["error"] = Json.emptyArray;
		ret["error"] ~= Json(app.data);
		res.writeJsonBody(ret);
		return;
	}
}
