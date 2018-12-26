module testdata;

import std.stdio;
import std.array : array, back;
import std.format : format;
import std.algorithm : each, map, joiner;
import std.range : tee;

import types;

union SearchResult {
	Character character;
	Starship ship;
}

interface Query {
	Character captain(Series series);
	SearchResult search(string name);
	Starship starship(long id);
	Starship[] starships();
	Character character(long id);
	Character[] character(Series series);
}

interface Mutation {
	Character addCrewman(Series series, string name, string species);
}

interface Subscription {
	Character crewmanAdded(Series series);
}

class Interface {
	Query query;
	Mutation mutation;
	Subscription subscription;
}

enum Series {
	TheOriginalSeries,
	TheNextGeneration,
	DeepSpaceNine,
	Voyager,
	Enterprise,
	Discovery
}

class Character {
	long id;
	string name;
	Series[] series;
	Character[] commands;
	Starship ship;
	Character[] commanders;

	this(long id, string name) {
		this.id = id;
		this.name = name;
	}
}

class Humanoid : Character {
	string species;
	this(long id, string name, string species) {
		super(id, name);
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

class Android : Character {
	string primaryFunction;

	this(long id, string name, string pfunc) {
		super(id, name);
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
	string designation;
	double size;

	Character commander;
	Series[] series;
	Character[] crew;

	this(long id, string designation, double size) {
		this.id = id;
		this.designation = designation;
		this.size = size;
	}

	override string toString() const @safe {
		return format!("Ship(id(%d), designation(%s), size(%.2f), "
					~ "commander(%s), series[%(%s,%)], crew[%(%s,%)])")
			(
				 id, designation, size, commander.name, series, 
				 crew.map!(a => a.name)
			);
	}
}

class Data {
	Character[] chars;
	Starship[] ships;

	this() {
		long i;
		auto picard = new Humanoid(i++, "Jean-Luc Picard", "Human");
		picard.series ~= Series.TheNextGeneration;
		auto tng = [
			new Humanoid(i++, "William Riker", "Human"),
			new Humanoid(i++, "Deanna Troi", "Betazoid "),
			new Humanoid(i++, "Dr. Beverly Crusher", "Human"),
			new Humanoid(i++, "Worf", "Klingon"),
			new Android(i++, "Data", "Becoming Human"),
			new Humanoid(i++, "Geordi La Forge", "Human"),
			new Humanoid(i++, "Miles O'Brien", "Human")
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

		auto sisko = new Humanoid(i++, "Benjamin Sisko", "Human");
		auto ds9 = [
			new Humanoid(i++, "Odo", "Changeling"),
			new Humanoid(i++, "Jadzia Dax", "Trill"),
			new Humanoid(i++, "Dr. Julian Bashir", "Human"),
			new Humanoid(i++, "Kira Nerys", "Bajoran"),
			new Humanoid(i++, "Elim Garak", "Cardassian")
		];
		sisko.commands = cast(Character[])ds9;
		ds9.map!(a => a.series ~= Series.DeepSpaceNine).each;
		ds9.map!(a => a.commanders ~= sisko).each;

		tng[6].commanders ~= sisko;

		auto janeway = new Humanoid(i++, "Kathryn Janeway", "Human");
		auto voyager = [
			new Humanoid(i++, "Chakotay", "Human"),
			new Humanoid(i++, "Tuvok", "Vulcan"),
			new Humanoid(i++, "Neelix", "Talaxian"),
			new Humanoid(i++, "Seven of Nine", "Human"),
			new Humanoid(i++, "B'Elanna Torres", "Klingon"),
			new Humanoid(i++, "Tom Paris", "Human"),
			new Humanoid(i++, "Harry Kim", "Human"),
		];
		janeway.commands = cast(Character[])voyager;
		voyager.map!(a => a.series ~= Series.Voyager).each;
		voyager.map!(a => a.commanders ~= janeway).each;

		auto archer = new Humanoid(i++, "Jonathan Archer", "Human");
		auto enterprise = [
			new Humanoid(i++, "Charles Tucer III", "Human"),
			new Humanoid(i++, "Hoshi Sato", "Human"),
			new Humanoid(i++, "Dr. Phlox", "Denobulan"),
			new Humanoid(i++, "Malcolm Reed", "Human"),
			new Humanoid(i++, "Travis Mayweather", "Human"),
			new Humanoid(i++, "T'Pol", "Vulcan")
		];
		archer.commands = cast(Character[])enterprise;
		enterprise.map!(a => a.series ~= Series.Enterprise).each;

		auto kirk = new Humanoid(i++, "James T. Kirk", "Human");
		auto tos = [
			new Humanoid(i++, "Hikaru Sulu", "Human"),
			new Humanoid(i++, "Uhura", "Human"),
			new Humanoid(i++, "Montgomery Scott", "Human"),
			new Humanoid(i++, "Dr. Leonard McCoy", "Human"),
			new Humanoid(i++, "Spock", "Vulcan"),
			new Humanoid(i++, "Spock", "Vulcan"),
		];
		kirk.commands = cast(Character[])tos;
		tos.map!(a => a.series ~= Series.TheOriginalSeries).each;
		tos.map!(a => a.commanders ~= kirk).each;

		auto georgiou = new Humanoid(i++, "Philippa Georgiou", "Human");
		auto discovery = [
			new Humanoid(i++, "Michael Burnham", "Human"),
			new Humanoid(i++, "Paum Stamets", "Human"),
			new Humanoid(i++, "Sylvia Tilly", "Human"),
			new Humanoid(i++, "Ash Tyler", "Klingon"),
			new Humanoid(i++, "Saru", "Kelpien"),
			new Humanoid(i++, "Hugh Culber", "Human"),
		];
		georgiou.commands = cast(Character[])discovery;
		discovery.map!(a => a.series ~= Series.Discovery).each;
		discovery.map!(a => a.commanders ~= georgiou).each;

		this.ships ~= new Starship(i++, "NCC-1701E", 685.7);
		this.ships.back.series ~= Series.TheNextGeneration;
		this.ships.back.commander = picard;
		this.ships.back.crew ~= picard;
		this.ships.back.crew ~= tng;
		tng.map!(a => a.ship = this.ships.back).each;

		this.ships ~= new Starship(i++, "NX-74205", 130.0);
		this.ships.back.series ~= Series.DeepSpaceNine;
		this.ships.back.series ~= Series.TheOriginalSeries;
		this.ships.back.commander = sisko;
		this.ships.back.crew ~= picard;
		this.ships.back.crew ~= sisko;
		this.ships.back.crew ~= ds9;
		ds9.map!(a => a.ship = this.ships.back).each;

		this.ships ~= new Starship(i++, "NCC-74656", 343.0);
		this.ships.back.series ~= Series.Voyager;
		this.ships.back.commander = janeway;
		this.ships.back.crew ~= janeway;
		this.ships.back.crew ~= voyager;
		voyager.map!(a => a.ship = this.ships.back).each;

		this.ships ~= new Starship(i++, "NX-01", 225.0);
		this.ships.back.series ~= Series.Enterprise;
		this.ships.back.commander = archer;
		this.ships.back.crew ~= archer;
		this.ships.back.crew ~= enterprise;
		enterprise.map!(a => a.ship = this.ships.back).each;

		this.ships ~= new Starship(i++, "NCC-1701", 288.64);
		this.ships.back.series ~= Series.TheOriginalSeries;
		this.ships.back.series ~= Series.Discovery;
		this.ships.back.commander = kirk;
		this.ships.back.crew ~= kirk;
		this.ships.back.crew ~= tos;
		tos.map!(a => a.ship = this.ships.back).each;

		this.ships ~= new Starship(i++, "NCC-1031", 244.00);
		this.ships.back.series ~= Series.Discovery;
		this.ships.back.commander = georgiou;
		this.ships.back.crew ~= georgiou;
		this.ships.back.crew ~= discovery;
		discovery.map!(a => a.ship = this.ships.back).each;

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
