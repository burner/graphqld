module graphql.starwars.introspection;

import std.typecons : Nullable, nullable;
import std.format : format;
import std.experimental.logger;
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
					Json hj = toGraphqlJson!StarWarsSchema(h);
					Json cj = toGraphqlJson!StarWarsSchema(cast(Character)h);
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
				ret["data"] = toGraphqlJson!StarWarsSchema(getHero(
						e ? nullable((*e).to!string().to!Episode())
							: Nullable!(Episode).init
					));
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
						ret["data"] ~= toGraphqlJson!StarWarsSchema(it);
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

	string s = `{
		"data" : {
			"__schema" : {
				"types" : [
					{
						"name": "Query"
					},
					{
						"name": "Episode"
					},
					{
						"name": "Character"
					},
					{
						"name": "String"
					},
					{
						"name": "Human"
					},
					{
						"name": "Droid"
					},
					{
						"name": "__Schema"
					},
					{
						"name": "__Type"
					},
					{
						"name": "__TypeKind"
					},
					{
						"name": "Boolean"
					},
					{
						"name": "__Field"
					},
					{
						"name": "__InputValue"
					},
					{
						"name": "__EnumValue"
					},
					{
						"name": "__Directive"
					},
					{
						"name": "__DirectiveLocation"
					}
				]
			}
		}
	}`;
	Json exp = parseJson(s);
	// TODO write a json array compare that does not depend on the order
	//assert(rslt == exp, format("exp:\n%s\ngot:\n%s", exp.toPrettyString(),
	//		rslt.toPrettyString()));
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
					"name" : "StarWarsQuery"
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

	string s = `{
		"data" : {
			"__type" : {
				"name" : "Droid",
				"fields" : [
					{
						"name": "primaryFunction",
						"type": {
							"name": "String",
							"kind": "SCALAR"
						}
					},
					{
						"name": "id",
						"type": {
							"name": null,
							"kind": "NON_NULL"
						}
					},
					{
						"name": "name",
						"type": {
							"name": "String",
							"kind": "SCALAR"
						}
					},
					{
						"name": "friends",
						"type": {
							"name": null,
							"kind": "LIST"
						}
					},
					{
						"name": "appearsIn",
						"type": {
							"name": null,
							"kind": "LIST"
						}
					},
					{
						"name": "secretBackstory",
						"type": {
							"name": "String",
							"kind": "SCALAR"
						}
					},
				]
			}
		}
	}
	`;
	Json exp = parseJson(s);
	assert(rslt == exp, format("exp:\n%s\ngot:\n%s", exp.toPrettyString(),
			rslt.toPrettyString()));
}
