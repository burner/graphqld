module tokenmodule;

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
	on,
	alias_,
	true_,
	false_,
	null_,
	comment,
	comma,
	union_
}

struct Token {
	size_t line;
	size_t column;
	string value;

	TokenType type;

	this(TokenType type) {
		this.type = type;
	}

	this(TokenType type, string value) {
		this(type);
		this.value = value;
	}
}

