module graphql.argumentextractortests;

import std.format : format;

import vibe.data.json;

import graphql.ast;
import graphql.astselector;
import graphql.helper : lexAndParse;
import graphql.argumentextractor;
import graphql.testschema;
import graphql.graphql;

unittest {
	string q = `
query a($s: boolean, $after: String) {
	starships(overSize: 10) {
		name
		crew @skip(if: $s) {
			...hyooman
			...robot
			...charac
		}
	}
	numberBetween(searchInput:
		{ first: 10
		, after: $after
		}
	) {
		id
	}
}

fragment hyooman on Humanoid {
	species
	dateOfBirth
}

fragment robot on Android {
	primaryFunction
}

fragment charac on Character {
	...robot
	id
	...hyooman
	name(get: $s)
	series
}`;

	Json vars = parseJsonString(`{ "s": false, "after": "Hello World" }`);

	Document doc = cast()lexAndParse(q);
	assert(doc !is null);

	{
		auto startships = astSelect!Field(doc, "a.starships");
		assert(startships !is null);

		Json args = getArguments(cast()startships, vars);
		assert(args == parseJsonString(`{"overSize" : 10}`),
				format("%s", args)
			);
	}

	{
		auto crew = astSelect!Field(doc, "a.starships.crew");
		assert(crew !is null);

		Json args = getArguments(cast()crew, vars);
		assert(args == parseJsonString(`{"if" : false}`), format("%s", args));
	}

	{
		auto name = astSelect!Field(doc, "a.starships.crew.name");
		assert(name !is null);

		Json args = getArguments(cast()name, vars);
		assert(args == parseJsonString(`{"get" : false}`), format("%s", args));
	}

	{
		auto searchInput = astSelect!Field(doc, "a.numberBetween");
		assert(searchInput !is null);

		Json args = getArguments(cast()searchInput, vars);
		assert(args == parseJsonString(
			`{ "searchInput": {"first" : 10, "after": "Hello World"}}`),
				format("%s", args));
	}
}
