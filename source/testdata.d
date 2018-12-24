module testdata;

enum Series {
	TheOriginalSeries,
	TheNextGeneration,
	DeepSpaceNine,
	Voyager,
	Enterprise,
	Discovery
}

interface Character {
	@GQLnotNull
	long id;

	@GQLnotNull
	string name;

	Character[] friends;

	FriendsConnection friendConnection(long first, long id);

	Series[] appearsIn;
}

class Human : Character {
	string homePlanet;
}
