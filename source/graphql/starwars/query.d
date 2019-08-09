module graphql.starwars.query;

import std.typecons : Nullable, nullable;

import vibe.data.json;

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
	graphqld.setResolver("queryType", "hero",
			delegate(string name, Json parent, Json args,
					ref DefaultContext con) @safe
			{
				auto e = "episode" in args;
				Json ret = Json.emptyObject();
				ret["data"] = toGraphqlJson(getHero(
						e ? nullable(cast(Episode)(*e).to!int)
							: Nullable!(Episode).init
					));
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
						ret["data"] ~= toGraphqlJson(it);
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
	Json rslt = query(
		`query HeroNameQuery {
			hero {
				name
			}
		}`);

	string s = `{ "data" : { "hero" : { "name" : "R2-D2" } } }`;
	Json exp = parseJson(s);
	assert(rslt == exp, rslt.toPrettyString() ~ "\n" ~ exp.toPrettyString());
}

@safe unittest {
	Json rslt = query(
		`query HeroNameQuery {
			hero {
				name
			}
		}`);
	string s = `{ "data" : { "hero" : { "name" : "R2-D2" } } }`;
	Json exp = parseJson(s);
	assert(rslt == exp, rslt.toPrettyString() ~ "\n" ~ exp.toPrettyString());
}

@safe unittest {
	Json rslt = query(
		`query HeroNameAndFriendsQuery {
			hero {
				id
				name
				friends {
					name
				}
			}
		}`);
	string s = `{
			"data": {
				"hero": {
					"id": "2001",
					"name": "R2-D2",
					"friends": [
						{
							"name": "Luke Skywalker",
						},
						{
							"name": "Han Solo",
						},
						{
							"name": "Leia Organa",
						}
					]
				}
			}
		}`;
	Json exp = parseJson(s);
	assert(rslt == exp, rslt.toPrettyString() ~ "\n" ~ exp.toPrettyString());
}
