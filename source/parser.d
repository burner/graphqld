module parser;

import std.typecons : RefCounted, refCounted;
import std.format : format;
import ast;
import tokenmodule;

import lexer;

import exception;

struct Parser {
	import std.array : appender;

	import std.format : formattedWrite;

	Lexer lex;

	this(Lexer lex) {
		this.lex = lex;
	}

	bool firstDocument() const pure @nogc @safe {
		return this.firstDefinitions();
	}

	Document parseDocument() {
		try {
			return this.parseDocumentImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Document an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Document parseDocumentImpl() {
		if(this.firstDefinitions()) {
			Definitions defs = this.parseDefinitions();

			return new Document(DocumentEnum.Defi
				, defs
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Definitions. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDefinitions() const pure @nogc @safe {
		return this.firstDefinition();
	}

	Definitions parseDefinitions() {
		try {
			return this.parseDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Definitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Definitions parseDefinitionsImpl() {
		if(this.firstDefinition()) {
			Definition def = this.parseDefinition();
			if(this.firstDefinitions()) {
				Definitions follow = this.parseDefinitions();

				return new Definitions(DefinitionsEnum.Defs
					, def
					, follow
				);
			}
			return new Definitions(DefinitionsEnum.Def
				, def
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Definition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDefinition() const pure @nogc @safe {
		return this.firstOperationDefinition()
			 || this.firstFragmentDefinition()
			 || this.firstTypeSystemDefinition();
	}

	Definition parseDefinition() {
		try {
			return this.parseDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Definition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Definition parseDefinitionImpl() {
		if(this.firstOperationDefinition()) {
			OperationDefinition op = this.parseOperationDefinition();

			return new Definition(DefinitionEnum.O
				, op
			);
		} else if(this.firstFragmentDefinition()) {
			FragmentDefinition frag = this.parseFragmentDefinition();

			return new Definition(DefinitionEnum.F
				, frag
			);
		} else if(this.firstTypeSystemDefinition()) {
			TypeSystemDefinition type = this.parseTypeSystemDefinition();

			return new Definition(DefinitionEnum.T
				, type
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an OperationDefinition, FragmentDefinition, or TypeSystemDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationDefinition() const pure @nogc @safe {
		return this.firstSelectionSet()
			 || this.firstOperationType();
	}

	OperationDefinition parseOperationDefinition() {
		try {
			return this.parseOperationDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	OperationDefinition parseOperationDefinitionImpl() {
		if(this.firstSelectionSet()) {
			SelectionSet ss = this.parseSelectionSet();

			return new OperationDefinition(OperationDefinitionEnum.SelSet
				, ss
			);
		} else if(this.firstOperationType()) {
			OperationType ot = this.parseOperationType();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstVariableDefinitions()) {
					VariableDefinitions vd = this.parseVariableDefinitions();
					if(this.firstDirectives()) {
						Directives d = this.parseDirectives();
						if(this.firstSelectionSet()) {
							SelectionSet ss = this.parseSelectionSet();

							return new OperationDefinition(OperationDefinitionEnum.OT_VD
								, ot
								, name
								, vd
								, d
								, ss
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return new OperationDefinition(OperationDefinitionEnum.OT_V
							, ot
							, name
							, vd
							, ss
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.firstDirectives()) {
					Directives d = this.parseDirectives();
					if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return new OperationDefinition(OperationDefinitionEnum.OT_D
							, ot
							, name
							, d
							, ss
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return new OperationDefinition(OperationDefinitionEnum.OT
						, ot
						, name
						, ss
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an VariableDefinitions, Directives, or SelectionSet. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an SelectionSet, or OperationType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSelectionSet() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lcurly;
	}

	SelectionSet parseSelectionSet() {
		try {
			return this.parseSelectionSetImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a SelectionSet an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	SelectionSet parseSelectionSetImpl() {
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.firstSelections()) {
				Selections sel = this.parseSelections();
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return new SelectionSet(SelectionSetEnum.SS
						, sel
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an Selections. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lcurly. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationType() const pure @nogc @safe {
		return this.lex.front.type == TokenType.query
			 || this.lex.front.type == TokenType.mutation
			 || this.lex.front.type == TokenType.subscription;
	}

	OperationType parseOperationType() {
		try {
			return this.parseOperationTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	OperationType parseOperationTypeImpl() {
		if(this.lex.front.type == TokenType.query) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new OperationType(OperationTypeEnum.Query
				, tok
			);
		} else if(this.lex.front.type == TokenType.mutation) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new OperationType(OperationTypeEnum.Mutation
				, tok
			);
		} else if(this.lex.front.type == TokenType.subscription) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new OperationType(OperationTypeEnum.Sub
				, tok
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an query, mutation, or subscription. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSelections() const pure @nogc @safe {
		return this.firstSelection();
	}

	Selections parseSelections() {
		try {
			return this.parseSelectionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Selections an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Selections parseSelectionsImpl() {
		if(this.firstSelection()) {
			Selection sel = this.parseSelection();
			if(this.firstSelections()) {
				Selections follow = this.parseSelections();

				return new Selections(SelectionsEnum.Sels
					, sel
					, follow
				);
			} else if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstSelections()) {
					Selections follow = this.parseSelections();

					return new Selections(SelectionsEnum.Selsc
						, sel
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Selections. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			return new Selections(SelectionsEnum.Sel
				, sel
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Selection. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSelection() const pure @nogc @safe {
		return this.firstField()
			 || this.lex.front.type == TokenType.dots;
	}

	Selection parseSelection() {
		try {
			return this.parseSelectionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Selection an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Selection parseSelectionImpl() {
		if(this.firstField()) {
			Field field = this.parseField();

			return new Selection(SelectionEnum.Field
				, field
			);
		} else if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			if(this.firstFragmentSpread()) {
				FragmentSpread frag = this.parseFragmentSpread();

				return new Selection(SelectionEnum.Spread
					, frag
				);
			} else if(this.firstInlineFragment()) {
				InlineFragment ifrag = this.parseInlineFragment();

				return new Selection(SelectionEnum.IFrag
					, ifrag
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an FragmentSpread, or InlineFragment. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Field, or dots. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFragmentSpread() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	FragmentSpread parseFragmentSpread() {
		try {
			return this.parseFragmentSpreadImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FragmentSpread an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	FragmentSpread parseFragmentSpreadImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.firstDirectives()) {
				Directives dirs = this.parseDirectives();

				return new FragmentSpread(FragmentSpreadEnum.FD
					, name
					, dirs
				);
			}
			return new FragmentSpread(FragmentSpreadEnum.F
				, name
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInlineFragment() const pure @nogc @safe {
		return this.lex.front.type == TokenType.on_
			 || this.firstDirectives()
			 || this.firstSelectionSet();
	}

	InlineFragment parseInlineFragment() {
		try {
			return this.parseInlineFragmentImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InlineFragment an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	InlineFragment parseInlineFragmentImpl() {
		if(this.lex.front.type == TokenType.on_) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token tc = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return new InlineFragment(InlineFragmentEnum.TDS
							, tc
							, dirs
							, ss
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return new InlineFragment(InlineFragmentEnum.TS
						, tc
						, ss
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		} else if(this.firstDirectives()) {
			Directives dirs = this.parseDirectives();
			if(this.firstSelectionSet()) {
				SelectionSet ss = this.parseSelectionSet();

				return new InlineFragment(InlineFragmentEnum.DS
					, dirs
					, ss
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		} else if(this.firstSelectionSet()) {
			SelectionSet ss = this.parseSelectionSet();

			return new InlineFragment(InlineFragmentEnum.S
				, ss
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an on_, Directives, or SelectionSet. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstField() const pure @nogc @safe {
		return this.firstFieldName();
	}

	Field parseField() {
		try {
			return this.parseFieldImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Field an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Field parseFieldImpl() {
		if(this.firstFieldName()) {
			FieldName name = this.parseFieldName();
			if(this.firstArguments()) {
				Arguments args = this.parseArguments();
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return new Field(FieldEnum.FADS
							, name
							, args
							, dirs
							, ss
						);
					}
					return new Field(FieldEnum.FAD
						, name
						, args
						, dirs
					);
				} else if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return new Field(FieldEnum.FAS
						, name
						, args
						, ss
					);
				}
				return new Field(FieldEnum.FA
					, name
					, args
				);
			} else if(this.firstDirectives()) {
				Directives dirs = this.parseDirectives();
				if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return new Field(FieldEnum.FDS
						, name
						, dirs
						, ss
					);
				}
				return new Field(FieldEnum.FD
					, name
					, dirs
				);
			} else if(this.firstSelectionSet()) {
				SelectionSet ss = this.parseSelectionSet();

				return new Field(FieldEnum.FS
					, name
					, ss
				);
			}
			return new Field(FieldEnum.F
				, name
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an FieldName. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFieldName() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name
			 || this.lex.front.type == TokenType.type
			 || this.lex.front.type == TokenType.schema__;
	}

	FieldName parseFieldName() {
		try {
			return this.parseFieldNameImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FieldName an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	FieldName parseFieldNameImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.lex.front.type == TokenType.name) {
					Token aka = this.lex.front;
					this.lex.popFront();

					return new FieldName(FieldNameEnum.A
						, name
						, aka
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an name. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			return new FieldName(FieldNameEnum.N
				, name
			);
		} else if(this.lex.front.type == TokenType.type) {
			Token type = this.lex.front;
			this.lex.popFront();

			return new FieldName(FieldNameEnum.T
				, type
			);
		} else if(this.lex.front.type == TokenType.schema__) {
			Token schema = this.lex.front;
			this.lex.popFront();

			return new FieldName(FieldNameEnum.S
				, schema
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name, type, or schema__. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArguments() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lparen;
	}

	Arguments parseArguments() {
		try {
			return this.parseArgumentsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Arguments an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Arguments parseArgumentsImpl() {
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			if(this.firstArgumentList()) {
				ArgumentList arg = this.parseArgumentList();
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return new Arguments(ArgumentsEnum.List
						, arg
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rparen. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				return new Arguments(ArgumentsEnum.Empty
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an ArgumentList, or rparen. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lparen. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArgumentList() const pure @nogc @safe {
		return this.firstArgument();
	}

	ArgumentList parseArgumentList() {
		try {
			return this.parseArgumentListImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ArgumentList an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ArgumentList parseArgumentListImpl() {
		if(this.firstArgument()) {
			Argument arg = this.parseArgument();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstArgumentList()) {
					ArgumentList follow = this.parseArgumentList();

					return new ArgumentList(ArgumentListEnum.ACS
						, arg
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an ArgumentList. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstArgumentList()) {
				ArgumentList follow = this.parseArgumentList();

				return new ArgumentList(ArgumentListEnum.AS
					, arg
					, follow
				);
			}
			return new ArgumentList(ArgumentListEnum.A
				, arg
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Argument. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArgument() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	Argument parseArgument() {
		try {
			return this.parseArgumentImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Argument an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Argument parseArgumentImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstValueOrVariable()) {
					ValueOrVariable vv = this.parseValueOrVariable();

					return new Argument(ArgumentEnum.Name
						, name
						, vv
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an ValueOrVariable. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFragmentDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.fragment;
	}

	FragmentDefinition parseFragmentDefinition() {
		try {
			return this.parseFragmentDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FragmentDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	FragmentDefinition parseFragmentDefinitionImpl() {
		if(this.lex.front.type == TokenType.fragment) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.lex.front.type == TokenType.on_) {
					this.lex.popFront();
					if(this.lex.front.type == TokenType.name) {
						Token tc = this.lex.front;
						this.lex.popFront();
						if(this.firstDirectives()) {
							Directives dirs = this.parseDirectives();
							if(this.firstSelectionSet()) {
								SelectionSet ss = this.parseSelectionSet();

								return new FragmentDefinition(FragmentDefinitionEnum.FTDS
									, name
									, tc
									, dirs
									, ss
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						} else if(this.firstSelectionSet()) {
							SelectionSet ss = this.parseSelectionSet();

							return new FragmentDefinition(FragmentDefinitionEnum.FTS
								, name
								, tc
								, ss
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an name. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an on_. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an fragment. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirectives() const pure @nogc @safe {
		return this.firstDirective();
	}

	Directives parseDirectives() {
		try {
			return this.parseDirectivesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Directives an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Directives parseDirectivesImpl() {
		if(this.firstDirective()) {
			Directive dir = this.parseDirective();
			if(this.firstDirectives()) {
				Directives follow = this.parseDirectives();

				return new Directives(DirectivesEnum.Dirs
					, dir
					, follow
				);
			}
			return new Directives(DirectivesEnum.Dir
				, dir
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Directive. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirective() const pure @nogc @safe {
		return this.lex.front.type == TokenType.at;
	}

	Directive parseDirective() {
		try {
			return this.parseDirectiveImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Directive an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Directive parseDirectiveImpl() {
		if(this.lex.front.type == TokenType.at) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstArguments()) {
					Arguments arg = this.parseArguments();

					return new Directive(DirectiveEnum.NArg
						, name
						, arg
					);
				}
				return new Directive(DirectiveEnum.N
					, name
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an at. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariableDefinitions() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lparen;
	}

	VariableDefinitions parseVariableDefinitions() {
		try {
			return this.parseVariableDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a VariableDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	VariableDefinitions parseVariableDefinitionsImpl() {
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				return new VariableDefinitions(VariableDefinitionsEnum.Empty
				);
			} else if(this.firstVariableDefinitionList()) {
				VariableDefinitionList vars = this.parseVariableDefinitionList();
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return new VariableDefinitions(VariableDefinitionsEnum.Vars
						, vars
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rparen. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an rparen, or VariableDefinitionList. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lparen. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariableDefinitionList() const pure @nogc @safe {
		return this.firstVariableDefinition();
	}

	VariableDefinitionList parseVariableDefinitionList() {
		try {
			return this.parseVariableDefinitionListImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a VariableDefinitionList an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	VariableDefinitionList parseVariableDefinitionListImpl() {
		if(this.firstVariableDefinition()) {
			VariableDefinition var = this.parseVariableDefinition();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstVariableDefinitionList()) {
					VariableDefinitionList follow = this.parseVariableDefinitionList();

					return new VariableDefinitionList(VariableDefinitionListEnum.VCF
						, var
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an VariableDefinitionList. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstVariableDefinitionList()) {
				VariableDefinitionList follow = this.parseVariableDefinitionList();

				return new VariableDefinitionList(VariableDefinitionListEnum.VF
					, var
					, follow
				);
			}
			return new VariableDefinitionList(VariableDefinitionListEnum.V
				, var
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an VariableDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariableDefinition() const pure @nogc @safe {
		return this.firstVariable();
	}

	VariableDefinition parseVariableDefinition() {
		try {
			return this.parseVariableDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a VariableDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	VariableDefinition parseVariableDefinitionImpl() {
		if(this.firstVariable()) {
			this.parseVariable();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstType()) {
					Type type = this.parseType();
					if(this.firstDefaultValue()) {
						DefaultValue dvalue = this.parseDefaultValue();

						return new VariableDefinition(VariableDefinitionEnum.VarD
							, type
							, dvalue
						);
					}
					return new VariableDefinition(VariableDefinitionEnum.Var
						, type
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Type. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Variable. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariable() const pure @nogc @safe {
		return this.lex.front.type == TokenType.dollar;
	}

	Variable parseVariable() {
		try {
			return this.parseVariableImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Variable an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Variable parseVariableImpl() {
		if(this.lex.front.type == TokenType.dollar) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();

				return new Variable(VariableEnum.Var
					, name
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an dollar. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDefaultValue() const pure @nogc @safe {
		return this.lex.front.type == TokenType.equal;
	}

	DefaultValue parseDefaultValue() {
		try {
			return this.parseDefaultValueImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a DefaultValue an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	DefaultValue parseDefaultValueImpl() {
		if(this.lex.front.type == TokenType.equal) {
			this.lex.popFront();
			if(this.firstValue()) {
				Value value = this.parseValue();

				return new DefaultValue(DefaultValueEnum.DV
					, value
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an Value. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an equal. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstValueOrVariable() const pure @nogc @safe {
		return this.firstValue()
			 || this.firstVariable();
	}

	ValueOrVariable parseValueOrVariable() {
		try {
			return this.parseValueOrVariableImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ValueOrVariable an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ValueOrVariable parseValueOrVariableImpl() {
		if(this.firstValue()) {
			Value val = this.parseValue();

			return new ValueOrVariable(ValueOrVariableEnum.Val
				, val
			);
		} else if(this.firstVariable()) {
			Variable var = this.parseVariable();

			return new ValueOrVariable(ValueOrVariableEnum.Var
				, var
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Value, or Variable. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstValue() const pure @nogc @safe {
		return this.lex.front.type == TokenType.stringValue
			 || this.lex.front.type == TokenType.intValue
			 || this.lex.front.type == TokenType.floatValue
			 || this.lex.front.type == TokenType.true_
			 || this.lex.front.type == TokenType.false_
			 || this.firstArray()
			 || this.firstObjectType();
	}

	Value parseValue() {
		try {
			return this.parseValueImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Value an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Value parseValueImpl() {
		if(this.lex.front.type == TokenType.stringValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new Value(ValueEnum.STR
				, tok
			);
		} else if(this.lex.front.type == TokenType.intValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new Value(ValueEnum.INT
				, tok
			);
		} else if(this.lex.front.type == TokenType.floatValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new Value(ValueEnum.FLOAT
				, tok
			);
		} else if(this.lex.front.type == TokenType.true_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new Value(ValueEnum.T
				, tok
			);
		} else if(this.lex.front.type == TokenType.false_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return new Value(ValueEnum.F
				, tok
			);
		} else if(this.firstArray()) {
			Array arr = this.parseArray();

			return new Value(ValueEnum.ARR
				, arr
			);
		} else if(this.firstObjectType()) {
			ObjectType obj = this.parseObjectType();

			return new Value(ValueEnum.O
				, obj
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an stringValue, intValue, floatValue, true_, false_, Array, or ObjectType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstType() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name
			 || this.firstListType();
	}

	Type parseType() {
		try {
			return this.parseTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Type an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Type parseTypeImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token tname = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();

				return new Type(TypeEnum.TN
					, tname
				);
			}
			return new Type(TypeEnum.T
				, tname
			);
		} else if(this.firstListType()) {
			ListType list = this.parseListType();
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();

				return new Type(TypeEnum.LN
					, list
				);
			}
			return new Type(TypeEnum.L
				, list
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name, or ListType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstListType() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lbrack;
	}

	ListType parseListType() {
		try {
			return this.parseListTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ListType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ListType parseListTypeImpl() {
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			if(this.firstType()) {
				Type type = this.parseType();
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					return new ListType(ListTypeEnum.T
						, type
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rbrack. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an Type. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lbrack. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstValues() const pure @nogc @safe {
		return this.firstValue();
	}

	Values parseValues() {
		try {
			return this.parseValuesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Values an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Values parseValuesImpl() {
		if(this.firstValue()) {
			Value val = this.parseValue();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstValues()) {
					Values follow = this.parseValues();

					return new Values(ValuesEnum.Vals
						, val
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Values. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			return new Values(ValuesEnum.Val
				, val
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an Value. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArray() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lbrack;
	}

	Array parseArray() {
		try {
			return this.parseArrayImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Array an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Array parseArrayImpl() {
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.rbrack) {
				this.lex.popFront();

				return new Array(ArrayEnum.Empty
				);
			} else if(this.firstValues()) {
				Values vals = this.parseValues();
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					return new Array(ArrayEnum.Value
						, vals
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rbrack. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an rbrack, or Values. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lbrack. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectValues() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	ObjectValues parseObjectValues() {
		try {
			return this.parseObjectValuesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectValues an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ObjectValues parseObjectValuesImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstValue()) {
					Value val = this.parseValue();
					if(this.lex.front.type == TokenType.comma) {
						this.lex.popFront();
						if(this.firstObjectValues()) {
							ObjectValues follow = this.parseObjectValues();

							return new ObjectValues(ObjectValuesEnum.Vsc
								, name
								, val
								, follow
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an ObjectValues. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.firstObjectValues()) {
						ObjectValues follow = this.parseObjectValues();

						return new ObjectValues(ObjectValuesEnum.Vs
							, name
							, val
							, follow
						);
					}
					return new ObjectValues(ObjectValuesEnum.V
						, name
						, val
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Value. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectValue() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	ObjectValue parseObjectValue() {
		try {
			return this.parseObjectValueImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectValue an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ObjectValue parseObjectValueImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstValue()) {
					Value val = this.parseValue();

					return new ObjectValue(ObjectValueEnum.V
						, name
						, val
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Value. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectType() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lcurly;
	}

	ObjectType parseObjectType() {
		try {
			return this.parseObjectTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ObjectType parseObjectTypeImpl() {
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.firstObjectValues()) {
				ObjectValues vals = this.parseObjectValues();
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return new ObjectType(ObjectTypeEnum.Var
						, vals
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an ObjectValues. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lcurly. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstTypeSystemDefinition() const pure @nogc @safe {
		return this.firstSchemaDefinition()
			 || this.firstTypeDefinition()
			 || this.firstTypeExtensionDefinition()
			 || this.firstDirectiveDefinition();
	}

	TypeSystemDefinition parseTypeSystemDefinition() {
		try {
			return this.parseTypeSystemDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TypeSystemDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	TypeSystemDefinition parseTypeSystemDefinitionImpl() {
		if(this.firstSchemaDefinition()) {
			SchemaDefinition sch = this.parseSchemaDefinition();

			return new TypeSystemDefinition(TypeSystemDefinitionEnum.S
				, sch
			);
		} else if(this.firstTypeDefinition()) {
			TypeDefinition td = this.parseTypeDefinition();

			return new TypeSystemDefinition(TypeSystemDefinitionEnum.T
				, td
			);
		} else if(this.firstTypeExtensionDefinition()) {
			TypeExtensionDefinition ted = this.parseTypeExtensionDefinition();

			return new TypeSystemDefinition(TypeSystemDefinitionEnum.TE
				, ted
			);
		} else if(this.firstDirectiveDefinition()) {
			DirectiveDefinition dd = this.parseDirectiveDefinition();

			return new TypeSystemDefinition(TypeSystemDefinitionEnum.D
				, dd
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an SchemaDefinition, TypeDefinition, TypeExtensionDefinition, or DirectiveDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstTypeDefinition() const pure @nogc @safe {
		return this.firstScalarTypeDefinition()
			 || this.firstObjectTypeDefinition()
			 || this.firstInterfaceTypeDefinition()
			 || this.firstUnionTypeDefinition()
			 || this.firstEnumTypeDefinition()
			 || this.firstInputObjectTypeDefinition();
	}

	TypeDefinition parseTypeDefinition() {
		try {
			return this.parseTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	TypeDefinition parseTypeDefinitionImpl() {
		if(this.firstScalarTypeDefinition()) {
			ScalarTypeDefinition std = this.parseScalarTypeDefinition();

			return new TypeDefinition(TypeDefinitionEnum.S
				, std
			);
		} else if(this.firstObjectTypeDefinition()) {
			ObjectTypeDefinition otd = this.parseObjectTypeDefinition();

			return new TypeDefinition(TypeDefinitionEnum.O
				, otd
			);
		} else if(this.firstInterfaceTypeDefinition()) {
			InterfaceTypeDefinition itd = this.parseInterfaceTypeDefinition();

			return new TypeDefinition(TypeDefinitionEnum.I
				, itd
			);
		} else if(this.firstUnionTypeDefinition()) {
			UnionTypeDefinition utd = this.parseUnionTypeDefinition();

			return new TypeDefinition(TypeDefinitionEnum.U
				, utd
			);
		} else if(this.firstEnumTypeDefinition()) {
			EnumTypeDefinition etd = this.parseEnumTypeDefinition();

			return new TypeDefinition(TypeDefinitionEnum.E
				, etd
			);
		} else if(this.firstInputObjectTypeDefinition()) {
			InputObjectTypeDefinition iod = this.parseInputObjectTypeDefinition();

			return new TypeDefinition(TypeDefinitionEnum.IO
				, iod
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an ScalarTypeDefinition, ObjectTypeDefinition, InterfaceTypeDefinition, UnionTypeDefinition, EnumTypeDefinition, or InputObjectTypeDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSchemaDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.schema;
	}

	SchemaDefinition parseSchemaDefinition() {
		try {
			return this.parseSchemaDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a SchemaDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	SchemaDefinition parseSchemaDefinitionImpl() {
		if(this.lex.front.type == TokenType.schema) {
			this.lex.popFront();
			if(this.firstDirectives()) {
				Directives dir = this.parseDirectives();
				if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstOperationTypeDefinitions()) {
						OperationTypeDefinitions otds = this.parseOperationTypeDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new SchemaDefinition(SchemaDefinitionEnum.DO
								, dir
								, otds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an rcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an OperationTypeDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an lcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.lex.front.type == TokenType.lcurly) {
				this.lex.popFront();
				if(this.firstOperationTypeDefinitions()) {
					OperationTypeDefinitions otds = this.parseOperationTypeDefinitions();
					if(this.lex.front.type == TokenType.rcurly) {
						this.lex.popFront();

						return new SchemaDefinition(SchemaDefinitionEnum.O
							, otds
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an rcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an OperationTypeDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an schema. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationTypeDefinitions() const pure @nogc @safe {
		return this.firstOperationTypeDefinition();
	}

	OperationTypeDefinitions parseOperationTypeDefinitions() {
		try {
			return this.parseOperationTypeDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationTypeDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	OperationTypeDefinitions parseOperationTypeDefinitionsImpl() {
		if(this.firstOperationTypeDefinition()) {
			OperationTypeDefinition otd = this.parseOperationTypeDefinition();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstOperationTypeDefinitions()) {
					OperationTypeDefinitions follow = this.parseOperationTypeDefinitions();

					return new OperationTypeDefinitions(OperationTypeDefinitionsEnum.OCS
						, otd
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an OperationTypeDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstOperationTypeDefinitions()) {
				OperationTypeDefinitions follow = this.parseOperationTypeDefinitions();

				return new OperationTypeDefinitions(OperationTypeDefinitionsEnum.OS
					, otd
					, follow
				);
			}
			return new OperationTypeDefinitions(OperationTypeDefinitionsEnum.O
				, otd
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an OperationTypeDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationTypeDefinition() const pure @nogc @safe {
		return this.firstOperationType();
	}

	OperationTypeDefinition parseOperationTypeDefinition() {
		try {
			return this.parseOperationTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	OperationTypeDefinition parseOperationTypeDefinitionImpl() {
		if(this.firstOperationType()) {
			OperationType ot = this.parseOperationType();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.lex.front.type == TokenType.name) {
					Token nt = this.lex.front;
					this.lex.popFront();

					return new OperationTypeDefinition(OperationTypeDefinitionEnum.O
						, ot
						, nt
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an name. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an OperationType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstScalarTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.scalar;
	}

	ScalarTypeDefinition parseScalarTypeDefinition() {
		try {
			return this.parseScalarTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ScalarTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ScalarTypeDefinition parseScalarTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.scalar) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();

					return new ScalarTypeDefinition(ScalarTypeDefinitionEnum.D
						, name
						, dir
					);
				}
				return new ScalarTypeDefinition(ScalarTypeDefinitionEnum.S
					, name
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an scalar. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.type;
	}

	ObjectTypeDefinition parseObjectTypeDefinition() {
		try {
			return this.parseObjectTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ObjectTypeDefinition parseObjectTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.type) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstImplementsInterfaces()) {
					ImplementsInterfaces ii = this.parseImplementsInterfaces();
					if(this.firstDirectives()) {
						Directives dir = this.parseDirectives();
						if(this.lex.front.type == TokenType.lcurly) {
							this.lex.popFront();
							if(this.firstFieldDefinitions()) {
								FieldDefinitions fds = this.parseFieldDefinitions();
								if(this.lex.front.type == TokenType.rcurly) {
									this.lex.popFront();

									return new ObjectTypeDefinition(ObjectTypeDefinitionEnum.ID
										, name
										, ii
										, dir
										, fds
									);
								}
								auto app = appender!string();
								formattedWrite(app, 
									"Was expecting an rcurly. Found a '%s' at %s:%s.", 
									this.lex.front, this.lex.line, this.lex.column
								);
								throw new ParseException(app.data,
									__FILE__, __LINE__
								);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an lcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new ObjectTypeDefinition(ObjectTypeDefinitionEnum.I
									, name
									, ii
									, fds
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an rcurly. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new ObjectTypeDefinition(ObjectTypeDefinitionEnum.D
									, name
									, dir
									, fds
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an rcurly. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstFieldDefinitions()) {
						FieldDefinitions fds = this.parseFieldDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new ObjectTypeDefinition(ObjectTypeDefinitionEnum.F
								, name
								, fds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an rcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an ImplementsInterfaces, Directives, or lcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an type. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFieldDefinitions() const pure @nogc @safe {
		return this.firstFieldDefinition();
	}

	FieldDefinitions parseFieldDefinitions() {
		try {
			return this.parseFieldDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FieldDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	FieldDefinitions parseFieldDefinitionsImpl() {
		if(this.firstFieldDefinition()) {
			FieldDefinition fd = this.parseFieldDefinition();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstFieldDefinitions()) {
					FieldDefinitions follow = this.parseFieldDefinitions();

					return new FieldDefinitions(FieldDefinitionsEnum.FC
						, fd
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstFieldDefinitions()) {
				FieldDefinitions follow = this.parseFieldDefinitions();

				return new FieldDefinitions(FieldDefinitionsEnum.FNC
					, fd
					, follow
				);
			}
			return new FieldDefinitions(FieldDefinitionsEnum.F
				, fd
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an FieldDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFieldDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	FieldDefinition parseFieldDefinition() {
		try {
			return this.parseFieldDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FieldDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	FieldDefinition parseFieldDefinitionImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.firstArgumentsDefinition()) {
				ArgumentsDefinition arg = this.parseArgumentsDefinition();
				if(this.lex.front.type == TokenType.colon) {
					this.lex.popFront();
					if(this.firstType()) {
						Type typ = this.parseType();
						if(this.firstDirectives()) {
							Directives dir = this.parseDirectives();

							return new FieldDefinition(FieldDefinitionEnum.AD
								, name
								, arg
								, typ
								, dir
							);
						}
						return new FieldDefinition(FieldDefinitionEnum.A
							, name
							, arg
							, typ
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an Type. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an colon. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstType()) {
					Type typ = this.parseType();
					if(this.firstDirectives()) {
						Directives dir = this.parseDirectives();

						return new FieldDefinition(FieldDefinitionEnum.D
							, name
							, typ
							, dir
						);
					}
					return new FieldDefinition(FieldDefinitionEnum.T
						, name
						, typ
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Type. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an ArgumentsDefinition, or colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstImplementsInterfaces() const pure @nogc @safe {
		return this.lex.front.type == TokenType.implements;
	}

	ImplementsInterfaces parseImplementsInterfaces() {
		try {
			return this.parseImplementsInterfacesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ImplementsInterfaces an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ImplementsInterfaces parseImplementsInterfacesImpl() {
		if(this.lex.front.type == TokenType.implements) {
			this.lex.popFront();
			if(this.firstNamedTypes()) {
				NamedTypes nts = this.parseNamedTypes();

				return new ImplementsInterfaces(ImplementsInterfacesEnum.N
					, nts
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an NamedTypes. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an implements. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstNamedTypes() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	NamedTypes parseNamedTypes() {
		try {
			return this.parseNamedTypesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a NamedTypes an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	NamedTypes parseNamedTypesImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstNamedTypes()) {
					NamedTypes follow = this.parseNamedTypes();

					return new NamedTypes(NamedTypesEnum.NCS
						, name
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an NamedTypes. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstNamedTypes()) {
				NamedTypes follow = this.parseNamedTypes();

				return new NamedTypes(NamedTypesEnum.NS
					, name
					, follow
				);
			}
			return new NamedTypes(NamedTypesEnum.N
				, name
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArgumentsDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lparen;
	}

	ArgumentsDefinition parseArgumentsDefinition() {
		try {
			return this.parseArgumentsDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ArgumentsDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	ArgumentsDefinition parseArgumentsDefinitionImpl() {
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			if(this.firstInputValueDefinitions()) {
				this.parseInputValueDefinitions();
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return new ArgumentsDefinition(ArgumentsDefinitionEnum.A
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an rparen. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an lparen. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInputValueDefinitions() const pure @nogc @safe {
		return this.firstInputValueDefinition();
	}

	InputValueDefinitions parseInputValueDefinitions() {
		try {
			return this.parseInputValueDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputValueDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	InputValueDefinitions parseInputValueDefinitionsImpl() {
		if(this.firstInputValueDefinition()) {
			InputValueDefinition iv = this.parseInputValueDefinition();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstInputValueDefinitions()) {
					InputValueDefinitions follow = this.parseInputValueDefinitions();

					return new InputValueDefinitions(InputValueDefinitionsEnum.ICF
						, iv
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstInputValueDefinitions()) {
				InputValueDefinitions follow = this.parseInputValueDefinitions();

				return new InputValueDefinitions(InputValueDefinitionsEnum.IF
					, iv
					, follow
				);
			}
			return new InputValueDefinitions(InputValueDefinitionsEnum.I
				, iv
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an InputValueDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInputValueDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	InputValueDefinition parseInputValueDefinition() {
		try {
			return this.parseInputValueDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputValueDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	InputValueDefinition parseInputValueDefinitionImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstType()) {
					Type type = this.parseType();
					if(this.firstDefaultValue()) {
						DefaultValue df = this.parseDefaultValue();
						if(this.firstDirectives()) {
							Directives dirs = this.parseDirectives();

							return new InputValueDefinition(InputValueDefinitionEnum.TVD
								, name
								, type
								, df
								, dirs
							);
						}
						return new InputValueDefinition(InputValueDefinitionEnum.TV
							, name
							, type
							, df
						);
					} else if(this.firstDirectives()) {
						Directives dirs = this.parseDirectives();

						return new InputValueDefinition(InputValueDefinitionEnum.TD
							, name
							, type
							, dirs
						);
					}
					return new InputValueDefinition(InputValueDefinitionEnum.T
						, name
						, type
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Type. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInterfaceTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.interface_;
	}

	InterfaceTypeDefinition parseInterfaceTypeDefinition() {
		try {
			return this.parseInterfaceTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InterfaceTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	InterfaceTypeDefinition parseInterfaceTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.interface_) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new InterfaceTypeDefinition(InterfaceTypeDefinitionEnum.NDF
									, name
									, dirs
									, fds
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an rcurly. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstFieldDefinitions()) {
						FieldDefinitions fds = this.parseFieldDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new InterfaceTypeDefinition(InterfaceTypeDefinitionEnum.NF
								, name
								, fds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an rcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an interface_. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstUnionTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.union_;
	}

	UnionTypeDefinition parseUnionTypeDefinition() {
		try {
			return this.parseUnionTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a UnionTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	UnionTypeDefinition parseUnionTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.union_) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					if(this.lex.front.type == TokenType.equal) {
						this.lex.popFront();
						if(this.firstUnionMembers()) {
							UnionMembers um = this.parseUnionMembers();

							return new UnionTypeDefinition(UnionTypeDefinitionEnum.NDU
								, name
								, dirs
								, um
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an UnionMembers. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an equal. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.equal) {
					this.lex.popFront();
					if(this.firstUnionMembers()) {
						UnionMembers um = this.parseUnionMembers();

						return new UnionTypeDefinition(UnionTypeDefinitionEnum.NU
							, name
							, um
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an UnionMembers. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Directives, or equal. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an union_. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstUnionMembers() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	UnionMembers parseUnionMembers() {
		try {
			return this.parseUnionMembersImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a UnionMembers an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	UnionMembers parseUnionMembersImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.pipe) {
				this.lex.popFront();
				if(this.firstUnionMembers()) {
					UnionMembers follow = this.parseUnionMembers();

					return new UnionMembers(UnionMembersEnum.SPF
						, name
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an UnionMembers. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstUnionMembers()) {
				UnionMembers follow = this.parseUnionMembers();

				return new UnionMembers(UnionMembersEnum.SF
					, name
					, follow
				);
			}
			return new UnionMembers(UnionMembersEnum.S
				, name
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstEnumTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.enum_;
	}

	EnumTypeDefinition parseEnumTypeDefinition() {
		try {
			return this.parseEnumTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a EnumTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	EnumTypeDefinition parseEnumTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.enum_) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstEnumValueDefinitions()) {
							EnumValueDefinitions evds = this.parseEnumValueDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new EnumTypeDefinition(EnumTypeDefinitionEnum.NDE
									, name
									, dir
									, evds
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an rcurly. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an EnumValueDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstEnumValueDefinitions()) {
						EnumValueDefinitions evds = this.parseEnumValueDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new EnumTypeDefinition(EnumTypeDefinitionEnum.NE
								, name
								, evds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an rcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an EnumValueDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an enum_. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstEnumValueDefinitions() const pure @nogc @safe {
		return this.firstEnumValueDefinition();
	}

	EnumValueDefinitions parseEnumValueDefinitions() {
		try {
			return this.parseEnumValueDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a EnumValueDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	EnumValueDefinitions parseEnumValueDefinitionsImpl() {
		if(this.firstEnumValueDefinition()) {
			EnumValueDefinition evd = this.parseEnumValueDefinition();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstEnumValueDefinitions()) {
					EnumValueDefinitions follow = this.parseEnumValueDefinitions();

					return new EnumValueDefinitions(EnumValueDefinitionsEnum.DCE
						, evd
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an EnumValueDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstEnumValueDefinitions()) {
				EnumValueDefinitions follow = this.parseEnumValueDefinitions();

				return new EnumValueDefinitions(EnumValueDefinitionsEnum.DE
					, evd
					, follow
				);
			}
			return new EnumValueDefinitions(EnumValueDefinitionsEnum.D
				, evd
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an EnumValueDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstEnumValueDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	EnumValueDefinition parseEnumValueDefinition() {
		try {
			return this.parseEnumValueDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a EnumValueDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	EnumValueDefinition parseEnumValueDefinitionImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.firstDirectives()) {
				Directives dirs = this.parseDirectives();

				return new EnumValueDefinition(EnumValueDefinitionEnum.ED
					, name
					, dirs
				);
			}
			return new EnumValueDefinition(EnumValueDefinitionEnum.E
				, name
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInputTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.input;
	}

	InputTypeDefinition parseInputTypeDefinition() {
		try {
			return this.parseInputTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	InputTypeDefinition parseInputTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.input) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstInputValueDefinitions()) {
							InputValueDefinitions ivds = this.parseInputValueDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new InputTypeDefinition(InputTypeDefinitionEnum.NDE
									, name
									, dir
									, ivds
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an rcurly. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstInputValueDefinitions()) {
						InputValueDefinitions ivds = this.parseInputValueDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new InputTypeDefinition(InputTypeDefinitionEnum.NE
								, name
								, ivds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an rcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an input. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstTypeExtensionDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.extend;
	}

	TypeExtensionDefinition parseTypeExtensionDefinition() {
		try {
			return this.parseTypeExtensionDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TypeExtensionDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	TypeExtensionDefinition parseTypeExtensionDefinitionImpl() {
		if(this.lex.front.type == TokenType.extend) {
			this.lex.popFront();
			if(this.firstObjectTypeDefinition()) {
				ObjectTypeDefinition otd = this.parseObjectTypeDefinition();

				return new TypeExtensionDefinition(TypeExtensionDefinitionEnum.O
					, otd
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an ObjectTypeDefinition. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an extend. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirectiveDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.directive;
	}

	DirectiveDefinition parseDirectiveDefinition() {
		try {
			return this.parseDirectiveDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a DirectiveDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	DirectiveDefinition parseDirectiveDefinitionImpl() {
		if(this.lex.front.type == TokenType.directive) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.at) {
				this.lex.popFront();
				if(this.lex.front.type == TokenType.name) {
					Token name = this.lex.front;
					this.lex.popFront();
					if(this.firstArgumentsDefinition()) {
						ArgumentsDefinition ad = this.parseArgumentsDefinition();
						if(this.lex.front.type == TokenType.on_) {
							this.lex.popFront();
							if(this.firstDirectiveLocations()) {
								DirectiveLocations dl = this.parseDirectiveLocations();

								return new DirectiveDefinition(DirectiveDefinitionEnum.AD
									, name
									, ad
									, dl
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an DirectiveLocations. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an on_. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.lex.front.type == TokenType.on_) {
						this.lex.popFront();
						if(this.firstDirectiveLocations()) {
							DirectiveLocations dl = this.parseDirectiveLocations();

							return new DirectiveDefinition(DirectiveDefinitionEnum.D
								, name
								, dl
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an DirectiveLocations. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an ArgumentsDefinition, or on_. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an name. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an at. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an directive. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirectiveLocations() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	DirectiveLocations parseDirectiveLocations() {
		try {
			return this.parseDirectiveLocationsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a DirectiveLocations an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	DirectiveLocations parseDirectiveLocationsImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.pipe) {
				this.lex.popFront();
				if(this.firstDirectiveLocations()) {
					DirectiveLocations follow = this.parseDirectiveLocations();

					return new DirectiveLocations(DirectiveLocationsEnum.NPF
						, name
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an DirectiveLocations. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstDirectiveLocations()) {
				DirectiveLocations follow = this.parseDirectiveLocations();

				return new DirectiveLocations(DirectiveLocationsEnum.NF
					, name
					, follow
				);
			}
			return new DirectiveLocations(DirectiveLocationsEnum.N
				, name
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInputObjectTypeDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.input;
	}

	InputObjectTypeDefinition parseInputObjectTypeDefinition() {
		try {
			return this.parseInputObjectTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputObjectTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	InputObjectTypeDefinition parseInputObjectTypeDefinitionImpl() {
		if(this.lex.front.type == TokenType.input) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstInputValueDefinitions()) {
							this.parseInputValueDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new InputObjectTypeDefinition(InputObjectTypeDefinitionEnum.NDI
									, name
									, dirs
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Was expecting an rcurly. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstInputValueDefinitions()) {
						this.parseInputValueDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new InputObjectTypeDefinition(InputObjectTypeDefinitionEnum.NI
								, name
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Was expecting an rcurly. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Was expecting an input. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__
		);

	}

}
