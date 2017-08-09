module parser;

import lexer;
import tokenmodule;
import ast;

import std.format : format;

struct Parser {
	Lexer lexer;
	
	this(string input) {
		this.lexer = Lexer(input);
	}

	Token testAndPopToken(TokenType type) {
		if(this.lexer.empty) {
			throw new Exception(format(
					"Lexer out of tokens while looking for a '%s'",
					type
				));
		}
		if(this.lexer.front.type != type) {
			throw new Exception(format(
					"Found '%s' while looking for a '%s'",
					this.lexer.front.type, type
				));
		}
		Token ret = this.lexer.front;
		this.lexer.popFront();
		return ret;
	}

	bool test(TokenType type) {
		return this.lexer.front.type == type;
	}

	Arguments parseArguments() {
		testAndPopToken(TokenType.lparen);
		Arguments ret;
		while(this.lexer.front.type != TokenType.rparen) {
			ret.arguments.insertBack(this.parseArgument);
			if(test(TokenType.comma)) {
				this.lexer.popFront();
			}
		}
		testAndPopToken(TokenType.rparen);
		return ret;
	}

	Argument parseArgument() {
		Token name = testAndPopToken(TokenType.name);
		testAndPopToken(TokenType.colon);
		Value value = this.parseValue();

		return Argument(name, value);
	}

	Value parseValue() {
		if(this.lexer.front.type == TokenType.intValue
			|| this.lexer.front.type == TokenType.floatValue
			|| this.lexer.front.type == TokenType.stringValue
			|| this.lexer.front.type == TokenType.null_
			|| this.lexer.front.type == TokenType.true_
			|| this.lexer.front.type == TokenType.false_
			// TODO enum
			// TODO listValue
			// TODO object
		) 
		{
			Token ret = this.lexer.front;
			this.lexer.popFront();
			return Value(ret);
		} else {
			throw new Exception(format("Failed to parse Value, found '%s'",
					this.lexer.front
				));
		}
	}
}

unittest {
	string s = "(a : 10, b : \"h\")";
	auto p = Parser(s);

	auto args = p.parseArguments();
	assert(args.arguments.length == 2);
}
