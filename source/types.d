module types;

import std.typecons : Flag;

alias NotNull = Flag!"NotNull";

struct GraphQLType {

}

unittest {
	static struct Foo {
		@GraphQLType() long id;
	}

	Foo foo;
}
