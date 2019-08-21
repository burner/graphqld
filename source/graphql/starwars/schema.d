module graphql.starwars.schema;

import std.typecons : Nullable, nullable;

import graphql.starwars.data;
import graphql.starwars.types;
import graphql.uda;

@safe:

@GQLDUda(TypeKind.OBJECT)
struct StarWarsQuery {
	Nullable!Character hero(
			@GQLDUda(GQLDDescription("If omitted, returns the hero of the "
					~ "whole saga. If provided, returns the hero of that "
					~ "particular episode."))
			Nullable!Episode episode
		);
	Nullable!Human human(
			@GQLDUda(GQLDDescription("id of the human")) string id
		);
	Nullable!Droid droid(
			@GQLDUda(GQLDDescription("id of the droid")) string id
		);
}

class StarWarsSchema {
	StarWarsQuery queryType;
}
