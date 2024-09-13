module graphql.countvisitor;

import std.traits : Unqual, Parameters;
import std.conv : to;
import std.stdio;
import std.string : indexOf;
import graphql.ast;
import graphql.visitor;
import graphql.tokenmodule;
import graphql.parser;

class CountVisitor : ConstVisitor {
	alias accept = ConstVisitor.accept;
	alias enter = ConstVisitor.enter;
	alias exit = ConstVisitor.exit;

	mixin(genCountTables());

	this(Parser* parser) {
		super(parser);
	}
}

string genCountTables() {
	string ret;
	string[] all;
	static foreach(it; __traits(getOverloads, Visitor, "accept")) {{
		alias Params = Parameters!(it);
		enum pName = Params[0].stringof;
		static if(pName.indexOf("const(") == -1) {
			all ~= pName;
			ret ~= "\tlong " ~ Params[0].stringof ~ "Counter;\n";
			ret ~= "\tlong " ~ Params[0].stringof ~ "CounterEnter;\n";
			ret ~= "\tlong " ~ Params[0].stringof ~ "CounterExit;\n";
		}
	}}

	ret ~= `
	string countsToString() {
		string ret;
`;
	foreach(it; all) {
		ret ~= "\t\tret ~= \"" ~ it ~ "Counter = \" ~ to!string(" ~ it
			~ "Counter)" ~ " ~ \"\\n\";\n";
		ret ~= "\t\tret ~= \"" ~ it ~ "CounterEnter = \" ~ to!string(" ~ it
			~ "CounterEnter)" ~ " ~ \"\\n\";\n";
		ret ~= "\t\tret ~= \"" ~ it ~ "CounterExit = \" ~ to!string(" ~ it
			~ "CounterExit)" ~ " ~ \"\\n\";\n";
	}
	ret ~= `
		return ret;
	}
`;
	return ret;
}

unittest {
	Parser p;
	auto c = new ConstVisitor(&p);
}
