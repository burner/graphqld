module countvisitor;

import std.traits : Unqual, Parameters;
import std.conv : to;
import std.stdio;
import std.string : indexOf;
import std.format;

import graphql.ast;
import graphql.visitor;
import graphql.tokenmodule;

class CountVisitor : Visitor {
	alias accept = Visitor.accept;
	alias enter = Visitor.enter;
	alias exit = Visitor.exit;

	mixin(genCountTables());
	mixin(genCountFunction());

	this() {
	}
}

string genCountFunction() {
	string ret;
	string[] all;
	static foreach(it; __traits(getOverloads, Visitor, "accept")) {{
		alias Params = Parameters!(it);
		enum pName = Params[0].stringof;
		static if(pName.indexOf("const(") == -1) {
			ret ~= format(`
		override void accept(%1$s f) {
			super.accept(f);
			this.%1$sCounter++;
		}

		override void enter(%1$s op) {
			this.%1$sCounterEnter++;
		}

		override void exit(%1$s op) {
			this.%1$sCounterExit++;
		}

		`, pName);
		}
	}}
	return ret;
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
	auto c = new ConstVisitor();
}
