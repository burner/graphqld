module graphql.validation.querybased;

import std.array : array, back, empty, popBack;
import std.algorithm.searching : canFind;
import std.algorithm.sorting : sort;
import std.algorithm.iteration : each, uniq, filter, map, joiner;
import std.algorithm.setops : setDifference;
import std.algorithm.comparison : equal;
import std.conv : to;
import std.format : format;
import std.exception : enforce;
import std.experimental.logger;

import vibe.data.json;

import fixedsizearray;

import graphql.ast;
import graphql.builder;
import graphql.helper : lexAndParse;
import graphql.visitor;
import graphql.validation.exception;

import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import graphql.lexer;
import graphql.parser;
import graphql.treevisitor;

@safe:

struct OperationFragVar {
	const(OperationDefinition) op;
	bool[string] fragmentsUsed;
	bool[string] variablesDefined;
	bool[string] variablesUsed;

	this(const(OperationDefinition) op) {
		this.op = op;
	}
}

class QueryValidator : ConstVisitor {
	import std.experimental.typecons : Final;
	alias enter = ConstVisitor.enter;
	alias exit = ConstVisitor.exit;
	alias accept = ConstVisitor.accept;

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

	// Unique Operation names
	bool[string] operationNames;

	// Unique Argument names
	bool[string] argumentNames;

	// Unique Variable names
	bool[string] variableNames;

	// Variable usage
	bool variableDefinitionDone;
	bool[string] variableUsed;

	string[string] variablesUsedByFragments;

	OperationFragVar[] operations;

	override void exit(const(Document) doc) {
		foreach(ref OperationFragVar op; this.operations) {
			bool[string] allFragsReached = allReachable(op.fragmentsUsed,
					this.fragmentChildren
				);
			bool[string] varsUsedByOp = computeVariablesUsedByFragments(
					allFragsReached, this.variablesUsedByFragments
				);

			auto allVars = op.variablesDefined.byKey().array.sort.uniq;
			auto varUsed = (varsUsedByOp.byKey().array ~
					op.variablesUsed.byKey().array)
					.sort.uniq;

			enforce!VariablesUseException(equal(allVars, varUsed),
					format("Variables available [%(%s, %)], "
						~ "Variables used [%(%s, %)]", allVars, varUsed)
				);
		}
	}

	override void enter(const(Definition) od) {
		enforce!NoTypeSystemDefinitionException(
				od.ruleSelection != DefinitionEnum.T);
	}

	override void enter(const(OperationDefinition) od) {
		this.operations ~= OperationFragVar(od);

		this.variableDefinitionDone = false;

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
		if(!this.operations.empty) {
			this.operations.back.fragmentsUsed[fragSpread.name.value] = true;
		}

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

	override void enter(const(Arguments) al) {
		() @trusted {
			this.argumentNames.clear();
		}();
	}

	override void enter(const(Argument) al) {
		enforce!ArgumentsNotUniqueException(al.name.value !in this.argumentNames,
				format("Argument with name '%s' already present in [%(%s, %)]",
						al.name.value, this.argumentNames.byKey()
					)
			);
		this.argumentNames[al.name.value] = true;
	}

	override void enter(const(VariableDefinitions) vd) {
		() @trusted {
			this.variableNames.clear();
		}();
	}

	override void exit(const(VariableDefinitions) vd) {
		this.variableDefinitionDone = true;
	}

	override void enter(const(Variable) v) {
		if(variableDefinitionDone) {
			this.operations.back.variablesUsed[v.name.value] = true;
			if(!this.curFragment.empty) {
				this.variablesUsedByFragments[this.curFragment.back] =
					v.name.value;
			}
		} else {
			enforce!VariablesNotUniqueException(
					v.name.value !in this.variableNames,
					format(
						"Variable with name '%s' already present in [%(%s, %)]",
						v.name.value, this.variableNames.byKey()
					)
				);
			this.variableNames[v.name.value] = true;
			this.operations.back.variablesDefined[v.name.value] = true;
		}
	}
}

bool[string] computeVariablesUsedByFragments(bool[string] fragmentsUsed,
		string[string] variablesUsed)
{
	bool[string] ret;
	fragmentsUsed
		.byKey()
		.filter!(a => a in variablesUsed)
		.map!(a => variablesUsed[a])
		.array
		.sort
		.uniq
		.each!(a => ret[a] = true);
	return ret;
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

void allFragmentsReached(QueryValidator fv) {
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

	auto doc = lexAndParse(simpleCylce);
	const(FragmentDefinition) f0 = findFragment(doc, "Frag0");
	assert(f0 !is null);
	const(FragmentDefinition) f1 = findFragment(doc, "Frag1");
	assert(f1 !is null);

	QueryValidator fv = new QueryValidator(doc);
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

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
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

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
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

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
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

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
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

	QueryValidator fv = new QueryValidator(doc);
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

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
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

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertThrown!LoneAnonymousOperationException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
{
	bar
}

enum Dog {
	foo
}`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertThrown!NoTypeSystemDefinitionException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo($x: Int!) {
	bar(x: $x) {
		a
	}
}`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertNotThrown!ArgumentsNotUniqueException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo {
	foo(x: 10, y: 11.1) {
		bar(x: $x, y: $y) {
			i
		}
	}

	bar(x: 10, x: 11.1) {
		bar(x: $x, y: $x) {
			i
		}
	}
}`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertThrown!ArgumentsNotUniqueException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo($x: Int, $y: Float) {
	bar(x: $x, y: $y) {
		i
	}
}`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertNotThrown!VariablesNotUniqueException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo($x: Int, $x: Float) {
	bar(x: $x, y: $x) {
		i
	}
}`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertThrown!VariablesNotUniqueException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo($x: Int, $y: Float) {
	bar(x: $x) {
		i
	}
}`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertThrown!VariablesUseException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo($x: Int) {
	...Foo
}

fragment Foo on Bar {
	bar(x: $x) {
		i
	}
}
`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertNotThrown!VariablesUseException(fv.accept(doc));
}

unittest {
	string biggerCylce = `
query foo($x: Int, $y: Float) {
	...Foo
}

fragment Foo on Bar {
	bar(x: $x) {
		i
		...ZZZ
	}
}

fragment ZZZ on Bar {
	bar(x: $y) {
		i
	}
}
`;

	auto doc = lexAndParse(biggerCylce);

	QueryValidator fv = new QueryValidator(doc);
	assertNotThrown!VariablesUseException(fv.accept(doc));
}
