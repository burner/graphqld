module graphql.starwars.data;

import std.typecons : Nullable, nullable;

import graphql.starwars.types;

@safe:

Human[string] humanData() {
	static Human[string] ret;
	static bool created;
	if(!created) {
		ret["1000"] =new Human("1000", "Luke Skywalker",
			["1002", "1003", "2000", "2001"], [4, 5, 6], "Tatooine"
		);
		ret["1001"] = new Human("1001", "Darth Vader", ["1004"], [4, 5, 6],
			"Tatooine"
		);
		ret["1002"] = new Human("1002", "Han Solo", ["1000", "1003", "2001"],
			[4, 5, 6], ""
		);
		ret["1003"] = new Human("1003", "Leia Organa",
			["1000", "1002", "2000", "2001"], [4, 5, 6], "Alderaan"
		);
		ret["1004"] = new Human("1004", "Wilhuff Tarkin", ["1001"], [4], "");
		created = true;
	}
	return ret;
}

Droid[string] droidData() {
	static Droid[string] ret;
	static bool created;
	if(!created) {
		ret["2000"] = new Droid("2000", "C-3PO",
			["1000", "1002", "1003", "2001"], [4, 5, 6], "Protocol"
		);
		ret["2001"] = new Droid("2001", "R2-D2", ["1000", "1002", "1003"],
			[4, 5, 6], "Astromech"
		);
		created = true;
	}
	return ret;
}

Character getCharacter(string id) {
	auto h = id in humanData();
	if(h) {
		return *h;
	} else {
		auto d = id in droidData();
		if(d) {
			return *d;
		}
	}
	return null;
}

Character[] getFriends(Character c) {
	import std.array : array;
	import std.algorithm.iteration : map;
	return c.friends.map!(id => getCharacter(id)).array;
}

Character getHero(Nullable!Episode episode) {
	return !episode.isNull() && episode.get() == 5
		? humanData()["1000"]
		: droidData()["2001"];
}

Human getHuman(string id) {
	auto h = id in humanData();
	return h ? *h : null;
}

Droid getDroid(string id) {
	auto d = id in droidData();
	return d ? *d : null;
}
