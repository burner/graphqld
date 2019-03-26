module graphql.validation.fragments;

import std.array : array, back, empty, popBack;
import std.algorithm.searching : canFind;
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
	import std.stdio;
	import graphql.lexer;
	import graphql.parser;
	import graphql.treevisitor;
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
	string[] allFrags;
	bool[string] reachedFragments;

	// Lone Anonymous Operation
	bool laoFound;

	// Unique Operation Names
	bool[string] operationNames;

	override void enter(const(OperationDefinition) od) {
		enforce!LoneAnonymousOperationException(!this.laoFound);
		if(canFind([OperationDefinitionEnum.SelSet,
					OperationDefinitionEnum.OT,
					OperationDefinitionEnum.OT_D,
					OperationDefinitionEnum.OT_V,
					OperationDefinitionEnum.OT_VD] ,od.ruleSelection))
		{
			this.laoFound = true;
		} else {
			enforce!NonUniqueOperationNameException(od.name.value !in
					this.operationNames, format(
						"Operation name '%s' already present in [%(%s, %)]",
						od.name.value, this.operationNames.byKey()
					)
				);
			this.operationNames[od.name.value] = true;
		}
	}

	override void enter(const(FragmentDefinition) frag) {
		enforce!FragmentNameAlreadyInUseException(
				!canFind(this.allFrags, frag.name.value),
				format("Fragment names '%s' already in use '[%(%s, %)]'",
					frag.name.value, this.allFrags)
			);

		this.allFrags ~= frag.name.value;
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

		this.reachedFragments[frag.name.value] = true;

		if(!this.curFragment.empty) {
			string[]* children =
				() @trusted {
					return &(this.fragmentChildren.require(
							this.curFragment.back, new string[](0)
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

bool[string] allReachable(bool[string] reached, string[][string] fragChildren) {
	bool[string] ret;
	foreach(string key; reached.byKey()) {
		enforce(!key.empty);
		ret[key] = true;
	}
	size_t oldLen;
	do {
		oldLen = ret.length;
		foreach(string key; ret.byKey()) {
			string[]* follow = key in fragChildren;
			if(follow !is null) {
				foreach(string f; *follow) {
					assert(!f.empty, format("%s [%(%s, %)]", key, *follow));
					ret[f] = true;
				}
			}
		}
	} while(ret.length > oldLen);
	return ret;
}

void allFragmentsReached(FragmentValidator fv) {
	import std.algorithm.setops : setDifference;
	import std.algorithm.sorting : sort;
	import std.algorithm.comparison : equal;
	bool[string] reached = allReachable(fv.reachedFragments,
			fv.fragmentChildren);
	auto af = fv.allFrags.sort;
	auto r = reached.byKey().array.sort;
	enforce!UnusedFragmentsException(equal(af, r),
			format("Fragments [%(%s, %)] are unused, allFrags [%(%s, %)], "
					~ "reached [%(%s, %)]",
					setDifference(af, r), af, r
				)
		);
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
	assertNotThrown(allFragmentsReached(fv));
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
	assertNotThrown(allFragmentsReached(fv));
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
	assertNotThrown(allFragmentsReached(fv));
}

unittest {
	import std.stdio;
	string biggerCylce = `
query Q {
	...Frag0
}

fragment Frag0 on Foo {
	...Frag1
}

fragment Frag1 on Foo {
	...Frag
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	assertThrown!FragmentNotFoundException(fv.accept(doc));
	assertNotThrown(allFragmentsReached(fv));
}

unittest {
	string biggerCylce = `
fragment Frag0 on Foo {
	...Frag1
}

fragment Frag0 on Foo {
	...Frag2
}

fragment Frag1 on Foo {
	...Frag2
}

fragment Frag2 on Foo {
	hello
}

fragment Frag4 on Foo {
	hello
}

query Q {
	...Frag0
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	assertThrown!FragmentNameAlreadyInUseException(fv.accept(doc));
	assertThrown!UnusedFragmentsException(allFragmentsReached(fv));
}

unittest {
	string biggerCylce = `
mutation Q {
	bar
}

query Q {
	foo
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	assertThrown!NonUniqueOperationNameException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
{
	bar
}

query Q {
	foo
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	assertThrown!LoneAnonymousOperationException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
{
	bar
}

{
	foo
}`;

	auto l = Lexer(biggerCylce);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();

	FragmentValidator fv = new FragmentValidator(doc);
	assertThrown!LoneAnonymousOperationException(fv.accept(doc));
}
