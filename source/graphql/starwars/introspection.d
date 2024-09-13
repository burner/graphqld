module graphql.starwars.introspection;

__EOF__

import std.typecons : Nullable, nullable;
import std.format : format;
import std.stdio;

import vibe.data.json;

import graphql.constants;
import graphql.parser;
import graphql.builder;
import graphql.lexer;
import graphql.ast;
import graphql.graphql;
import graphql.helper;
import graphql.starwars.data;
import graphql.starwars.schema;
import graphql.starwars.types;
import graphql.validation.querybased;
import graphql.validation.schemabased;

@safe:

Json query(string s) {
	return query(s, Json.init);
}

Json query(string s, Json args) {
	auto graphqld = new GraphQLD!(StarWarsSchema);
	//auto lo = new std.experimental.logger.FileLogger("query.log");
	//graphqld.defaultResolverLog = lo;
	//graphqld.executationTraceLog = lo;
	//graphqld.resolverLog = lo;

	graphqld.setResolver("queryType", "human",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @safe
			{
				auto idPtr = "id" in args;
				Json ret = Json.emptyObject();
				if(idPtr) {
					string id = idPtr.to!string();
					Human h = getHuman(id);
					if(h is null) {
						ret["data"] = Json(null);
						return ret;
					}
					Json hj = toGraphqlJson(h, graphqld.schema);
					Json cj = toGraphqlJson(cast(Character)h,
							graphqld.schema);
					cj.remove("__typename");
					ret["data"] = joinJson(hj, cj);
				}
				return ret;
			}
		);

	graphqld.setResolver("queryType", "hero",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @safe
			{
				import std.conv : to;
				auto e = "episode" in args;
				Json ret = Json.emptyObject();
				ret["data"] = toGraphqlJson(getHero(
						e ? nullable((*e).to!string().to!Episode())
							: Nullable!(Episode).init
					), graphqld.schema);
				return ret;
			}
		);

	graphqld.setResolver("Character", "secretBackstory",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @safe
			{
				Json ret = Json.emptyObject();
				ret[Constants.data] = Json(null);
				ret[Constants.errors] = Json.emptyArray();
				ret.insertError("secretBackstory is secret");
				return ret;
			}
		);

	graphqld.setResolver("Character", "friends",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @safe
			{
				auto idPtr = "id" in parent;
				Json ret = Json.emptyObject();
				ret["data"] = Json.emptyArray();
				if(idPtr) {
					string id = idPtr.to!string();
					foreach(it; getFriends(getCharacter(id))) {
						ret["data"] ~= toGraphqlJson(it, graphqld.schema);
					}
				}
				return ret;
			}
		);

	auto l = Lexer(s);
	auto p = Parser(l);

	Document d = p.parseDocument();
	const(Document) cd = d;
	QueryValidator fv = new QueryValidator(d);
	fv.accept(cd);
	noCylces(fv.fragmentChildren);
	allFragmentsReached(fv);
	SchemaValidator!StarWarsSchema sv = new SchemaValidator!StarWarsSchema(d,
			graphqld.schema
		);
	sv.accept(cd);
	DefaultContext con;
	Json gqld = graphqld.execute(d, args, con);
	return gqld;
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionTypeQuery {
			__schema {
				types {
					name
				}
			}
		}
		`);

	string s = ` {
	"data": {
		"__schema": {
			"types": [
				{
					"name": "Boolean"
				},
				{
					"name": "Character"
				},
				{
					"name": "Droid"
				},
				{
					"name": "Episode"
				},
				{
					"name": "Float"
				},
				{
					"name": "Human"
				},
				{
					"name": "Int"
				},
				{
					"name": "String"
				},
				{
					"name": "__InputValue"
				},
				{
					"name": "__Type"
				},
				{
					"name": "__TypeKind"
				},
				{
					"name": "queryType"
				},
				{
					"name": "subscriptionType"
				}
			]
		}
	}
}`;
	Json exp = parseJson(s);
	auto cmpResult = compareJson(exp, rslt, "", true);
	// TODO make this test pass
	assert(cmpResult.okay, format("msg: %s\npath: %--(%s,%)\nexp:\n%s\ngot:\n%s"
			, cmpResult.message, cmpResult.path, exp.toPrettyString()
			, rslt.toPrettyString()));
	//if(!cmpResult.okay) {
	//	writefln("msg: %s\npath: %--(%s,%)\nexp:\n%s\ngot:\n%s"
	//		, cmpResult.message, cmpResult.path, exp.toPrettyString()
	//		, rslt.toPrettyString());
	//}
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionDroidTypeQuery {
			__type(name: "Droid") {
				name
			}
		}
		`);

	string s = `{
		"data" : {
			"__type" : {
				"name" : "Droid"
			}
		}
	}
	`;
	Json exp = parseJson(s);
	assert(rslt == exp, format("exp:\n%s\ngot:\n%s", exp.toPrettyString(),
			rslt.toPrettyString()));
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionQueryTypeQuery {
			__schema {
				queryType {
					name
				}
			}
		}
		`);

	string s = `{
		"data" : {
			"__schema" : {
				"queryType" : {
					"name" : "queryType"
				}
			}
		}
	}
	`;
	Json exp = parseJson(s);
	assert(rslt == exp, format("exp:\n%s\ngot:\n%s", exp.toPrettyString(),
			rslt.toPrettyString()));
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionDroidTypeQuery {
			__type(name: "Droid") {
				name
				kind
			}
		}
		`);

	string s = `{
		"data" : {
			"__type" : {
				"name" : "Droid",
				"kind" : "OBJECT"
			}
		}
	}
	`;
	Json exp = parseJson(s);
	assert(rslt == exp, format("exp:\n%s\ngot:\n%s", exp.toPrettyString(),
			rslt.toPrettyString()));
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionCharacterKindQuery {
			__type(name: "Character") {
				name
				kind
			}
		}
		`);

	string s = `{
		"data" : {
			"__type" : {
				"name" : "Character",
				"kind" : "INTERFACE"
			}
		}
	}
	`;
	Json exp = parseJson(s);
	assert(rslt == exp, format("exp:\n%s\ngot:\n%s", exp.toPrettyString(),
			rslt.toPrettyString()));
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionDroidFieldsQuery {
			__type(name: "Droid") {
				name
				fields {
					name
					type {
						name
						kind
					}
				}
			}
		}
		`);

	string s = `
{
	"data": {
		"__type": {
			"fields": [
				{
					"type": {
						"kind": "SCALAR",
						"name": "String"
					},
					"name": "name"
				},
				{
					"type": {
						"kind": "LIST",
						"name": null
					},
					"name": "friends"
				},
				{
					"type": {
						"kind": "SCALAR",
						"name": "String"
					},
					"name": "secretBackstory"
				},
				{
					"type": {
						"kind": "SCALAR",
						"name": "String"
					},
					"name": "primaryFunction"
				},
				{
					"type": {
						"kind": "NON_NULL",
						"name": null
					},
					"name": "id"
				},
				{
					"type": {
						"kind": "LIST",
						"name": null
					},
					"name": "appearsIn"
				}
			],
			"name": "Droid"
		}
	}
}
	`;
	Json exp = parseJson(s);
	auto r = compareJson(exp, rslt, "", true);
	assert(r.okay, format("msg: %s\nexp:\n%s\ngot:\n%s", r
			, exp.toPrettyString(), rslt.toPrettyString()));
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionDroidNestedFieldsQuery {
			__type(name: "Droid") {
				name
				fields {
					name
					type {
						name
						kind
						ofType {
							name
							kind
						}
					}
				}
			}
		}
		`);

	string s = `{
		"data" : {
			"__type" : {
				"name" : "Droid",
				"fields" : [
					{
						"name": "primaryFunction",
						"type": {
							"name": "String",
							"kind": "SCALAR",
							"ofType": null
						}
					},
					{
						"name": "id",
						"type": {
							"name": null,
							"kind": "NON_NULL",
							"ofType": {
								"name": "String",
								"kind": "SCALAR"
							}
						}
					},
					{
						"name": "name",
						"type": {
							"name": "String",
							"kind": "SCALAR",
							"ofType": null
						}
					},
					{
						"name": "friends",
						"type": {
							"name": null,
							"kind": "LIST",
							"ofType": {
								"name": "Character",
								"kind": "INTERFACE"
							}
						}
					},
					{
						"name": "appearsIn",
						"type": {
							"name": null,
							"kind": "LIST",
							"ofType": {
								"name": "Episode",
								"kind": "ENUM"
							}
						}
					},
					{
						"name": "secretBackstory",
						"type": {
							"name": "String",
							"kind": "SCALAR",
							"ofType": null
						}
					},
				]
			}
		}
	}
	`;
	Json exp = parseJson(s);
	auto r = compareJson(exp, rslt, "", true);
	assert(r.okay, format("msg: %s\nexp:\n%s\ngot:\n%s"
			, r.message
			, exp.toPrettyString()
			, rslt.toPrettyString()));
}

@safe unittest {
	Json rslt = query(`
		query IntrospectionQueryTypeQuery {
			__schema {
				queryType {
					fields {
						name
						args {
							name
							description
							type {
								name
								kind
								ofType {
									name
									kind
								}
							}
							defaultValue
						}
					}
				}
			}
		}
		`);

	string s = ` {
		"data" : {
			"__schema": {
				"queryType": {
					"fields": [
						{
							"name": "droid",
							"args": [
								{
									"name": "id",
									"description": "id of the droid",
									"type": {
										"kind": "NON_NULL",
										"name": null,
										"ofType": {
											"kind": "SCALAR",
											"name": "String"
										}
									},
									"defaultValue": null
								}
							]
						},
						{
							"args": [
								{
									"description": "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.",
									"type": {
										"kind": "ENUM",
										"name": "Episode",
										"ofType": null
									},
									"defaultValue": null,
									"name": "episode",
								}
							],
							"name": "hero"
						},
						{
							"name": "human",
							"args": [
								{
									"name": "id",
									"description": "id of the human",
									"type": {
										"kind": "NON_NULL",
										"name": null,
										"ofType": {
											"kind": "SCALAR",
											"name": "String"
										}
									},
									"defaultValue": null
								}
							]
						},
						{
							"args": [
								{
									"description": "",
									"type": {
										"kind": "SCALAR",
										"ofType": null,
										"name": "Boolean"
									},
									"defaultValue": null,
									"name": "includeDeprecated"
								}
							],
							"name": "fields"
						},
						{
							"args": [],
							"name": "name"
						}
					]
				}
			}
		}
	}`;
	Json exp = parseJson(s);
	auto r = compareJson(exp, rslt, "", true);
	string extS = exp.toPrettyString();
	string rsltS = rslt.toPrettyString();
	assert(r.okay, format("msg: %s\nexp:\n%s\ngot:\n%s", r.message, extS, rsltS));
}

@safe unittest {
	Json rslt = query(`
		{
			__type(name: "Droid") {
				name
				description
			}
		}`);

	string s = `{
		"data" : {
			"__type": {
				"name" : "Droid",
				"description" : "A mechanical creature in the Star Wars universe."
			}
		}
	}`;
	Json exp = parseJson(s);
	auto r = compareJson(exp, rslt, "", true);
	string extS = exp.toPrettyString();
	string rsltS = rslt.toPrettyString();
	assert(r.okay, format("msg: %s\nexp:\n%s\ngot:\n%s", r.message, extS, rsltS));
}

@safe unittest {
	Json rslt = query(`
		{
			__type(name: "Character") {
				fields {
					name
					description
				}
			}
		}`);

	string s = `{
	"data": {
		"__type": {
			"fields": [
				{
					"description": "The id of the character",
					"name": "id"
				},
				{
					"description": "The name of the character",
					"name": "name"
				},
				{
					"description": "The friends of the character, or an empty list if they have none.",
					"name": "friends"
				},
				{
					"description": "Which movies they appear in.",
					"name": "appearsIn"
				},
				{
					"description": "Where are they from and how they came to be who they  are.",
					"name": "secretBackstory"
				}
			]
		}
	}
	}`;
	Json exp = parseJson(s);
	auto r = compareJson(exp, rslt, "", true);
	string extS = exp.toPrettyString();
	string rsltS = rslt.toPrettyString();
	assert(r.okay, format("msg: %s\nexp:\n%s\ngot:\n%s", r.message, extS, rsltS));
}
