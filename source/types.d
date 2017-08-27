module types;

import std.typecons : Flag;

alias NotNull = Flag!"NotNull";

struct GraphQLType {
	NotNull notNull;

	this(Args...)(auto ref Args args) {
		foreach(ref arg; args) {
			static if(is(typeof(arg) == NotNull)) {
				this.notNull = arg;
			}
		}
	}
}

unittest {
	static struct Foo {
		@GraphQLType(NotNull.yes) long id;
	}

	Foo foo;
}
