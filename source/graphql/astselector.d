module graphql.astselector;

import std.array : back, empty, front, popBack;
import std.exception : enforce;

import graphql.tokenmodule;
import graphql.ast;
import graphql.visitor : ConstVisitor;

/* Sometimes you need to select a specific part of the ast,
this module allows to do that.
*/

@safe:

/+
const(T) astSelect(T,S)(const(S) input, string path) {
	auto astsel = new AstSelector(path);
	static if(is(S == Document)) {
		return astsel.get!T(input, input);
	} else {
		return astsel.get!T(input);
	}
}

const(T) astSelect(T,S)(const(S) input, const(Document) doc, string path) {
	auto astsel = new AstSelector(path);
	return astsel.get!T(input, doc);
}

class AstSelector : ConstVisitor {
	import std.format : format;
	import std.typecons : rebindable, Rebindable;
	alias enter = ConstVisitor.enter;
	alias exit = ConstVisitor.exit;
	alias accept = ConstVisitor.accept;

	Rebindable!(const(Document)) document;

	const(string[]) sp;
	size_t spPos;

	Rebindable!(const(Node)) result;
	Rebindable!(const(Node))[] stack;

	this(string p) {
		import std.string : split;
		this.sp = p.split('.');
	}

	const(T) get(T,S)(const(S) input, const(Document) doc) {
		this.document = doc;
		this.accept(input);
		return cast(typeof(return))this.result.get();
	}

	const(T) get(T,S)(const(S) input) {
		return this.get!T(input, null);
	}

	bool takeName(string name, const(Node) nn) {
		if(this.spPos < this.sp.length && name == this.sp[this.spPos]) {
			this.stack ~= rebindable(nn);
		} else {
			return false;
		}

		++this.spPos;
		if(this.spPos == this.sp.length) {
			enforce(this.result.get() is null);
			this.result = this.stack.back;
		}
		return true;
	}

	void popStack(bool shouldPop) {
		enforce(this.stack.length == this.spPos,
				format("stack.length %s, spPos %s", this.stack.length,
					this.spPos));
		enforce(shouldPop ? this.stack.length > 0 : true,
				"should pop put stack is empty");
		if(shouldPop) {
			this.stack.popBack();
			--this.spPos;
		}
	}

	override void accept(const(OperationDefinition) obj) {
		if(obj.name.type != TokenType.undefined) {
			immutable bool shouldPop = this.takeName(obj.name.value, obj);
			if(shouldPop) {
				if(obj.vd !is null) {
					obj.vd.visit(this);
				}
				if(obj.d !is null) {
					obj.d.visit(this);
				}
				if(obj.ss !is null) {
					obj.ss.visit(this);
				}
			}
			this.popStack(shouldPop);
		}
	}

	override void accept(const(Field) obj) {
		bool shouldPop;

		scope(exit) {
			this.popStack(shouldPop);
		}

		shouldPop = this.takeName(obj.name.name.value, obj);

		if(shouldPop) {
			if(obj.args !is null) {
				obj.args.visit(this);
			}
			if(obj.dirs !is null) {
				obj.dirs.visit(this);
			}
			if(obj.ss !is null) {
				obj.ss.visit(this);
			}
		}
	}

	override void accept(const(InlineFragment) obj) {
		if(obj.tc.type != TokenType.undefined) {
			immutable bool shouldPop = this.takeName(obj.tc.value, obj);
			if(shouldPop) {
				if(obj.dirs !is null) {
					obj.dirs.visit(this);
				}
				if(obj.ss !is null) {
					obj.ss.visit(this);
				}
			}
			this.popStack(shouldPop);
		}
	}

	override void accept(const(FragmentSpread) fragSpread) {
		import graphql.builder : findFragment;
		const(FragmentDefinition) frag = findFragment(this.document.get(),
				fragSpread.name.value
			);
		immutable bool shouldPop = this.takeName(fragSpread.name.value, frag);
		frag.visit(this);
		this.popStack(shouldPop);
	}
}

unittest {
	string s = `
query foo {
	a
}`;

	auto d = lexAndParse(s);
	auto foo = d.astSelect!OperationDefinition("foo");
	assert(foo !is null);
	assert(foo.name.value == "foo");
}

unittest {
	string s = `
query foo {
	a
}

mutation bar {
	b
}

`;

	auto d = lexAndParse(s);
	auto bar = d.astSelect!OperationDefinition("bar");
	assert(bar !is null);
	assert(bar.name.value == "bar");
}

unittest {
	string s = `
query foo {
	a {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto a = d.astSelect!Field("foo.a");
	assert(a !is null);
	assert(a.name.name.value == "a");
}

unittest {
	string s = `
query foo {
	a {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto a = d.astSelect!Document("foo.a");
	assert(a is null);
}

unittest {
	string s = `
query foo {
	a {
		b
	}
}

mutation a {
	foo {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto foo = d.astSelect!Field("a.foo");
	assert(foo !is null);
}

unittest {
	string s = `
query foo {
	a {
		b
	}
	c {
		b
	}
}

mutation a {
	foo {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto foo = d.astSelect!Field("foo.a.b");
	assert(foo !is null);
	assert(foo.name.name.value == "b");
}

unittest {
	string s = `
fragment Foo on Bar {
	a @skip(if: true)
}

query foo {
	...Foo
}

`;

	auto d = lexAndParse(s);
	auto a = d.astSelect!Field("foo.a");
	assert(a !is null);
	assert(a.dirs !is null);
	assert(a.dirs.dir.name.value == "skip");
}

import std.range : take;
import graphql.helper : lexAndParse;

struct RandomPaths {
	import std.random : choice, Random;
	import std.algorithm.sorting : sort;
	import std.algorithm.iteration : uniq, splitter, map, joiner;
	import std.conv : to;
	import std.range : take, iota;
	import std.array : array;
	import std.ascii : isWhite;
	import std.string : strip, split;
	string[] elems;
	string toIgnore;
	size_t len;

	string front;
	Random rnd;

	static RandomPaths opCall(string elems, string toIgnore, uint seed) {
		RandomPaths ret;

		ret.elems = elems.splitter!isWhite()
			.map!(e => e.strip)
			.array
			.sort
			.uniq
			.array;

		ret.toIgnore = toIgnore;
		ret.rnd = Random(seed);
		ret.len = toIgnore.split('.').length;
		return ret;
	}

	private void build() {
		do {
			this.front = iota(this.len)
				.map!(i => choice(this.elems, this.rnd))
				.joiner(".")
				.to!string();
		} while(this.front == this.toIgnore);
	}

	void popFront() {
		this.build();
	}

	enum bool empty = false;
}

unittest {
	import std.array : array;
	import std.algorithm.sorting : sort;
	import std.algorithm.iteration : uniq;
	import std.format : format;

	string s = ` query foo { a { b } c { b } foo ( args : 10 ) { ... on Foo {
			bar } } } mutation a { foo @ ship ( if : true) { b } } `;
	string toIgnore = "foo.a.b";

	string[] r = take(RandomPaths(s, toIgnore, 1337), 10).array.sort.release;
	string[] su = r.dup.sort.uniq.array;
	assert(r == su, format("\n%s\n%s", r, su));
}

unittest {
	string s = `
query foo {
	a {
		b
	}
	c {
		b
	}
	foo ( args : 10 ) {
		... on Foo {
			bar
		}
	}
}

mutation a {
	foo @ ship ( if : true) {
		b
	}
}
`;

	auto d = lexAndParse(s);
	string toIgnore = "foo.a.b";
	const(Field) foo = astSelect!Field(d, toIgnore);
	foreach(string p; take(RandomPaths(s, toIgnore, 1337), 5000)) {
		auto bar = astSelect!Field(d, p);
		assert(bar is null || bar !is foo);
	}
}
+/
