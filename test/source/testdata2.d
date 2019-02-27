module testdata2;

class Small {
	long id;
	string name;
}

interface Query2 {
	long foo();
	long bar();
	Small small();
	Small[] manysmall();
}

interface Mutation2 {
}

interface Subscription2 {
}

class Schema2 {
	Query2 query;
	Mutation2 mutation;
	Subscription2 subscription;
}
