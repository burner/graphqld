module graphql.tokenmodule;

import graphql.visitor;

enum TokenType {
	undefined,
	exclamation,
	dollar,
	lparen,
	rparen,
	dots,
	colon,
	equal,
	at,
	lbrack,
	rbrack,
	lcurly,
	rcurly,
	pipe,
	name,
	intValue,
	floatValue,
	stringValue,
	query,
	mutation,
	subscription,
	fragment,
	on_,
	alias_,
	true_,
	false_,
	null_,
	comment,
	comma,
	union_,
	type,
	typename,
	skip,
	include_,
	input,
	scalar,
	schema,
	schema__,
	directive,
	enum_,
	interface_,
	implements,
	extend,
}

struct Token {
@safe:
	size_t line;
	size_t column;
	string value;

	TokenType type;

	this(TokenType type) {
		this.type = type;
	}

	this(TokenType type, size_t line, size_t column) {
		this.type = type;
		this.line = line;
		this.column = column;
	}

	this(TokenType type, string value) {
		this(type);
		this.value = value;
	}

	this(TokenType type, string value, size_t line, size_t column) {
		this(type, line, column);
		this.value = value;
	}

	void visit(ConstVisitor vis) {
	}

	void visit(ConstVisitor vis) const {
	}

	void visit(Visitor vis) {
	}

	void visit(Visitor vis) const {
	}

	string toString() const {
		import std.format : format;
		return format("Token(%s,%s,%s,%s)", this.line, this.column, this.type,
				this.value);
	}
}

