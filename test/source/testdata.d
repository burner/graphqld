module testdata;

import std.stdio;
import std.datetime : DateTime, Date;
import std.conv : to;
import std.array : array, back;
import std.format : format;
import std.algorithm : each, map, joiner;
import std.range : tee;
import std.typecons : nullable, Nullable;
import std.experimental.logger;

import vibe.data.json;

import nullablestore;

import graphql.testschema;
import graphql.helper : returnTemplate;
import graphql.uda;

@safe:

// The database impl

Json characterToJson(Character c) {
	Json ret = Json.emptyObject();
	ret["data"] = Json.emptyObject();

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
		ret["data"]["dateOfBirth"] = Json(h.dateOfBirth.toISOExtString());
	}

	if(Android a = cast(Android)c) {
		ret["data"]["primaryFunction"] = a.primaryFunction;
		ret["data"]["__typename"] = "Android";
	}

	return ret;
}


class CharacterImpl : Character {
	@GQLDUda(Ignore.yes)
	this(long id, string name) {
		this.id = id;
		this.name = name;
	}
}

class HumanoidImpl : Humanoid {
	@GQLDUda(Ignore.yes)
	this(long id, string name, string species, Date dob) {
		this.id = id;
		this.name = name;
		this.species = species;
		this.dateOfBirth = dob;
	}

	@GQLDUda(Ignore.yes)
	override string toString() const @safe {
		return format!("Humanoid(id(%d), name(%s), species(%s), "
					~ " series[%(%s,%)], commands[%(%s,%)], ship(%s)),"
					~ " commanders[%(%s,%)]")
			(
				id, name, species, series, commands.map!(a => a.name),
				!ship.isNull() ? ship.get().designation : ""
				, commanders.map!(a => a.name)
			);
	}
}

class AndroidImpl : Android {
	this(long id, string name, string pfunc) {
		this.id = id;
		this.name = name;
		this.primaryFunction = pfunc;
	}

	@GQLDUda(Ignore.yes)
	override string toString() const @safe {
		return format!("Android(id(%d), name(%s), function(%s), series[%(%s,%)], "
					~ " commands[%(%s,%)], ship(%s)), commanders[%(%s,%)]")
			(
				id, name, primaryFunction, series, commands.map!(a => a.name),
				!ship.isNull() ? ship.get().designation : "",
				commanders.map!(a => a.name)
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

	//logf("%s", ret.toPrettyString());
	return ret;
}

class Data {
	Character[] chars;
	Starship[] ships;
	long i;

	@GQLDUda(Ignore.yes)
	this() @trusted {
		auto picard = new HumanoidImpl(i++, "Jean-Luc Picard", "Human",
				Date(2305, 7, 13));
		auto worf = new HumanoidImpl(i++, "Worf", "Klingon", Date(2340, 5, 23));
		picard.series ~= Series.TheNextGeneration;
		auto tng = [
			new HumanoidImpl(i++, "William Riker", "Human", Date(2335, 8, 19)),
			new HumanoidImpl(i++, "Deanna Troi", "Betazoid", Date(2336, 3, 29)),
			new HumanoidImpl(i++, "Dr. Beverly Crusher", "Human",
					Date(2324, 10, 13)),
			worf,
			new AndroidImpl(i++, "Data", "Becoming Human"),
			new HumanoidImpl(i++, "Geordi La Forge", "Human", Date(2335, 2, 16)),
			new HumanoidImpl(i++, "Miles O'Brien", "Human", Date(2328, 9, 1))
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

		auto sisko = new HumanoidImpl(i++, "Benjamin Sisko", "Human",
				Date(2332, 1, 1));
		sisko.series ~= Series.DeepSpaceNine;
		auto ds9 = [
			new HumanoidImpl(i++, "Odo", "Changeling", Date(1970, 1, 1)),
			new HumanoidImpl(i++, "Jadzia Dax", "Trill", Date(2346, 8, 20)),
			new HumanoidImpl(i++, "Dr. Julian Bashir", "Human", Date(2341, 1, 1)),
			worf,
			new HumanoidImpl(i++, "Kira Nerys", "Bajoran", Date(2343, 1, 1)),
			new HumanoidImpl(i++, "Elim Garak", "Cardassian", Date(2320, 1, 1))
		];
		sisko.commands = cast(Character[])ds9;
		ds9.map!(a => a.series ~= Series.DeepSpaceNine).each;
		ds9.map!(a => a.commanders ~= sisko).each;

		tng[6].commanders ~= sisko;

		auto janeway = new HumanoidImpl(i++, "Kathryn Janeway", "Human",
				Date(2330, 5, 20));
		auto voyager = [
			new HumanoidImpl(i++, "Chakotay", "Human", Date(2329, 1, 1)),
			new HumanoidImpl(i++, "Tuvok", "Vulcan", Date(2361, 10, 10)),
			new HumanoidImpl(i++, "Neelix", "Talaxian", Date(2340, 1, 1)),
			new HumanoidImpl(i++, "Seven of Nine", "Human", Date(2348, 6, 24)),
			new HumanoidImpl(i++, "B'Elanna Torres", "Klingon", Date(2349, 2, 1)),
			new HumanoidImpl(i++, "Tom Paris", "Human", Date(2346, 2, 1)),
			new HumanoidImpl(i++, "Harry Kim", "Human", Date(2349, 2, 1)),
		];
		janeway.commands = cast(Character[])voyager;
		voyager.map!(a => a.series ~= Series.Voyager).each;
		voyager.map!(a => a.commanders ~= janeway).each;

		auto archer = new HumanoidImpl(i++, "Jonathan Archer", "Human",
				Date(2112, 10, 9));
		auto enterprise = [
			new HumanoidImpl(i++, "Charles Tucker III", "Human", Date(2121, 2,
						1)),
			new HumanoidImpl(i++, "Hoshi Sato", "Human", Date(2129, 7, 9)),
			new HumanoidImpl(i++, "Dr. Phlox", "Denobulan", Date(2080, 2, 1)),
			new HumanoidImpl(i++, "Malcolm Reed", "Human", Date(2117, 9, 2)),
			new HumanoidImpl(i++, "Travis Mayweather", "Human", Date(2121, 2, 1)),
			new HumanoidImpl(i++, "T'Pol", "Vulcan", Date(2088, 2, 1))
		];
		archer.commands = cast(Character[])enterprise;
		enterprise.map!(a => a.series ~= Series.Enterprise).each;

		auto kirk = new HumanoidImpl(i++, "James T. Kirk", "Human",
				Date(2202, 2, 1));
		auto tos = [
			new HumanoidImpl(i++, "Hikaru Sulu", "Human", Date(2237, 2, 1)),
			new HumanoidImpl(i++, "Uhura", "Human", Date(2239, 2, 1)),
			new HumanoidImpl(i++, "Montgomery Scott", "Human", Date(2222, 2, 1)),
			new HumanoidImpl(i++, "Dr. Leonard McCoy", "Human", Date(2227, 2, 1)),
			new HumanoidImpl(i++, "Spock", "Vulcan", Date(2230, 2, 1)),
		];
		kirk.commands = cast(Character[])tos;
		tos.map!(a => a.series ~= Series.TheOriginalSeries).each;
		tos.map!(a => a.commanders ~= kirk).each;

		auto georgiou = new HumanoidImpl(i++, "Philippa Georgiou", "Human",
				Date(2202, 2, 1));
		auto discovery = [
			new HumanoidImpl(i++, "Michael Burnham", "Human", Date(2226, 2, 1)),
			new HumanoidImpl(i++, "Paul Stamets", "Human", Date(2225, 2, 1)),
			new HumanoidImpl(i++, "Sylvia Tilly", "Human", Date(2230, 2, 1)),
			new HumanoidImpl(i++, "Ash Tyler", "Klingon", Date(2230, 2, 1)),
			new HumanoidImpl(i++, "Saru", "Kelpien", Date(2230, 2, 1)),
			new HumanoidImpl(i++, "Hugh Culber", "Human", Date(2227, 2, 1)),
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
