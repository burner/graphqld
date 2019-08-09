module graphql.starwars.schema;

import std.typecons : Nullable, nullable;

import graphql.starwars.data;
import graphql.starwars.types;
import graphql.uda;

@safe:

@GQLDUda(TypeKind.OBJECT)
struct StarWarsQuery {
	Nullable!Character hero(Nullable!Episode episode);
	Nullable!Human human(string id);
	Nullable!Droid droid(string id);
}

class StarWarsSchema {
	StarWarsQuery queryType;
}
