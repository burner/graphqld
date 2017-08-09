module ast;

import std.container.array;

import lexer;
import tokenmodule;

struct Directive {
	Token name;
}

struct Argument {
	Token name;
	Value value;

	this(Token name, Value value) {
		this.name = name;
		this.value = value;
	}
}

struct Arguments {
	Array!(Argument) arguments;
}

struct Value {
	Token value;
}
