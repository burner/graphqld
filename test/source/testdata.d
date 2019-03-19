module testdata;

import std.stdio;
import std.conv : to;
import std.array : array, back;
import std.format : format;
import std.algorithm : each, map, joiner;
import std.range : tee;
import std.typecons : nullable, Nullable;
import std.experimental.logger;

import vibe.data.json;

import schema.directives;
import helper;

import types;
import uda;

@safe:

union SearchResult {
	Android android;
	Humanoid humanoid;
	Starship ship;
}

interface Query {
	Character captain(Series series);
	SearchResult search(string name);
	Nullable!Starship starship(long id);
	Starship[] starships(float overSize = 100.0);
	Starship[] shipsselection(long[] ids);
	Nullable!Character character(long id);
	Character[] character(Series series);
	Humanoid[] humanoids();
	Android[] androids();
}

@GQLDUda(TypeKind.INPUT_OBJECT)
struct AddCrewmanData {
	string name;
	long shipId;
	Series[] series;
}

interface Mutation {
	Character addCrewman(AddCrewmanData input);
}

interface Subscription {
	Character crewmanAdded(Series series);
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
	Character[] commanders;
}

Json characterToJson(Character c) {
	Json ret = returnTemplate();

	// direct
	ret["data"]["id"] = c.id;
	ret["data"]["name"] = c.name;
	ret["data"]["series"] = Json.emptyArray();
	ret["data"]["__typename"] = "Character";
	foreach(Series s; c.series) {
		ret["data"]["series"] ~= to!string(s);
	}

	// indirect
	ret["data"]["commandsIds"] = Json.emptyArray();
	foreach(Character cc; c.commands) {
		ret["data"]["commandsIds"] ~= cc.id;
	}

	// indirect
	if(c.ship.isNull()) {
		ret["data"]["shipId"] = Json(null);
	} else {
		ret["data"]["shipId"] = c.ship.get().id;
	}

	// indirect
	ret["data"]["commandersIds"] = Json.emptyArray();
	foreach(Character cc; c.commanders) {
		ret["data"]["commandersIds"] ~= cc.id;
	}

	if(Humanoid h = cast(Humanoid)c) {
		ret["data"]["species"] = h.species;
		ret["data"]["__typename"] = "Humanoid";
	}

	if(Android a = cast(Android)c) {
		ret["data"]["primaryFunction"] = a.primaryFunction;
		ret["data"]["__typename"] = "Android";
	}

	return ret;
}


class CharacterImpl : Character {
	this(long id, string name) {
		this.id = id;
		this.name = name;
	}
}

abstract class Humanoid : Character {
	string species;
}

class HumanoidImpl : Humanoid {
	this(long id, string name, string species) {
		this.id = id;
		this.name = name;
		this.species = species;
	}

	override string toString() const @safe {
		return format!("Humanoid(id(%d), name(%s), species(%s), "
					~ " series[%(%s,%)], commands[%(%s,%)], ship(%s)),"
					~ " commanders[%(%s,%)]")
			(
				id, name, species, series, commands.map!(a => a.name),
				ship ? ship.designation : "", commanders.map!(a => a.name)
			);
	}
}

abstract class Android : Character {
	string primaryFunction;
}

class AndroidImpl : Android {
	this(long id, string name, string pfunc) {
		this.id = id;
		this.name = name;
		this.primaryFunction = pfunc;
	}

	override string toString() const @safe {
		return format!("Android(id(%d), name(%s), function(%s), series[%(%s,%)], "
					~ " commands[%(%s,%)], ship(%s)), commanders[%(%s,%)]")
			(
				id, name, primaryFunction, series, commands.map!(a => a.name),
				ship ? ship.designation : "", commanders.map!(a => a.name)
			);
	}
}

class Starship {
	long id;
	string name;
	string designation;
	double size;

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

Json starshipToJson(Starship s) {
	Json ret = returnTemplate();

	// direct
	ret["data"]["id"] = s.id;
	ret["data"]["designation"] = s.designation;
	ret["data"]["name"] = s.name;
	ret["data"]["size"] = s.size;
	ret["data"]["series"] = Json.emptyArray();
	ret["data"]["__typename"] = "Starship";
	foreach(Nullable!Series show; s.series) {
		if(!show.isNull()) {
			ret["data"]["series"] ~= to!string(show.get());
		}
	}

	// indirect
	ret["data"]["commanderId"] = s.commander.id;
	ret["data"]["crewIds"] = Json.emptyArray();
	foreach(Character cm; s.crew) {
		ret["data"]["crewIds"] ~= cm.id;
	}

	logf("%s", ret.toPrettyString());
	return ret;
}

class Data {
	Character[] chars;
	Starship[] ships;
	long i;

	this() @trusted {
		auto picard = new HumanoidImpl(i++, "Jean-Luc Picard", "Human");
		auto worf = new HumanoidImpl(i++, "Worf", "Klingon");
		picard.series ~= Series.TheNextGeneration;
		auto tng = [
			new HumanoidImpl(i++, "William Riker", "Human"),
			new HumanoidImpl(i++, "Deanna Troi", "Betazoid "),
			new HumanoidImpl(i++, "Dr. Beverly Crusher", "Human"),
			worf,
			new AndroidImpl(i++, "Data", "Becoming Human"),
			new HumanoidImpl(i++, "Geordi La Forge", "Human"),
			new HumanoidImpl(i++, "Miles O'Brien", "Human")
		];
		picard.commands = tng;
		picard.series ~= Series.DeepSpaceNine;
		tng.map!(a => a.series ~= Series.TheNextGeneration).each;
		tng.map!(a => a.commanders ~= picard).each;
		tng[0].series ~= Series.Enterprise;
		tng[1].series ~= Series.Voyager;
		tng[1].series ~= Series.Enterprise;
		tng[3].series ~= Series.DeepSpaceNine;
		tng[6].series ~= Series.DeepSpaceNine;

		auto sisko = new HumanoidImpl(i++, "Benjamin Sisko", "Human");
		sisko.series ~= Series.DeepSpaceNine;
		auto ds9 = [
			new HumanoidImpl(i++, "Odo", "Changeling"),
			new HumanoidImpl(i++, "Jadzia Dax", "Trill"),
			new HumanoidImpl(i++, "Dr. Julian Bashir", "Human"),
			worf,
			new HumanoidImpl(i++, "Kira Nerys", "Bajoran"),
			new HumanoidImpl(i++, "Elim Garak", "Cardassian")
		];
		sisko.commands = cast(Character[])ds9;
		ds9.map!(a => a.series ~= Series.DeepSpaceNine).each;
		ds9.map!(a => a.commanders ~= sisko).each;

		tng[6].commanders ~= sisko;

		auto janeway = new HumanoidImpl(i++, "Kathryn Janeway", "Human");
		auto voyager = [
			new HumanoidImpl(i++, "Chakotay", "Human"),
			new HumanoidImpl(i++, "Tuvok", "Vulcan"),
			new HumanoidImpl(i++, "Neelix", "Talaxian"),
			new HumanoidImpl(i++, "Seven of Nine", "Human"),
			new HumanoidImpl(i++, "B'Elanna Torres", "Klingon"),
			new HumanoidImpl(i++, "Tom Paris", "Human"),
			new HumanoidImpl(i++, "Harry Kim", "Human"),
		];
		janeway.commands = cast(Character[])voyager;
		voyager.map!(a => a.series ~= Series.Voyager).each;
		voyager.map!(a => a.commanders ~= janeway).each;

		auto archer = new HumanoidImpl(i++, "Jonathan Archer", "Human");
		auto enterprise = [
			new HumanoidImpl(i++, "Charles Tucer III", "Human"),
			new HumanoidImpl(i++, "Hoshi Sato", "Human"),
			new HumanoidImpl(i++, "Dr. Phlox", "Denobulan"),
			new HumanoidImpl(i++, "Malcolm Reed", "Human"),
			new HumanoidImpl(i++, "Travis Mayweather", "Human"),
			new HumanoidImpl(i++, "T'Pol", "Vulcan")
		];
		archer.commands = cast(Character[])enterprise;
		enterprise.map!(a => a.series ~= Series.Enterprise).each;

		auto kirk = new HumanoidImpl(i++, "James T. Kirk", "Human");
		auto tos = [
			new HumanoidImpl(i++, "Hikaru Sulu", "Human"),
			new HumanoidImpl(i++, "Uhura", "Human"),
			new HumanoidImpl(i++, "Montgomery Scott", "Human"),
			new HumanoidImpl(i++, "Dr. Leonard McCoy", "Human"),
			new HumanoidImpl(i++, "Spock", "Vulcan"),
		];
		kirk.commands = cast(Character[])tos;
		tos.map!(a => a.series ~= Series.TheOriginalSeries).each;
		tos.map!(a => a.commanders ~= kirk).each;

		auto georgiou = new HumanoidImpl(i++, "Philippa Georgiou", "Human");
		auto discovery = [
			new HumanoidImpl(i++, "Michael Burnham", "Human"),
			new HumanoidImpl(i++, "Paum Stamets", "Human"),
			new HumanoidImpl(i++, "Sylvia Tilly", "Human"),
			new HumanoidImpl(i++, "Ash Tyler", "Klingon"),
			new HumanoidImpl(i++, "Saru", "Kelpien"),
			new HumanoidImpl(i++, "Hugh Culber", "Human"),
		];
		georgiou.commands = cast(Character[])discovery;
		discovery.map!(a => a.series ~= Series.Discovery).each;
		discovery.map!(a => a.commanders ~= georgiou).each;

		this.ships ~= new Starship(i++, "NCC-1701E", 685.7, "Enterprise");
		this.ships.back.series ~= nullable(Series.TheNextGeneration);
		this.ships.back.commander = picard;
		this.ships.back.crew = tng;
		this.ships.back.crew ~= picard;
		tng.map!(a => a.ship = nullable(this.ships.back)).each;

		this.ships ~= new Starship(i++, "NX-74205", 130.0, "Defiant");
		this.ships.back.series ~= nullable(Series.DeepSpaceNine);
		this.ships.back.series ~= nullable(Series.TheOriginalSeries);
		this.ships.back.commander = sisko;
		this.ships.back.crew = cast(Character[])ds9;
		this.ships.back.crew ~= sisko;
		ds9.map!(a => a.ship = nullable(this.ships.back)).each;

		this.ships ~= new Starship(i++, "NCC-74656", 343.0, "Voyager");
		this.ships.back.series ~= nullable(Series.Voyager);
		this.ships.back.series ~= nullable(Series.DeepSpaceNine);
		this.ships.back.commander = janeway;
		this.ships.back.crew = cast(Character[])voyager;
		this.ships.back.crew ~= janeway;
		voyager.map!(a => a.ship = nullable(this.ships.back)).each;

		this.ships ~= new Starship(i++, "NX-01", 225.0, "Enterprise");
		this.ships.back.series ~= nullable(Series.Enterprise);
		this.ships.back.commander = archer;
		this.ships.back.crew = cast(Character[])enterprise;
		this.ships.back.crew ~= archer;
		enterprise.map!(a => a.ship = nullable(this.ships.back)).each;

		this.ships ~= new Starship(i++, "NCC-1701", 288.64, "Enterprise");
		this.ships.back.series ~= nullable(Series.TheOriginalSeries);
		this.ships.back.series ~= nullable(Series.Discovery);
		this.ships.back.commander = kirk;
		this.ships.back.crew = cast(Character[])tos;
		this.ships.back.crew ~= kirk;
		tos.map!(a => a.ship = nullable(this.ships.back)).each;

		this.ships ~= new Starship(i++, "NCC-1031", 244.00, "Discovery");
		this.ships.back.series ~= nullable(Series.Discovery);
		this.ships.back.commander = georgiou;
		this.ships.back.crew = cast(Character[])discovery;
		this.ships.back.crew ~= georgiou;
		discovery.map!(a => a.ship = nullable(this.ships.back)).each;

		this.chars =
			joiner([
				cast(Character[])[picard, sisko, janeway, archer, kirk, georgiou],
				cast(Character[])tng, cast(Character[])ds9,
				cast(Character[])voyager, cast(Character[])enterprise,
				cast(Character[])tos, cast(Character[])discovery
			])
			.array;
	}
}

unittest {
	auto d = new Data();
}
