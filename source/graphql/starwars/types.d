module graphql.starwars.types;

import std.typecons : Nullable, nullable;

import graphql.uda;

@safe:

@GQLDUda(
	GQLDDescription("One of the films in the Star Wars Trilogy")
)
enum Episode {
	NEWHOPE = 4,
	EMPIRE = 5,
	JEDI = 6
}

@GQLDUda(
	GQLDDescription("A character in the Star Wars Trilogy")
)
abstract class Character {
	@GQLDUda(GQLDDescription("The id of the character"))
	string id;

	@GQLDUda(GQLDDescription("The name of the character"))
	Nullable!string name;

	@GQLDUda(
		GQLDDescription("The friends of the character, or an empty list if "
			~ "they have none."
		)
	)
	Nullable!(string)[] friends;

	@GQLDUda(GQLDDescription("Which movies they appear in."))
	Episode[] appearsIn;

	this(string id, string name, string[] friends, int[] appearsIn) {
		import std.array : array;
		import std.algorithm.iteration : map;
		this.id = id;
		this.name = name;
		this.friends = friends.map!(f => nullable(f)).array;
		this.appearsIn = appearsIn.map!(e => cast(Episode)e).array;
	}
}

class Human : Character {
	string type;

	@GQLDUda(
		GQLDDescription("The home planet of the human, or null if unknown.")
	)
	string homePlanet;

	this(string id, string name, string[] friends, int[] appearsIn,
			string homePlanet)
	{
		super(id, name, friends, appearsIn);
		this.type = "Human";
		this.homePlanet = homePlanet;
	}
}

class Droid : Character{
	string type;
	@GQLDUda(
		GQLDDescription("The primary function of the droid.")
	)
	string primaryFunction;

	this(string id, string name, string[] friends, int[] appearsIn,
			string primaryFunction)
	{
		super(id, name, friends, appearsIn);
		this.type = "Human";
		this.primaryFunction = primaryFunction;
	}
}
