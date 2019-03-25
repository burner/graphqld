module graphql.validation.fragments;

import std.array : back, empty, popBack;
import std.conv : to;
import std.format : format;
import std.exception : enforce;
import std.experimental.logger;

import vibe.data.json;

import fixedsizearray;

import graphql.ast;
import graphql.builder;
import graphql.visitor;
import graphql.validation.exception;

version(unittest) {
	import std.exception : assertThrown, assertNotThrown;
	import graphql.lexer;
	import graphql.parser;
}

@safe:

class FragmentValidator : Visitor {
	import std.experimental.typecons : Final;
	alias enter = Visitor.enter;
	alias exit = Visitor.exit;
	alias accept = Visitor.accept;

	const(Document) doc;

	this(const(Document) doc) {
		this.doc = doc;
	}

	string[][string] fragmentChildren;
	FixedSizeArray!string curFragment;

	override void enter(const(FragmentDefinition) frag) {
		this.curFragment.insertBack(frag.name.value);
	}

	override void exit(const(FragmentDefinition) frag) {
		this.curFragment.removeBack();
	}

	override void enter(const(FragmentSpread) fragSpread) {
		const(FragmentDefinition) frag = findFragment(this.doc,
				fragSpread.name.value
			);

		enforce!FragmentNotFoundException(frag !is null,
				format("No Fragment with name '%s' could be found",
					fragSpread.name.value)
			);

		if(!this.curFragment.empty) {
			string[]* children =
				() @trusted {
					return &(this.fragmentChildren.require(
							this.curFragment.back, new string[](1)
						));
				}();
			(*children) ~= frag.name.value;
		}
	}
}

bool noCylces(string[][string] frags) {
	foreach(string key; frags.byKey()) {
		noCylcesImpl([key], frags);
	}
	return true;
}

void noCylcesImpl(string[] toFind, string[][string] frags) {
	import std.algorithm.searching : canFind;
	auto toIter = toFind.back in frags;
	if(toIter is null) {
		return;
	}

	string[] follow = *toIter;
	foreach(f; follow) {
		enforce!FragmentCycleException(!canFind(toFind, f), format(
				"Found a cycle in the fragments '[%(%s -> %)]'", toFind ~ f
			));
		noCylcesImpl(toFind ~ f, frags);
	}
}

unittest {
	string simpleCylce = `
fragment Frag0 on Foo {
	...Frag1
}

fragment Frag1 on Foo {
	...Frag0
}

query Q {
	...Frag0
}`;

	auto l = Lexer(simpleCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();
	const(FragmentDefinition) f0 = findFragment(doc, "Frag0");
	assert(f0 !is null);
	const(FragmentDefinition) f1 = findFragment(doc, "Frag1");
	assert(f1 !is null);

	FragmentValidator fv = new FragmentValidator(doc);
	fv.accept(doc);
	assertThrown!(FragmentCycleException)(noCylces(fv.fragmentChildren));
}

unittest {
	string biggerCylce = `
fragment Frag0 on Foo {
	...Frag1
}

fragment Frag1 on Foo {
	...Frag2
}

fragment Frag2 on Foo {
	...Frag0
}

query Q {
	...Frag0
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	fv.accept(doc);
	assertThrown!(FragmentCycleException)(noCylces(fv.fragmentChildren));
}

unittest {
	string biggerCylce = `
fragment Frag0 on Foo {
	...Frag1
}

fragment Frag1 on Foo {
	...Frag2
}

fragment Frag2 on Foo {
	hello
}

query Q {
	...Frag0
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	fv.accept(doc);
	assertNotThrown(noCylces(fv.fragmentChildren));
}

unittest {
	string biggerCylce = `
fragment Frag0 on Foo {
	...Frag1
}

fragment Frag1 on Foo {
	...Frag
}

query Q {
	...Frag0
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	assertThrown!FragmentNotFoundException(fv.accept(doc));
}
