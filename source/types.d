module types;

import std.typecons : Flag;
public import taggedalgebraic;

alias NotNull = Flag!"NotNull";

struct GraphQLType {
	NotNull notNull;
	string description;

	this(Args...)(auto ref Args args) {
		foreach(ref arg; args) {
			static if(is(typeof(arg) == NotNull)) {
				this.notNull = arg;
			}
		}
	}
}

template GQLImplements(T) {
	enum GQLImplements = "";
}

unittest {
	import std.container.array;

	static struct Bar {

	}

	static struct Foo {
		@GraphQLType(NotNull.yes) long id;
		@GraphQLType() Array!string arr;
		mixin(GQLImplements!Bar);
	}

	Foo foo;
}

unittest {
	static struct Bar {
		int a;
	}

	static struct Foo {
		string a;
	}

	static union Foobar {
		Bar bar;
		Foo foo;
	}

	alias Foos = TaggedAlgebraic!Foobar;

	Foos foo;
	foo = Foo("10");
}

unittest {
	import lexer;
	import parser;
	import std.experimental.allocator;
	import std.experimental.allocator.mallocator : Mallocator;
	import std.stdio : writeln;

	string s = `{
  __schema {
    queryType {
      name
    }
  }
}`;
	auto l = Lexer(s);
	auto p = Parser(l);
	try {
		auto d = p.parseDocument();
	} catch(Throwable e) {
		writeln(e.toString());
		while(e.next) {
			writeln(e.next.toString());
			e = e.next;
		}
		assert(false);
	}
	assert(p.lex.empty);
}
