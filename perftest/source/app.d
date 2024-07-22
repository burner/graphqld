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

void main() {
	string toParse = readText("schema.docs.graphql");
	auto l = Lexer(toParse, QueryParser.no);
	//auto l = Lexer(toParse);
	auto p = Parser(l);
	Document d = p.parseDocument();
	auto cv = new CountVisitor();
	cv.accept(d);
	writeln(cv.countsToString());
}
