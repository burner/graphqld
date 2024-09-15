import std.stdio;
import std.file : readText;

import vibe.vibe;
import vibe.core.core;
import vibe.data.json;

import graphql.parser;
import graphql.builder;
import graphql.lexer;
import graphql.ast;

import graphql.helper;
import graphql.schema;
import graphql.traits;
import graphql.argumentextractor;
import graphql.schema.toschemafile;
import graphql.exception;
import graphql.graphql;
import graphql.testschema;

import countvisitor;

pragma(mangle, "_D4core8internal4hash__T6hashOfTAxS7graphql6schema18introspectiontypes6__TypeZQCcFNbNfQCcmZm")
ulong __fun() {
	return 0;
}

void main() {
	string toParse = readText("schema.docs.graphql");
	foreach(i; 0 .. 50) {
		auto l = Lexer(toParse, QueryParser.no);
		//auto l = Lexer(toParse);
		auto p = Parser(l);
		uint d = p.parseDocument();
		auto cv = new CountVisitor(&p);
		cv.accept(p.documents[0]);
		doNotOptimizeAway(cv.countsToString());
	}
}

void doNotOptimizeAway(T...)(auto ref T t)
{
    foreach (ref it; t)
    {
        doNotOptimizeAwayImpl(&it);
    }
}

private void doNotOptimizeAwayImpl(void* p)
{
    import core.thread : getpid;
    import std.stdio : writeln;

    if (getpid() == 0)
    {
        writeln(p);
    }
}
