module testdata2;

import std.typecons : Nullable;

import schema.directives;

abstract class SmallChild {
	long id;
	string name;
	int foo(long a);
}

abstract class Small {
	long id;
	string name;
	abstract SmallChild[] arg(int a);
	SmallChild[] foobar;
}

interface Query2 {
	long foo();
	long bar();
	Nullable!Small small();
	Small[] manysmall();
}

interface Mutation2 {
}

interface Subscription2 {
}

class Schema2 {
	Query2 queryType;
	DefaultDirectives directives;
	//Mutation2 mutation;
	//Subscription2 subscription;
}
