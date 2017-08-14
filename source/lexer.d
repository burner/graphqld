module lexer;

import std.experimental.logger;
import std.format : format;

import tokenmodule;

struct Lexer {
	string input;
	size_t stringPos;

	size_t line;
	size_t column;

	Token cur;

	this(string input) {
		this.input = input;
		this.stringPos = 0;
		this.line = 1;
		this.column = 1;
		this.buildToken();
	}

	private bool isTokenStop() const {
		return this.stringPos >= this.input.length 
			|| this.isTokenStop(this.input[this.stringPos]);
	}

	private bool isTokenStop(const(char) c) const {
		return 
			c == ' ' || c == '\t' || c == '\n' || c == ';' || c == '(' 
			|| c == ')' || c == '{' || c == '}' || c == '!' || c == '=' 
			|| c == '|' || c == '*' || c == '/' || c == '[' || c == ':'
			|| c == ']' || c == ',' || c == '@' || c == '#';
	}

	private void eatWhitespace() {
		import std.ascii : isWhite;
		while(this.stringPos < this.input.length) {
			if(this.input[this.stringPos] == ' ') {
				++this.column;
			} else if(this.input[this.stringPos] == '\t') {
				++this.column;
			} else if(this.input[this.stringPos] == '\n') {
				this.column = 1;
				++this.line;
			} else {
				break;
			}
			++this.stringPos;
		}
	}

	private void buildToken() {
		import std.uni : isAlphaNum;
		this.eatWhitespace();

		if(this.stringPos >= this.input.length) {
			this.cur = Token(TokenType.undefined);
			return;
		}

		if(this.input[this.stringPos] == ')') {
			this.cur = Token(TokenType.rparen);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '(') {
			this.cur = Token(TokenType.lparen);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == ']') {
			this.cur = Token(TokenType.rbrack);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '[') {
			this.cur = Token(TokenType.lbrack);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '}') {
			this.cur = Token(TokenType.rcurly);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '{') {
			this.cur = Token(TokenType.lcurly);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '#') {
			size_t b = this.stringPos;	
			size_t e = this.stringPos;
			do {
				++this.stringPos;
				++this.column;
				++e;
			} while(this.stringPos < this.input.length 
					&& this.input[this.stringPos] != '\n');
			++this.line;
			++this.stringPos;
			this.cur = Token(TokenType.comment, this.input[b .. e]);
		} else if(this.input[this.stringPos] == ',') {
			this.cur = Token(TokenType.comma);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == '=') {
			this.cur = Token(TokenType.equal);
			++this.column;
			++this.stringPos;
		} else if(this.input[this.stringPos] == ':') {
			this.cur = Token(TokenType.colon);
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
					if(this.testCharAndInc('u', e)) {
						if(this.testCharAndInc('t', e)) {
							if(this.testCharAndInc('a', e)) {
								if(this.testCharAndInc('t', e)) {
									if(this.testCharAndInc('i', e)) {
										if(this.testCharAndInc('o', e)) {
											if(this.testCharAndInc('n', e)) {
												if(this.isTokenStop()) {
													this.cur = Token(TokenType.mutation);
													return;
												}
											}
										}
									}
								}
							}
						}
					}
					goto default;
				case '_':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('_', e)) {
						if(this.testCharAndInc('t', e)) {
							if(this.testCharAndInc('y', e)) {
								if(this.testCharAndInc('p', e)) {
									if(this.testCharAndInc('e', e)) {
										if(this.isTokenStop()) {
											this.cur = Token(TokenType.type);
											return;
										} else if(this.testCharAndInc('n', e)) {
											if(this.testCharAndInc('a', e)) {
												if(this.testCharAndInc('m', e)) {
													if(this.testCharAndInc('e', e)) {
														if(this.isTokenStop()) {
															this.cur = Token(TokenType.typename);
															return;
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
					goto default;
				case 's':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('u', e)) {
						if(this.testCharAndInc('p', e)) {
							if(this.testCharAndInc('s', e)) {
								if(this.testCharAndInc('c', e)) {
									if(this.testCharAndInc('r', e)) {
										if(this.testCharAndInc('i', e)) {
											if(this.testCharAndInc('p', e)) {
												if(this.testCharAndInc('t', e)) {
													if(this.testCharAndInc('i', e)) {
														if(this.testCharAndInc('o', e)) {
															if(this.testCharAndInc('n', e)) {
																if(this.isTokenStop()) {
																	this.cur = Token(TokenType.subscription);
																	return;
																}
															}
														}
													}
												}
											}
										}
									}
								}
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
							this.cur = Token(TokenType.on_);
							return;
						}
					}
					goto default;
				case 'f':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('a', e)) {
						if(this.testCharAndInc('l', e)) {
							if(this.testCharAndInc('s', e)) {
								if(this.testCharAndInc('e', e)) {
									if(this.isTokenStop()) {
										this.cur = Token(TokenType.false_);
										return;
									}
								}
							}
						}
					} else if(this.testCharAndInc('r', e)) {
						if(this.testCharAndInc('a', e)) {
							if(this.testCharAndInc('g', e)) {
								if(this.testCharAndInc('m', e)) {
									if(this.testCharAndInc('e', e)) {
										if(this.testCharAndInc('n', e)) {
											if(this.testCharAndInc('t', e)) {
												if(this.isTokenStop()) {
													this.cur = Token(TokenType.fragment);
													return;
												}
											}
										}
									}
								}
							}
						}
					}
					goto default;
				case '@':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('i', e)) {
						if(this.testCharAndInc('n', e)) {
							if(this.testCharAndInc('c', e)) {
								if(this.testCharAndInc('l', e)) {
									if(this.testCharAndInc('u', e)) {
										if(this.testCharAndInc('d', e)) {
											if(this.testCharAndInc('e', e)) {
												if(this.isTokenStop()) {
													this.cur = Token(TokenType.include_);
													return;
												}
											}
										}
									}
								}
							}
						}
					} else if(this.testCharAndInc('s', e)) {
						if(this.testCharAndInc('k', e)) {
							if(this.testCharAndInc('i', e)) {
								if(this.testCharAndInc('p', e)) {
									this.cur = Token(TokenType.skip);
									return;
								}
							}
						}
					} else if(isTokenStop()) {
						this.cur = Token(TokenType.at);
						return;
					}
					goto default;
				case 'q':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('u', e)) {
						if(this.testCharAndInc('e', e)) {
							if(this.testCharAndInc('r', e)) {
								if(this.testCharAndInc('y', e)) {
									if(this.isTokenStop()) {
										this.cur = Token(TokenType.query);
										return;
									}
								}
							}
						}
					}
					goto default;
				case 't':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('r', e)) {
						if(this.testCharAndInc('u', e)) {
							if(this.testCharAndInc('e', e)) {
								if(this.isTokenStop()) {
									this.cur = Token(TokenType.true_);
									return;
								}
							}
						}
					}
					goto default;
				case 'n':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('u', e)) {
						if(this.testCharAndInc('l', e)) {
							if(this.testCharAndInc('l', e)) {
								if(this.isTokenStop()) {
									this.cur = Token(TokenType.null_);
									return;
								}
							}
						}
					}
					goto default;
				case 'u':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('n', e)) {
						if(this.testCharAndInc('i', e)) {
							if(this.testCharAndInc('o', e)) {
								if(this.testCharAndInc('n', e)) {
									if(this.isTokenStop()) {
										this.cur = Token(TokenType.union_);
										return;
									}
								}
							}
						}
					}
					goto default;
				case '.':
					++this.stringPos;
					++this.column;
					++e;
					if(this.testCharAndInc('.', e)) {
						if(this.testCharAndInc('.', e)) {
							if(this.stringPos < this.input.length 
								&& isAlphaNum(this.input[this.stringPos])) 
							{
								this.cur = Token(TokenType.dots);
								return;
							}
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
						this.cur = Token(TokenType.intValue, this.input[b .. e]);
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

						this.cur = Token(TokenType.floatValue, this.input[b ..  e]);
						return;
					}
					goto default;
				case '"':
					++this.stringPos;
					++this.column;
					++e;
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
					this.cur = Token(TokenType.stringValue, this.input[b + 1 .. e]);
					break;
				default:
					do {
						++this.stringPos;
						++this.column;
						++e;
					} while(!this.isTokenStop());
					this.cur = Token(TokenType.name, this.input[b .. e]);
					break;
			}
		}
	}

	bool testCharAndInc(const(char) c, ref size_t e) {
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

	@property bool empty() const {
		return this.stringPos >= this.input.length
			&& this.cur.type == TokenType.undefined;
	}

	@property ref Token front() {
		return this.cur;
	}

	@property Token front() const {
		return this.cur;
	}

	void popFront() {
		this.buildToken();		
	}
}

unittest {
	string f = "fragment";
	auto l = Lexer(f);
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
	assert(l.front.type == TokenType.comment);
	assert(l.front.value == "# super cool comment");
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
