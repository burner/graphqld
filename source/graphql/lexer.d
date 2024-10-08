module graphql.lexer;

version(LDC) {
	import std.experimental.logger;
} else {
	import std.logger;
}

import std.array : empty, front, popFront;
import std.format : format;
import std.typecons : Flag;
import std.stdio;

import graphql.tokenmodule;

alias QueryParser = Flag!"QueryParser";

struct Lexer {
	const QueryParser qp;
	string input;
	size_t stringPos;

	uint line;
	ushort column;

	Token cur;

	this(string input, QueryParser qp = QueryParser.yes) @safe {
		this.input = input;
		this.stringPos = 0;
		this.line = 1;
		this.column = 1;
		this.qp = qp;
		this.buildToken();
	}

	bool isNotQueryParser() @safe const {
		return this.qp == QueryParser.no;
	}

	private bool isTokenStop() const @safe {
		return this.stringPos >= this.input.length
			|| this.isTokenStop(this.input[this.stringPos]);
	}

	private bool isTokenStop(const(char) c) const @safe {
		import std.ascii : isWhite;
		import std.algorithm.searching : canFind;
		return isWhite(c)
			|| c == '('
			|| c == ')'
			|| c == '{'
			|| c == '}'
			|| c == '!'
			|| c == '='
			|| c == '|'
			|| c == '['
			|| c == ']'
			|| c == ']'
			|| c == ':'
			|| c == ','
			|| c == '@'
			|| c == '$';
	}

	private bool eatComment() @safe {
		if(this.stringPos < this.input.length &&
				this.input[this.stringPos] == '#')
		{
			++this.stringPos;
			while(this.stringPos < this.input.length &&
				this.input[this.stringPos] != '\n')
			{
				++this.stringPos;
			}
			++this.stringPos;
			++this.line;
			this.column = 1;
			return true;
		} else {
			return false;
		}
	}

	private void eatWhitespace() @safe {
		import std.ascii : isWhite;
		while(this.stringPos < this.input.length) {
			if(this.eatComment()) {
				continue;
			} else if(this.input[this.stringPos] == '\n') {
				this.column = 1;
				++this.line;
			} else if(this.input[this.stringPos].isWhite) {
				++this.column;
			} else {
				break;
			}
			++this.stringPos;
		}
	}

	private void buildToken() @safe {
		import std.ascii : isAlphaNum;
		this.eatWhitespace();

		if(this.stringPos >= this.input.length) {
			this.cur = Token(TokenType.undefined);
			return;
		}

		if(this.input[this.stringPos] == ')') {
			this.cur = Token(TokenType.rparen, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '(') {
			this.cur = Token(TokenType.lparen, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == ']') {
			this.cur = Token(TokenType.rbrack, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '[') {
			this.cur = Token(TokenType.lbrack, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '}') {
			this.cur = Token(TokenType.rcurly, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '$') {
			this.cur = Token(TokenType.dollar, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '!') {
			this.cur = Token(TokenType.exclamation, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '{') {
			this.cur = Token(TokenType.lcurly, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '|') {
			this.cur = Token(TokenType.pipe, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '@') {
			this.cur = Token(TokenType.at, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == ',') {
			this.cur = Token(TokenType.comma, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '=') {
			this.cur = Token(TokenType.equal, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == ':') {
			this.cur = Token(TokenType.colon, this.line, this.column);
			++this.column;
			++this.stringPos;
		} else {
			size_t b = this.stringPos;
			size_t e = this.stringPos;
			switch(this.input[this.stringPos]) {
				case 'm':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"utation"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.mutation, this.line,
										this.column);
							return;
						}
					}
					goto default;
				case 's':
					++this.stringPos;
					++this.column;
					++e;
					if(this.isNotQueryParser() &&
							this.testStrAndInc!"ubscription"(e))
					{
						if(this.isTokenStop()) {
							this.cur =
								Token(TokenType.subscription,
										this.line,
										this.column);
							return;
						}
					} else if(this.isNotQueryParser()
								&& this.testCharAndInc('c', e))
					{
						if(this.testStrAndInc!"alar"(e)) {
							if(this.isTokenStop()) {
								this.cur = Token(TokenType.scalar, this.line, this.column);
								return;
							}
						} else if(this.isNotQueryParser()
									&& this.testStrAndInc!"hema"(e))
						{
							if(this.isTokenStop()) {
								this.cur = Token(TokenType.schema, this.line, this.column);
								return;
							}
						}
					}
					goto default;
				case 'o':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('n', e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.on_, this.line,
									this.column);
							return;
						}
					}
					goto default;
				case 'd':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"irective"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.directive,
									this.line, this.column);
							return;
						}
					}
					goto default;
				case 'e':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"num"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.enum_,
									this.line, this.column);
							return;
						}
					} else if(this.testStrAndInc!"xtend"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.extend,
									this.line, this.column);
							return;
						}
					}
					goto default;
				case 'i':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('n', e)) {
						if(this.isNotQueryParser()
								&& this.testCharAndInc('p', e)
							)
						{
							if(this.testStrAndInc!"ut"(e)) {
								if(this.isTokenStop()) {
									this.cur = Token(TokenType.input,
											this.line, this.column);
									return;
								}
							}
						} else if(this.testStrAndInc!"terface"(e)) {
							if(this.isTokenStop()) {
								this.cur = Token(TokenType.interface_,
										this.line, this.column);
								return;
							}
						}
					} else if(this.testStrAndInc!"mplements"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.implements,
									this.line, this.column);
							return;
						}
					}

					goto default;
				case 'f':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"alse"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.false_,
									this.line, this.column);
							return;
						}
					} else if(this.testStrAndInc!"ragment"(e)) {
						if(this.isTokenStop()) {
							this.cur =
								Token(TokenType.fragment,
										this.line,
										this.column);
							return;
						}
					}
					goto default;
				case 'q':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"uery"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.query,
									this.line, this.column);
							return;
						}
					}
					goto default;
				case 't':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"rue"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.true_,
									this.line, this.column);
							return;
						}
					} else if(this.isNotQueryParser()
							&& this.testStrAndInc!"ype"(e))
					{
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.type,
									this.line, this.column);
							return;
						}
					}
					goto default;
				case 'n':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"ull"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.null_,
									this.line, this.column);
							return;
						}
					}
					goto default;
				case 'u':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!"nion"(e)) {
						if(this.isTokenStop()) {
							this.cur = Token(TokenType.union_,
									this.line, this.column);
							return;
						}
					}
					goto default;
				case '.':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testStrAndInc!".."(e)) {
						if(this.isTokenStop()
								|| (this.stringPos < this.input.length
									&& isAlphaNum(this.input[this.stringPos])
									)
							)
						{
							this.cur = Token(TokenType.dots, this.line,
									this.column);
							return;
						}
					}
					throw new Exception(format(
							"failed to parse \"...\" at line %s column %s",
							this.line, this.column
						));
				case '-':
					++this.stringPos;
					++this.column;
					++e;
					goto case '0';
				case '+':
					++this.stringPos;
					++this.column;
					++e;
					goto case '0';
				case '0': .. case '9':
					do {
						++this.stringPos;
						++this.column;
						++e;
					} while(this.stringPos < this.input.length
							&& this.input[this.stringPos] >= '0'
							&& this.input[this.stringPos] <= '9');

					if(this.stringPos >= this.input.length
							|| this.input[this.stringPos] != '.')
					{
						this.cur = Token(TokenType.intValue, this.input[b ..
								e], this.line, this.column);
						return;
					} else if(this.stringPos < this.input.length
							&& this.input[this.stringPos] == '.')
					{
						do {
							++this.stringPos;
							++this.column;
							++e;
						} while(this.stringPos < this.input.length
								&& this.input[this.stringPos] >= '0'
								&& this.input[this.stringPos] <= '9');

						this.cur = Token(TokenType.floatValue, this.input[b ..
								e], this.line, this.column);
						return;
					}
					goto default;
				case '"':
					++this.stringPos;
					++this.column;
					++e;
					//writeln("string start '''", this.input[this.stringPos .. $]
					//		, "'''");
					if(this.qp == QueryParser.no
							&& this.testStrAndIncOnFullMatch!(`""`)(e))
					{
						while(!this.testStrAndIncOnFullMatch!(`"""`)(e))
						{
							if(this.stringPos > this.input.length) {
								break;
							}
							if(this.input[this.stringPos] == '\n')
							{
								this.column = 1;
								++this.line;

							} else {
								++this.column;
							}
							++this.stringPos;
							++e;
						}
						//writeln("triple string done ", this.input[this.stringPos
						//		.. $]);
						//writefln("%s %s %s %s", b, e, this.stringPos
						//		, this.input.length);
						this.cur = Token(TokenType.stringValue
								, this.input[b + 3 .. e - 3], this.line
								, this.column
								);
					} else {
						//writeln("normal string");
						while(this.stringPos < this.input.length
								&& (this.input[this.stringPos] != '"'
									|| (this.input[this.stringPos] == '"'
										&& this.input[this.stringPos - 1U] == '\\')
							 		)
							)
						{
							++this.stringPos;
							++this.column;
							++e;
						}
						++this.stringPos;
						++this.column;
						this.cur = Token(TokenType.stringValue, this.input[b + 1
								.. e], this.line, this.column);
					}
					break;
				default:
					while(!this.isTokenStop()) {
						//writefln("455 '%s'", this.input[this.stringPos]);
						++this.stringPos;
						++this.column;
						++e;
					}
					this.cur = Token(TokenType.name, this.input[b .. e],
							this.line, this.column
						);
					break;
			}
		}
	}

	bool testCharAndInc(const(char) c, ref size_t e) @safe {
		if(this.stringPos < this.input.length
				&& this.input[this.stringPos] == c)
		{
			++this.column;
			++this.stringPos;
			++e;
			return true;
		} else {
			return false;
		}
	}

	bool testStrAndIncOnFullMatch(string s)(ref size_t e) @safe {
		for(size_t i = 0; i < s.length; ++i) {
			if(this.stringPos < this.input.length
					&& this.input[this.stringPos + i] == s[i])
			{
			} else {
				return false;
			}
		}
		this.column += s.length;
		this.stringPos += s.length;
		e += s.length;

		return true;
	}

	bool testStrAndInc(string s)(ref size_t e) @safe {
		for(size_t i = 0; i < s.length; ++i) {
			if(this.stringPos < this.input.length
					&& this.input[this.stringPos] == s[i])
			{
				++this.column;
				++this.stringPos;
				++e;
			} else {
				return false;
			}
		}

		return true;
	}

	@property bool empty() const @safe {
		return this.stringPos >= this.input.length
			&& this.cur.type == TokenType.undefined;
	}

	Token front() @property @safe {
		return this.cur;
	}

	@property Token front() const @safe @nogc pure {
		return this.cur;
	}

	void popFront() @safe {
		this.buildToken();
	}

	string getRestOfInput() const @safe {
		return this.input[this.stringPos .. $];
	}
}

private void test(string input, TokenType[] tokens, bool requireEmpty = true) {
	auto l = Lexer(input, QueryParser.no);
	Token[] token;
	foreach(idx, it; tokens) {
		assert(!l.empty
			, format("Was looking for '%s' at index '%s'in empty Lexer\n%s"
				, it, idx, token));
		assert(l.front.type == it
			, format("Wanted '%s' got '%s' at index %s\n%s", it, l.front.type
				, idx, token));
		token ~= l.front;
		l.popFront();
	}
	if(requireEmpty) {
		assert(l.empty
			, format("Lexer was not empty after all tokens have "
				~ "been consumpt\n%s", token));
	}
}

unittest {
	string f = "f ";
	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "f", format("'%s'", l.front.value));
}

unittest {
	string f = "... ";

	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.dots);
	l.popFront();
	assert(l.empty);
}

unittest {
	string f = "name! ";
	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "name", format("'%s'", l.front.value));
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.exclamation);
	l.popFront();
	assert(l.empty);
}

unittest {
	string f = "fragment";
	const l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.fragment);
}

unittest {
	string f = `
		mutation {
		  likeStory(storyID: 12345) {
		    story {
		      likeCount
		    }
		  }
		}`;
	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.mutation);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.lcurly);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.lparen);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.colon, format("%s", l.front.type));
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.intValue);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rparen);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.lcurly);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.lcurly);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rcurly);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rcurly);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rcurly);
	l.popFront();
	assert(l.empty);
}

unittest {
	string f = `
		query withFragments {
		  user(id: +4) {
			# super cool comment
friends(first: -10.3) {
		      ...friendFields
			  null false true
		    }
		    mutualFriends(first: 10) {
		      ...friendFields
		    }
		  }
		}

		fragment friendFields on User {
		  id
		  name
		  profilePic(size: 50)
		}`;
	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.query);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "withFragments");
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "user");
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "id", l.front.value);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.colon);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.intValue);
	assert(l.front.value == "+4");
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rparen);
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "friends");
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.lparen);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "first");
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.floatValue, format("%s", l.front.type));
	assert(l.front.value == "-10.3", l.front.value);
	l.popFront();
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.dots, format("%s", l.front.type));
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name, format("%s", l.front.type));
	assert(l.front.value == "friendFields");
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.null_, format("%s", l.front.type));
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.false_, format("%s", l.front.type));
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.true_, format("%s", l.front.type));
	while(!l.empty) {
		l.popFront();
	}
}

unittest {
	string f = `
		query withFragments {
		  user(id: "hello") {
		  }
		}`;

	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.query);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "withFragments");
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "user");
	l.popFront();
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name);
	assert(l.front.value == "id", l.front.value);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.colon);
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.stringValue);
	assert(l.front.value == "hello", format("'%s' '%s'", l.front.value, "hello"));
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rparen);
}

// Issue #20
unittest {
	string f = `# asldf
#
{ foo }
`;

	auto l = Lexer(f);
	assert(!l.empty);
	assert(l.front.type == TokenType.lcurly, l.front.toString());
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.name, l.front.toString());
	l.popFront();
	assert(!l.empty);
	assert(l.front.type == TokenType.rcurly, l.front.toString());
	l.popFront();
	assert(l.empty);
}

unittest {
	string f = `""" a long comment """ `;

	auto l = Lexer(f, QueryParser.no);
	assert(!l.empty);
	assert(l.front.type == TokenType.stringValue, l.front.toString());
	assert(l.front.value == " a long comment ", format("'%s'", l.front.value));
	l.popFront();
	assert(l.empty);
}

unittest {
	import std.string : indexOf;

	string f = `""" a

		long

		comment """ `;

	auto l = Lexer(f, QueryParser.no);
	assert(!l.empty);
	assert(l.front.type == TokenType.stringValue, l.front.toString());
	assert(l.front.value.indexOf("a") != -1);
	assert(l.front.value.indexOf("long") != -1);
	assert(l.front.value.indexOf("comment") != -1);
	assert(l.front.value.indexOf("\n") != -1);
	l.popFront();
	assert(l.empty);
}

unittest {
	import std.string : indexOf;

	string f = `
"""
Defines what type of global IDs are accepted for a mutation argument of type ID.
"""
directive @possibleTypes(
  """
  Abstract type of accepted global ID
  """
  abstractType: String

  """
  Accepted types of global IDs.
  """
  concreteTypes: [String!]!
) on INPUT_FIELD_DEFINITION
`;

	auto l = Lexer(f, QueryParser.no);
	test(f, [ TokenType.stringValue, TokenType.directive, TokenType.at
			, TokenType.name, TokenType.lparen, TokenType.stringValue
			, TokenType.name, TokenType.colon, TokenType.name
			, TokenType.stringValue, TokenType.name, TokenType.colon
			, TokenType.lbrack, TokenType.name, TokenType.exclamation
			, TokenType.rbrack, TokenType.exclamation, TokenType.rparen
			, TokenType.on_, TokenType.name
	]);
}

unittest {
	string f = `
  """
  Optional comment for approving deployments
  """
  comment: String = ""
`;
	test(f, [ TokenType.stringValue, TokenType.name, TokenType.colon
			, TokenType.name, TokenType.equal, TokenType.stringValue]);

}

unittest {
	string f = `
  """
  Optional comment for approving deployments
  """
  comment: String = ""

  """
  The ids of environments to reject deployments
  """
`;
	test(f, [ TokenType.stringValue, TokenType.name, TokenType.colon
			, TokenType.name, TokenType.equal, TokenType.stringValue
			, TokenType.stringValue]);

}
