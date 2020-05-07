module graphql.testschema;

import std.algorithm.iteration : map;
import std.datetime : DateTime, Date;
import std.typecons : Nullable;
import std.format : format;

import vibe.data.json;
import nullablestore;

import graphql.schema.directives;
import graphql.helper;

import graphql.uda;

@safe:

Json datetimeToJson(DateTime dt) {
	return Json(dt.toISOExtString());
}

// The Schema used by graphqld

union SearchResult {
	Android android;
	Humanoid humanoid;
	Starship ship;
}

string dtToString(DateTime dt) {
	return dt.toISOExtString();
}

DateTime stringToDT(string s) {
	return DateTime.fromISOExtString(s);
}

@GQLDUda(TypeKind.OBJECT)
struct Query {
	@GQLDUda(
		GQLDDescription("Get the captain by Series")
	)
	Character captain(Series series);
	@GQLDUda(
		GQLDDeprecated(IsDeprecated.yes, "To complex")
	)
	SearchResult search(string name);
	Nullable!Starship starship(long id);
	Starship starshipDoesNotExist();
	Starship[] starships(float overSize = 100.0);
	Starship[] shipsselection(long[] ids);
	Nullable!Character character(long id);
	Character[] character(Series series);
	Humanoid[] humanoids();
	Android[] androids();
	Android[] resolverWillThrow();
	GQLDCustomLeaf!(DateTime, dtToString, stringToDT) currentTime();
	int currentTime();

	@GQLDUda(Ignore.yes)
	void ignoreMe() {
	}
}

unittest {
	Query d;
}

@GQLDUda(TypeKind.INPUT_OBJECT)
struct AddCrewmanData {
	string name;
	long shipId;
	Series[] series;
}

/*@GQLDUda(TypeKind.INPUT_OBJECT)
struct AddCrewmanComplexInput {
	Character crewman;
	Starship starship;
}*/

interface Mutation {
	Character addCrewman(AddCrewmanData input);
	//Starship addCrewmanCompley(AddCrewmanComplexInput input);
}

interface Subscription {
	Starship[] starships();
}

class Schema {
	Query queryType;
	Mutation mutationType;
	Subscription subscriptionType;
	DefaultDirectives directives;
}

enum Series {
	TheOriginalSeries,
	TheNextGeneration,
	DeepSpaceNine,
	Voyager,
	Enterprise,
	Discovery
}

@GQLDUda(TypeKind.INTERFACE)
abstract class Character {
	long id;
	string name;
	Series[] series;
	Character[] commands;
	Nullable!Starship ship;
	NullableStore!Starship ships;
	Character[] commanders;
	Nullable!Starship allwaysNull;
	Nullable!int alsoAllwaysNull;

	//NullableStore!AddCrewmanData data;
}

class Humanoid : Character {
	string species;
	GQLDCustomLeaf!(Date, dToString, stringToDT) dateOfBirth;
}

class Android : Character {
	string primaryFunction;

	@GQLDUda(Ignore.yes)
	void ignoreMeToo() {
	}
}

@GQLDUda(
	GQLDDescription("The thing Chracters fly around in")
)
class Starship {
	long id;
	string name;

	@GQLDUda(
		GQLDDescription("The name used when speaking about the ship")
	)
	string designation;
	double size;

	@GQLDUda(
		GQLDDescription("The person in charge")
	)
	Character commander;
	Nullable!(Series)[] series;
	Character[] crew;

	this(long id, string designation, double size, string name) {
		this.id = id;
		this.designation = designation;
		this.size = size;
		this.name = name;
	}

	override string toString() const @safe {
		return format!("Ship(id(%d), designation(%s), size(%.2f), name(%s)"
					~ "commander(%s), series[%(%s,%)], crew[%(%s,%)])")
			(
				 id, designation, size, name, commander.name, series,
				 crew.map!(a => a.name)
			);
	}
}
