module parser;

import std.typecons : RefCounted, refCounted;
import std.experimental.allocator;

import std.format : format;
import ast;
import tokenmodule;

import lexer;

import exception;

struct Parser {
	import vibe.utils.array : AllocAppender;

	import std.format : formattedWrite;

	Lexer lex;

	IAllocator alloc;

	this(Lexer lex, IAllocator alloc) {
		this.lex = lex;
		this.alloc = alloc;
	}

	bool firstDocument() const {
		return this.lex.front.type == TokenType.lcurly;
	}

	Document parseDocument() {
		try {
			return this.parseDocumentImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Document an Exception was thrown.", e);
		}
	}

	Document parseDocumentImpl() {
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.firstDefinitions()) {
				Definitions defs = this.parseDefinitions();
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return this.alloc.make!Document(DocumentEnum.Defi
						, defs
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an Definitions. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lcurly. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDefinitions() const {
		return this.firstDefinition();
	}

	Definitions parseDefinitions() {
		try {
			return this.parseDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Definitions an Exception was thrown.", e);
		}
	}

	Definitions parseDefinitionsImpl() {
		if(this.firstDefinition()) {
			Definition def = this.parseDefinition();
			if(this.firstDefinitions()) {
				Definitions follow = this.parseDefinitions();

				return this.alloc.make!Definitions(DefinitionsEnum.Defs
					, def
					, follow
				);
			}
			return this.alloc.make!Definitions(DefinitionsEnum.Def
				, def
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Definition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDefinition() const {
		return this.firstOperationDefinition()
			 || this.firstFragmentDefinition();
	}

	Definition parseDefinition() {
		try {
			return this.parseDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Definition an Exception was thrown.", e);
		}
	}

	Definition parseDefinitionImpl() {
		if(this.firstOperationDefinition()) {
			OperationDefinition op = this.parseOperationDefinition();

			return this.alloc.make!Definition(DefinitionEnum.Op
				, op
			);
		} else if(this.firstFragmentDefinition()) {
			FragmentDefinition frag = this.parseFragmentDefinition();

			return this.alloc.make!Definition(DefinitionEnum.Frag
				, frag
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an OperationDefinition, or FragmentDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationDefinition() const {
		return this.firstSelectionSet()
			 || this.firstOperationType();
	}

	OperationDefinition parseOperationDefinition() {
		try {
			return this.parseOperationDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a OperationDefinition an Exception was thrown.", e);
		}
	}

	OperationDefinition parseOperationDefinitionImpl() {
		if(this.firstSelectionSet()) {
			SelectionSet ss = this.parseSelectionSet();

			return this.alloc.make!OperationDefinition(OperationDefinitionEnum.SelSet
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

							return this.alloc.make!OperationDefinition(OperationDefinitionEnum.OT_VD
								, ot
								, name
								, vd
								, d
								, ss
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return this.alloc.make!OperationDefinition(OperationDefinitionEnum.OT_V
							, ot
							, name
							, vd
							, ss
						);
					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.firstDirectives()) {
					Directives d = this.parseDirectives();
					if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return this.alloc.make!OperationDefinition(OperationDefinitionEnum.OT_D
							, ot
							, name
							, d
							, ss
						);
					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return this.alloc.make!OperationDefinition(OperationDefinitionEnum.OT
						, ot
						, name
						, ss
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an VariableDefinitions, Directives, or SelectionSet. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an SelectionSet, or OperationType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSelectionSet() const {
		return this.lex.front.type == TokenType.lcurly;
	}

	SelectionSet parseSelectionSet() {
		try {
			return this.parseSelectionSetImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a SelectionSet an Exception was thrown.", e);
		}
	}

	SelectionSet parseSelectionSetImpl() {
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.firstSelections()) {
				Selections sel = this.parseSelections();
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return this.alloc.make!SelectionSet(SelectionSetEnum.SS
						, sel
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an Selections. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lcurly. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationType() const {
		return this.lex.front.type == TokenType.query
			 || this.lex.front.type == TokenType.mutation;
	}

	OperationType parseOperationType() {
		try {
			return this.parseOperationTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a OperationType an Exception was thrown.", e);
		}
	}

	OperationType parseOperationTypeImpl() {
		if(this.lex.front.type == TokenType.query) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!OperationType(OperationTypeEnum.Query
				, tok
			);
		} else if(this.lex.front.type == TokenType.mutation) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!OperationType(OperationTypeEnum.Mutation
				, tok
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an query, or mutation. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSelections() const {
		return this.firstSelection();
	}

	Selections parseSelections() {
		try {
			return this.parseSelectionsImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Selections an Exception was thrown.", e);
		}
	}

	Selections parseSelectionsImpl() {
		if(this.firstSelection()) {
			Selection sel = this.parseSelection();
			if(this.firstSelections()) {
				Selections follow = this.parseSelections();

				return this.alloc.make!Selections(SelectionsEnum.Sels
					, sel
					, follow
				);
			} else if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstSelections()) {
					Selections follow = this.parseSelections();

					return this.alloc.make!Selections(SelectionsEnum.Selsc
						, sel
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Selections. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			return this.alloc.make!Selections(SelectionsEnum.Sel
				, sel
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Selection. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSelection() const {
		return this.firstField()
			 || this.firstFragmentSpread()
			 || this.firstInlineFragment();
	}

	Selection parseSelection() {
		try {
			return this.parseSelectionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Selection an Exception was thrown.", e);
		}
	}

	Selection parseSelectionImpl() {
		if(this.firstField()) {
			Field field = this.parseField();

			return this.alloc.make!Selection(SelectionEnum.Field
				, field
			);
		} else if(this.firstFragmentSpread()) {
			FragmentSpread frag = this.parseFragmentSpread();

			return this.alloc.make!Selection(SelectionEnum.Frag
				, frag
			);
		} else if(this.firstInlineFragment()) {
			InlineFragment ifrag = this.parseInlineFragment();

			return this.alloc.make!Selection(SelectionEnum.IFrag
				, ifrag
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Field, FragmentSpread, or InlineFragment. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstField() const {
		return this.firstFieldName();
	}

	Field parseField() {
		try {
			return this.parseFieldImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Field an Exception was thrown.", e);
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

						return this.alloc.make!Field(FieldEnum.FADS
							, name
							, args
							, dirs
							, ss
						);
					}
					return this.alloc.make!Field(FieldEnum.FAD
						, name
						, args
						, dirs
					);
				} else if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return this.alloc.make!Field(FieldEnum.FAS
						, name
						, args
						, ss
					);
				}
				return this.alloc.make!Field(FieldEnum.FA
					, name
					, args
				);
			} else if(this.firstDirectives()) {
				Directives dirs = this.parseDirectives();
				if(this.firstSelectionSet()) {
					SelectionSet ss = this.parseSelectionSet();

					return this.alloc.make!Field(FieldEnum.FDS
						, name
						, dirs
						, ss
					);
				}
				return this.alloc.make!Field(FieldEnum.FD
					, name
					, dirs
				);
			} else if(this.firstSelectionSet()) {
				SelectionSet ss = this.parseSelectionSet();

				return this.alloc.make!Field(FieldEnum.FS
					, name
					, ss
				);
			}
			return this.alloc.make!Field(FieldEnum.F
				, name
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an FieldName. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFieldName() const {
		return this.lex.front.type == TokenType.alias_
			 || this.lex.front.type == TokenType.name;
	}

	FieldName parseFieldName() {
		try {
			return this.parseFieldNameImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a FieldName an Exception was thrown.", e);
		}
	}

	FieldName parseFieldNameImpl() {
		if(this.lex.front.type == TokenType.alias_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!FieldName(FieldNameEnum.A
				, tok
			);
		} else if(this.lex.front.type == TokenType.name) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!FieldName(FieldNameEnum.N
				, tok
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an alias_, or name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstAlias() const {
		return this.lex.front.type == TokenType.name;
	}

	Alias parseAlias() {
		try {
			return this.parseAliasImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Alias an Exception was thrown.", e);
		}
	}

	Alias parseAliasImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token from = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.lex.front.type == TokenType.name) {
					Token to = this.lex.front;
					this.lex.popFront();

					return this.alloc.make!Alias(AliasEnum.A
						, from
						, to
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an name. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArguments() const {
		return this.lex.front.type == TokenType.lparen;
	}

	Arguments parseArguments() {
		try {
			return this.parseArgumentsImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Arguments an Exception was thrown.", e);
		}
	}

	Arguments parseArgumentsImpl() {
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			if(this.firstArgument()) {
				Argument arg = this.parseArgument();
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return this.alloc.make!Arguments(ArgumentsEnum.Arg
						, arg
					);
				} else if(this.lex.front.type == TokenType.comma) {
					this.lex.popFront();
					if(this.firstArguments()) {
						Arguments follow = this.parseArguments();
						if(this.lex.front.type == TokenType.rparen) {
							this.lex.popFront();

							return this.alloc.make!Arguments(ArgumentsEnum.Args
								, arg
								, follow
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an rparen. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an Arguments. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rparen, or comma. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an Argument. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lparen. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArgument() const {
		return this.lex.front.type == TokenType.name;
	}

	Argument parseArgument() {
		try {
			return this.parseArgumentImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Argument an Exception was thrown.", e);
		}
	}

	Argument parseArgumentImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstValueOrVariable()) {
					this.parseValueOrVariable();

					return this.alloc.make!Argument(ArgumentEnum.Name
						, name
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an ValueOrVariable. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFragmentSpread() const {
		return this.lex.front.type == TokenType.dots;
	}

	FragmentSpread parseFragmentSpread() {
		try {
			return this.parseFragmentSpreadImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a FragmentSpread an Exception was thrown.", e);
		}
	}

	FragmentSpread parseFragmentSpreadImpl() {
		if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();

					return this.alloc.make!FragmentSpread(FragmentSpreadEnum.FD
						, name
						, dirs
					);
				}
				return this.alloc.make!FragmentSpread(FragmentSpreadEnum.F
					, name
				);
			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an dots. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInlineFragment() const {
		return this.lex.front.type == TokenType.dots;
	}

	InlineFragment parseInlineFragment() {
		try {
			return this.parseInlineFragmentImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a InlineFragment an Exception was thrown.", e);
		}
	}

	InlineFragment parseInlineFragmentImpl() {
		if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.on_) {
				this.lex.popFront();
				if(this.firstTypeCondition()) {
					TypeCondition tc = this.parseTypeCondition();
					if(this.firstDirectives()) {
						Directives dirs = this.parseDirectives();
						if(this.firstSelectionSet()) {
							SelectionSet ss = this.parseSelectionSet();

							return this.alloc.make!InlineFragment(InlineFragmentEnum.TDS
								, tc
								, dirs
								, ss
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.firstSelectionSet()) {
						SelectionSet ss = this.parseSelectionSet();

						return this.alloc.make!InlineFragment(InlineFragmentEnum.TS
							, tc
							, ss
						);
					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an TypeCondition. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an on_. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an dots. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFragmentDefinition() const {
		return this.lex.front.type == TokenType.fragment;
	}

	FragmentDefinition parseFragmentDefinition() {
		try {
			return this.parseFragmentDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a FragmentDefinition an Exception was thrown.", e);
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
					if(this.firstTypeCondition()) {
						TypeCondition tc = this.parseTypeCondition();
						if(this.firstDirectives()) {
							Directives dirs = this.parseDirectives();
							if(this.firstSelectionSet()) {
								SelectionSet ss = this.parseSelectionSet();

								return this.alloc.make!FragmentDefinition(FragmentDefinitionEnum.FTDS
									, name
									, tc
									, dirs
									, ss
								);
							}
							auto app = AllocAppender!string(this.alloc);
							formattedWrite(&app, 
								"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
								this.lex.front, this.lex.line, this.lex.column
							);
							throw this.alloc.make!ParseException(app.data,
								__FILE__, __LINE__
							);

						} else if(this.firstSelectionSet()) {
							SelectionSet ss = this.parseSelectionSet();

							return this.alloc.make!FragmentDefinition(FragmentDefinitionEnum.FTS
								, name
								, tc
								, ss
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an TypeCondition. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an on_. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an fragment. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirectives() const {
		return this.firstDirective();
	}

	Directives parseDirectives() {
		try {
			return this.parseDirectivesImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Directives an Exception was thrown.", e);
		}
	}

	Directives parseDirectivesImpl() {
		if(this.firstDirective()) {
			Directive dir = this.parseDirective();
			if(this.firstDirectives()) {
				Directives follow = this.parseDirectives();

				return this.alloc.make!Directives(DirectivesEnum.Dirs
					, dir
					, follow
				);
			}
			return this.alloc.make!Directives(DirectivesEnum.Dir
				, dir
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Directive. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirective() const {
		return this.lex.front.type == TokenType.at;
	}

	Directive parseDirective() {
		try {
			return this.parseDirectiveImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Directive an Exception was thrown.", e);
		}
	}

	Directive parseDirectiveImpl() {
		if(this.lex.front.type == TokenType.at) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				if(this.lex.front.type == TokenType.colon) {
					this.lex.popFront();
					if(this.firstValueOrVariable()) {
						ValueOrVariable vv = this.parseValueOrVariable();

						return this.alloc.make!Directive(DirectiveEnum.NVV
							, name
							, vv
						);
					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an ValueOrVariable. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				} else if(this.lex.front.type == TokenType.lparen) {
					this.lex.popFront();
					if(this.firstArgument()) {
						Argument arg = this.parseArgument();
						if(this.lex.front.type == TokenType.rparen) {
							this.lex.popFront();

							return this.alloc.make!Directive(DirectiveEnum.NArg
								, name
								, arg
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an rparen. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an Argument. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				return this.alloc.make!Directive(DirectiveEnum.N
					, name
				);
			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an at. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstTypeCondition() const {
		return this.lex.front.type == TokenType.name;
	}

	TypeCondition parseTypeCondition() {
		try {
			return this.parseTypeConditionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a TypeCondition an Exception was thrown.", e);
		}
	}

	TypeCondition parseTypeConditionImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token tname = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!TypeCondition(TypeConditionEnum.TN
				, tname
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariableDefinitions() const {
		return this.lex.front.type == TokenType.lparen;
	}

	VariableDefinitions parseVariableDefinitions() {
		try {
			return this.parseVariableDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a VariableDefinitions an Exception was thrown.", e);
		}
	}

	VariableDefinitions parseVariableDefinitionsImpl() {
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				return this.alloc.make!VariableDefinitions(VariableDefinitionsEnum.Empty
				);
			} else if(this.firstVariableDefinitionList()) {
				VariableDefinitionList vars = this.parseVariableDefinitionList();
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return this.alloc.make!VariableDefinitions(VariableDefinitionsEnum.Vars
						, vars
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rparen. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an rparen, or VariableDefinitionList. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lparen. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariableDefinitionList() const {
		return this.firstVariableDefinition();
	}

	VariableDefinitionList parseVariableDefinitionList() {
		try {
			return this.parseVariableDefinitionListImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a VariableDefinitionList an Exception was thrown.", e);
		}
	}

	VariableDefinitionList parseVariableDefinitionListImpl() {
		if(this.firstVariableDefinition()) {
			VariableDefinition var = this.parseVariableDefinition();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstVariableDefinitionList()) {
					VariableDefinitionList follow = this.parseVariableDefinitionList();

					return this.alloc.make!VariableDefinitionList(VariableDefinitionListEnum.Vars
						, var
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an VariableDefinitionList. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			return this.alloc.make!VariableDefinitionList(VariableDefinitionListEnum.Var
				, var
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an VariableDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariableDefinition() const {
		return this.firstVariable();
	}

	VariableDefinition parseVariableDefinition() {
		try {
			return this.parseVariableDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a VariableDefinition an Exception was thrown.", e);
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

						return this.alloc.make!VariableDefinition(VariableDefinitionEnum.VarD
							, type
							, dvalue
						);
					}
					return this.alloc.make!VariableDefinition(VariableDefinitionEnum.Var
						, type
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Type. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Variable. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstVariable() const {
		return this.lex.front.type == TokenType.dollar;
	}

	Variable parseVariable() {
		try {
			return this.parseVariableImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Variable an Exception was thrown.", e);
		}
	}

	Variable parseVariableImpl() {
		if(this.lex.front.type == TokenType.dollar) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();

				return this.alloc.make!Variable(VariableEnum.Var
					, name
				);
			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an dollar. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDefaultValue() const {
		return this.lex.front.type == TokenType.equal;
	}

	DefaultValue parseDefaultValue() {
		try {
			return this.parseDefaultValueImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a DefaultValue an Exception was thrown.", e);
		}
	}

	DefaultValue parseDefaultValueImpl() {
		if(this.lex.front.type == TokenType.equal) {
			this.lex.popFront();
			if(this.firstValue()) {
				Value value = this.parseValue();

				return this.alloc.make!DefaultValue(DefaultValueEnum.DV
					, value
				);
			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an Value. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an equal. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstValueOrVariable() const {
		return this.firstValue()
			 || this.firstVariable();
	}

	ValueOrVariable parseValueOrVariable() {
		try {
			return this.parseValueOrVariableImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ValueOrVariable an Exception was thrown.", e);
		}
	}

	ValueOrVariable parseValueOrVariableImpl() {
		if(this.firstValue()) {
			Value val = this.parseValue();

			return this.alloc.make!ValueOrVariable(ValueOrVariableEnum.Val
				, val
			);
		} else if(this.firstVariable()) {
			Variable var = this.parseVariable();

			return this.alloc.make!ValueOrVariable(ValueOrVariableEnum.Var
				, var
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Value, or Variable. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstValue() const {
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
			throw new ParseException("While parsing a Value an Exception was thrown.", e);
		}
	}

	Value parseValueImpl() {
		if(this.lex.front.type == TokenType.stringValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!Value(ValueEnum.STR
				, tok
			);
		} else if(this.lex.front.type == TokenType.intValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!Value(ValueEnum.INT
				, tok
			);
		} else if(this.lex.front.type == TokenType.floatValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!Value(ValueEnum.FLOAT
				, tok
			);
		} else if(this.lex.front.type == TokenType.true_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!Value(ValueEnum.T
				, tok
			);
		} else if(this.lex.front.type == TokenType.false_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!Value(ValueEnum.F
				, tok
			);
		} else if(this.firstArray()) {
			Array arr = this.parseArray();

			return this.alloc.make!Value(ValueEnum.ARR
				, arr
			);
		} else if(this.firstObjectType()) {
			ObjectType obj = this.parseObjectType();

			return this.alloc.make!Value(ValueEnum.O
				, obj
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an stringValue, intValue, floatValue, true_, false_, Array, or ObjectType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstType() const {
		return this.lex.front.type == TokenType.name
			 || this.firstListType();
	}

	Type parseType() {
		try {
			return this.parseTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Type an Exception was thrown.", e);
		}
	}

	Type parseTypeImpl() {
		if(this.lex.front.type == TokenType.name) {
			Token tname = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();

				return this.alloc.make!Type(TypeEnum.TN
					, tname
				);
			}
			return this.alloc.make!Type(TypeEnum.T
				, tname
			);
		} else if(this.firstListType()) {
			ListType list = this.parseListType();
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();

				return this.alloc.make!Type(TypeEnum.LN
					, list
				);
			}
			return this.alloc.make!Type(TypeEnum.L
				, list
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an name, or ListType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstListType() const {
		return this.lex.front.type == TokenType.lbrack;
	}

	ListType parseListType() {
		try {
			return this.parseListTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ListType an Exception was thrown.", e);
		}
	}

	ListType parseListTypeImpl() {
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			if(this.firstType()) {
				Type type = this.parseType();
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					return this.alloc.make!ListType(ListTypeEnum.T
						, type
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rbrack. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an Type. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lbrack. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstValues() const {
		return this.firstValue();
	}

	Values parseValues() {
		try {
			return this.parseValuesImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Values an Exception was thrown.", e);
		}
	}

	Values parseValuesImpl() {
		if(this.firstValue()) {
			Value val = this.parseValue();
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				if(this.firstValues()) {
					Values follow = this.parseValues();

					return this.alloc.make!Values(ValuesEnum.Vals
						, val
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Values. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			return this.alloc.make!Values(ValuesEnum.Val
				, val
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Value. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstArray() const {
		return this.lex.front.type == TokenType.lbrack;
	}

	Array parseArray() {
		try {
			return this.parseArrayImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Array an Exception was thrown.", e);
		}
	}

	Array parseArrayImpl() {
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.rbrack) {
				this.lex.popFront();

				return this.alloc.make!Array(ArrayEnum.Empty
				);
			} else if(this.firstValues()) {
				Values vals = this.parseValues();
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					return this.alloc.make!Array(ArrayEnum.Value
						, vals
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rbrack. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an rbrack, or Values. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lbrack. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectValues() const {
		return this.lex.front.type == TokenType.name;
	}

	ObjectValues parseObjectValues() {
		try {
			return this.parseObjectValuesImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ObjectValues an Exception was thrown.", e);
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

							return this.alloc.make!ObjectValues(ObjectValuesEnum.Vsc
								, name
								, val
								, follow
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an ObjectValues. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					} else if(this.firstObjectValues()) {
						ObjectValues follow = this.parseObjectValues();

						return this.alloc.make!ObjectValues(ObjectValuesEnum.Vs
							, name
							, val
							, follow
						);
					}
					return this.alloc.make!ObjectValues(ObjectValuesEnum.V
						, name
						, val
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Value. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectValue() const {
		return this.lex.front.type == TokenType.name;
	}

	ObjectValue parseObjectValue() {
		try {
			return this.parseObjectValueImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ObjectValue an Exception was thrown.", e);
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

					return this.alloc.make!ObjectValue(ObjectValueEnum.V
						, name
						, val
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Value. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectType() const {
		return this.lex.front.type == TokenType.lcurly;
	}

	ObjectType parseObjectType() {
		try {
			return this.parseObjectTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ObjectType an Exception was thrown.", e);
		}
	}

	ObjectType parseObjectTypeImpl() {
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.firstObjectValues()) {
				ObjectValues vals = this.parseObjectValues();
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return this.alloc.make!ObjectType(ObjectTypeEnum.Var
						, vals
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an rcurly. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an ObjectValues. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an lcurly. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

}
