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
		return this.firstDefinitions();
	}

	Document parseDocument() {
		try {
			return this.parseDocumentImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
				"While parsing a Document an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Document parseDocumentImpl() {
		if(this.firstDefinitions()) {
			Definitions defs = this.parseDefinitions();

			return this.alloc.make!Document(DocumentEnum.Defi
				, defs
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

	bool firstDefinitions() const {
		return this.firstDefinition();
	}

	Definitions parseDefinitions() {
		try {
			return this.parseDefinitionsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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
			 || this.firstFragmentDefinition()
			 || this.firstTypeSystemDefinition();
	}

	Definition parseDefinition() {
		try {
			return this.parseDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
				"While parsing a Definition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Definition parseDefinitionImpl() {
		if(this.firstOperationDefinition()) {
			OperationDefinition op = this.parseOperationDefinition();

			return this.alloc.make!Definition(DefinitionEnum.O
				, op
			);
		} else if(this.firstFragmentDefinition()) {
			FragmentDefinition frag = this.parseFragmentDefinition();

			return this.alloc.make!Definition(DefinitionEnum.F
				, frag
			);
		} else if(this.firstTypeSystemDefinition()) {
			TypeSystemDefinition type = this.parseTypeSystemDefinition();

			return this.alloc.make!Definition(DefinitionEnum.T
				, type
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an OperationDefinition, FragmentDefinition, or TypeSystemDefinition. Found a '%s' at %s:%s.", 
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
			throw this.alloc.make!(ParseException)(
				"While parsing a OperationDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
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
			throw this.alloc.make!(ParseException)(
				"While parsing a SelectionSet an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	SelectionSet parseSelectionSetImpl() {
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.rcurly) {
				this.lex.popFront();

				return this.alloc.make!SelectionSet(SelectionSetEnum.Empty
				);
			} else if(this.firstSelections()) {
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
				"Was expecting an rcurly, or Selections. Found a '%s' at %s:%s.", 
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
			 || this.lex.front.type == TokenType.mutation
			 || this.lex.front.type == TokenType.subscription;
	}

	OperationType parseOperationType() {
		try {
			return this.parseOperationTypeImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
				"While parsing a OperationType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
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
		} else if(this.lex.front.type == TokenType.subscription) {
			Token tok = this.lex.front;
			this.lex.popFront();

			return this.alloc.make!OperationType(OperationTypeEnum.Sub
				, tok
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an query, mutation, or subscription. Found a '%s' at %s:%s.", 
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
			throw this.alloc.make!(ParseException)(
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
			 || this.lex.front.type == TokenType.dots;
	}

	Selection parseSelection() {
		try {
			return this.parseSelectionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
				"While parsing a Selection an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Selection parseSelectionImpl() {
		if(this.firstField()) {
			Field field = this.parseField();

			return this.alloc.make!Selection(SelectionEnum.Field
				, field
			);
		} else if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			if(this.firstFragmentSpread()) {
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
				"Was expecting an FragmentSpread, or InlineFragment. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an Field, or dots. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFragmentSpread() const {
		return this.lex.front.type == TokenType.name;
	}

	FragmentSpread parseFragmentSpread() {
		try {
			return this.parseFragmentSpreadImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

	bool firstInlineFragment() const {
		return this.lex.front.type == TokenType.on_
			 || this.firstDirectives()
			 || this.firstSelectionSet();
	}

	InlineFragment parseInlineFragment() {
		try {
			return this.parseInlineFragmentImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		} else if(this.firstDirectives()) {
			Directives dirs = this.parseDirectives();
			if(this.firstSelectionSet()) {
				SelectionSet ss = this.parseSelectionSet();

				return this.alloc.make!InlineFragment(InlineFragmentEnum.DS
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

			return this.alloc.make!InlineFragment(InlineFragmentEnum.S
				, ss
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an on_, Directives, or SelectionSet. Found a '%s' at %s:%s.", 
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
			throw this.alloc.make!(ParseException)(
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
		return this.lex.front.type == TokenType.name;
	}

	FieldName parseFieldName() {
		try {
			return this.parseFieldNameImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!FieldName(FieldNameEnum.A
						, name
						, aka
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
			return this.alloc.make!FieldName(FieldNameEnum.N
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

	bool firstArguments() const {
		return this.lex.front.type == TokenType.lparen;
	}

	Arguments parseArguments() {
		try {
			return this.parseArgumentsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!Arguments(ArgumentsEnum.Arg
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
				"Was expecting an ArgumentList. Found a '%s' at %s:%s.", 
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

	bool firstArgumentList() const {
		return this.firstArgument();
	}

	ArgumentList parseArgumentList() {
		try {
			return this.parseArgumentListImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!ArgumentList(ArgumentListEnum.ACS
						, arg
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an ArgumentList. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstArgumentList()) {
				ArgumentList follow = this.parseArgumentList();

				return this.alloc.make!ArgumentList(ArgumentListEnum.AS
					, arg
					, follow
				);
			}
			return this.alloc.make!ArgumentList(ArgumentListEnum.A
				, arg
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

	bool firstArgument() const {
		return this.lex.front.type == TokenType.name;
	}

	Argument parseArgument() {
		try {
			return this.parseArgumentImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!Argument(ArgumentEnum.Name
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

	bool firstFragmentDefinition() const {
		return this.lex.front.type == TokenType.fragment;
	}

	FragmentDefinition parseFragmentDefinition() {
		try {
			return this.parseFragmentDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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
						"Was expecting an name. Found a '%s' at %s:%s.", 
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!Directive(DirectiveEnum.NArg
						, name
						, arg
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

	bool firstVariableDefinitions() const {
		return this.lex.front.type == TokenType.lparen;
	}

	VariableDefinitions parseVariableDefinitions() {
		try {
			return this.parseVariableDefinitionsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!VariableDefinitionList(VariableDefinitionListEnum.VCF
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

			} else if(this.firstVariableDefinitionList()) {
				VariableDefinitionList follow = this.parseVariableDefinitionList();

				return this.alloc.make!VariableDefinitionList(VariableDefinitionListEnum.VF
					, var
					, follow
				);
			}
			return this.alloc.make!VariableDefinitionList(VariableDefinitionListEnum.V
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
				"While parsing a ValueOrVariable an Exception was thrown.",
				e, __FILE__, __LINE__
			);
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
			throw this.alloc.make!(ParseException)(
				"While parsing a Value an Exception was thrown.",
				e, __FILE__, __LINE__
			);
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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
			throw this.alloc.make!(ParseException)(
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

	bool firstTypeSystemDefinition() const {
		return this.firstSchemaDefinition()
			 || this.firstTypeDefinition()
			 || this.firstTypeExtensionDefinition()
			 || this.firstDirectiveDefinition();
	}

	TypeSystemDefinition parseTypeSystemDefinition() {
		try {
			return this.parseTypeSystemDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
				"While parsing a TypeSystemDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	TypeSystemDefinition parseTypeSystemDefinitionImpl() {
		if(this.firstSchemaDefinition()) {
			SchemaDefinition sch = this.parseSchemaDefinition();

			return this.alloc.make!TypeSystemDefinition(TypeSystemDefinitionEnum.S
				, sch
			);
		} else if(this.firstTypeDefinition()) {
			TypeDefinition td = this.parseTypeDefinition();

			return this.alloc.make!TypeSystemDefinition(TypeSystemDefinitionEnum.T
				, td
			);
		} else if(this.firstTypeExtensionDefinition()) {
			TypeExtensionDefinition ted = this.parseTypeExtensionDefinition();

			return this.alloc.make!TypeSystemDefinition(TypeSystemDefinitionEnum.TE
				, ted
			);
		} else if(this.firstDirectiveDefinition()) {
			DirectiveDefinition dd = this.parseDirectiveDefinition();

			return this.alloc.make!TypeSystemDefinition(TypeSystemDefinitionEnum.D
				, dd
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an SchemaDefinition, TypeDefinition, TypeExtensionDefinition, or DirectiveDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstTypeDefinition() const {
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
			throw this.alloc.make!(ParseException)(
				"While parsing a TypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	TypeDefinition parseTypeDefinitionImpl() {
		if(this.firstScalarTypeDefinition()) {
			ScalarTypeDefinition std = this.parseScalarTypeDefinition();

			return this.alloc.make!TypeDefinition(TypeDefinitionEnum.S
				, std
			);
		} else if(this.firstObjectTypeDefinition()) {
			ObjectTypeDefinition otd = this.parseObjectTypeDefinition();

			return this.alloc.make!TypeDefinition(TypeDefinitionEnum.O
				, otd
			);
		} else if(this.firstInterfaceTypeDefinition()) {
			InterfaceTypeDefinition itd = this.parseInterfaceTypeDefinition();

			return this.alloc.make!TypeDefinition(TypeDefinitionEnum.I
				, itd
			);
		} else if(this.firstUnionTypeDefinition()) {
			UnionTypeDefinition utd = this.parseUnionTypeDefinition();

			return this.alloc.make!TypeDefinition(TypeDefinitionEnum.U
				, utd
			);
		} else if(this.firstEnumTypeDefinition()) {
			EnumTypeDefinition etd = this.parseEnumTypeDefinition();

			return this.alloc.make!TypeDefinition(TypeDefinitionEnum.E
				, etd
			);
		} else if(this.firstInputObjectTypeDefinition()) {
			InputObjectTypeDefinition iod = this.parseInputObjectTypeDefinition();

			return this.alloc.make!TypeDefinition(TypeDefinitionEnum.IO
				, iod
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an ScalarTypeDefinition, ObjectTypeDefinition, InterfaceTypeDefinition, UnionTypeDefinition, EnumTypeDefinition, or InputObjectTypeDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstSchemaDefinition() const {
		return this.lex.front.type == TokenType.schema;
	}

	SchemaDefinition parseSchemaDefinition() {
		try {
			return this.parseSchemaDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

							return this.alloc.make!SchemaDefinition(SchemaDefinitionEnum.DO
								, dir
								, otds
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
						"Was expecting an OperationTypeDefinitions. Found a '%s' at %s:%s.", 
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

			} else if(this.lex.front.type == TokenType.lcurly) {
				this.lex.popFront();
				if(this.firstOperationTypeDefinitions()) {
					OperationTypeDefinitions otds = this.parseOperationTypeDefinitions();
					if(this.lex.front.type == TokenType.rcurly) {
						this.lex.popFront();

						return this.alloc.make!SchemaDefinition(SchemaDefinitionEnum.O
							, otds
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
					"Was expecting an OperationTypeDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an schema. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationTypeDefinitions() const {
		return this.firstOperationTypeDefinition();
	}

	OperationTypeDefinitions parseOperationTypeDefinitions() {
		try {
			return this.parseOperationTypeDefinitionsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!OperationTypeDefinitions(OperationTypeDefinitionsEnum.OCS
						, otd
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an OperationTypeDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstOperationTypeDefinitions()) {
				OperationTypeDefinitions follow = this.parseOperationTypeDefinitions();

				return this.alloc.make!OperationTypeDefinitions(OperationTypeDefinitionsEnum.OS
					, otd
					, follow
				);
			}
			return this.alloc.make!OperationTypeDefinitions(OperationTypeDefinitionsEnum.O
				, otd
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an OperationTypeDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstOperationTypeDefinition() const {
		return this.firstOperationType();
	}

	OperationTypeDefinition parseOperationTypeDefinition() {
		try {
			return this.parseOperationTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!OperationTypeDefinition(OperationTypeDefinitionEnum.O
						, ot
						, nt
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
			"Was expecting an OperationType. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstScalarTypeDefinition() const {
		return this.lex.front.type == TokenType.scalar;
	}

	ScalarTypeDefinition parseScalarTypeDefinition() {
		try {
			return this.parseScalarTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!ScalarTypeDefinition(ScalarTypeDefinitionEnum.D
						, name
						, dir
					);
				}
				return this.alloc.make!ScalarTypeDefinition(ScalarTypeDefinitionEnum.S
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
			"Was expecting an scalar. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstObjectTypeDefinition() const {
		return this.lex.front.type == TokenType.type;
	}

	ObjectTypeDefinition parseObjectTypeDefinition() {
		try {
			return this.parseObjectTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

									return this.alloc.make!ObjectTypeDefinition(ObjectTypeDefinitionEnum.ID
										, name
										, ii
										, dir
										, fds
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
								"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
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

					} else if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return this.alloc.make!ObjectTypeDefinition(ObjectTypeDefinitionEnum.I
									, name
									, ii
									, fds
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
							"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
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

								return this.alloc.make!ObjectTypeDefinition(ObjectTypeDefinitionEnum.D
									, name
									, dir
									, fds
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
							"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
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

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstFieldDefinitions()) {
						FieldDefinitions fds = this.parseFieldDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return this.alloc.make!ObjectTypeDefinition(ObjectTypeDefinitionEnum.F
								, name
								, fds
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
						"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an ImplementsInterfaces, Directives, or lcurly. Found a '%s' at %s:%s.", 
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
			"Was expecting an type. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFieldDefinitions() const {
		return this.firstFieldDefinition();
	}

	FieldDefinitions parseFieldDefinitions() {
		try {
			return this.parseFieldDefinitionsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!FieldDefinitions(FieldDefinitionsEnum.FC
						, fd
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstFieldDefinitions()) {
				FieldDefinitions follow = this.parseFieldDefinitions();

				return this.alloc.make!FieldDefinitions(FieldDefinitionsEnum.FNC
					, fd
					, follow
				);
			}
			return this.alloc.make!FieldDefinitions(FieldDefinitionsEnum.F
				, fd
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an FieldDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstFieldDefinition() const {
		return this.lex.front.type == TokenType.name;
	}

	FieldDefinition parseFieldDefinition() {
		try {
			return this.parseFieldDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

							return this.alloc.make!FieldDefinition(FieldDefinitionEnum.AD
								, name
								, arg
								, typ
								, dir
							);
						}
						return this.alloc.make!FieldDefinition(FieldDefinitionEnum.A
							, name
							, arg
							, typ
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

			} else if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstType()) {
					Type typ = this.parseType();
					if(this.firstDirectives()) {
						Directives dir = this.parseDirectives();

						return this.alloc.make!FieldDefinition(FieldDefinitionEnum.D
							, name
							, typ
							, dir
						);
					}
					return this.alloc.make!FieldDefinition(FieldDefinitionEnum.T
						, name
						, typ
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
				"Was expecting an ArgumentsDefinition, or colon. Found a '%s' at %s:%s.", 
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

	bool firstImplementsInterfaces() const {
		return this.lex.front.type == TokenType.implements;
	}

	ImplementsInterfaces parseImplementsInterfaces() {
		try {
			return this.parseImplementsInterfacesImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

				return this.alloc.make!ImplementsInterfaces(ImplementsInterfacesEnum.N
					, nts
				);
			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an NamedTypes. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an implements. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstNamedTypes() const {
		return this.lex.front.type == TokenType.name;
	}

	NamedTypes parseNamedTypes() {
		try {
			return this.parseNamedTypesImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!NamedTypes(NamedTypesEnum.NCS
						, name
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an NamedTypes. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstNamedTypes()) {
				NamedTypes follow = this.parseNamedTypes();

				return this.alloc.make!NamedTypes(NamedTypesEnum.NS
					, name
					, follow
				);
			}
			return this.alloc.make!NamedTypes(NamedTypesEnum.N
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

	bool firstArgumentsDefinition() const {
		return this.lex.front.type == TokenType.lparen;
	}

	ArgumentsDefinition parseArgumentsDefinition() {
		try {
			return this.parseArgumentsDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!ArgumentsDefinition(ArgumentsDefinitionEnum.A
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
				"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
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

	bool firstInputValueDefinitions() const {
		return this.firstInputValueDefinition();
	}

	InputValueDefinitions parseInputValueDefinitions() {
		try {
			return this.parseInputValueDefinitionsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!InputValueDefinitions(InputValueDefinitionsEnum.ICF
						, iv
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstInputValueDefinitions()) {
				InputValueDefinitions follow = this.parseInputValueDefinitions();

				return this.alloc.make!InputValueDefinitions(InputValueDefinitionsEnum.IF
					, iv
					, follow
				);
			}
			return this.alloc.make!InputValueDefinitions(InputValueDefinitionsEnum.I
				, iv
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an InputValueDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInputValueDefinition() const {
		return this.lex.front.type == TokenType.name;
	}

	InputValueDefinition parseInputValueDefinition() {
		try {
			return this.parseInputValueDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

							return this.alloc.make!InputValueDefinition(InputValueDefinitionEnum.TVD
								, name
								, type
								, df
								, dirs
							);
						}
						return this.alloc.make!InputValueDefinition(InputValueDefinitionEnum.TV
							, name
							, type
							, df
						);
					} else if(this.firstDirectives()) {
						Directives dirs = this.parseDirectives();

						return this.alloc.make!InputValueDefinition(InputValueDefinitionEnum.TD
							, name
							, type
							, dirs
						);
					}
					return this.alloc.make!InputValueDefinition(InputValueDefinitionEnum.T
						, name
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
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstInterfaceTypeDefinition() const {
		return this.lex.front.type == TokenType.interface_;
	}

	InterfaceTypeDefinition parseInterfaceTypeDefinition() {
		try {
			return this.parseInterfaceTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

								return this.alloc.make!InterfaceTypeDefinition(InterfaceTypeDefinitionEnum.NDF
									, name
									, dirs
									, fds
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
							"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
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

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstFieldDefinitions()) {
						FieldDefinitions fds = this.parseFieldDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return this.alloc.make!InterfaceTypeDefinition(InterfaceTypeDefinitionEnum.NF
								, name
								, fds
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
						"Was expecting an FieldDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
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
			"Was expecting an interface_. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstUnionTypeDefinition() const {
		return this.lex.front.type == TokenType.union_;
	}

	UnionTypeDefinition parseUnionTypeDefinition() {
		try {
			return this.parseUnionTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

							return this.alloc.make!UnionTypeDefinition(UnionTypeDefinitionEnum.NDU
								, name
								, dirs
								, um
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an UnionMembers. Found a '%s' at %s:%s.", 
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

				} else if(this.lex.front.type == TokenType.equal) {
					this.lex.popFront();
					if(this.firstUnionMembers()) {
						UnionMembers um = this.parseUnionMembers();

						return this.alloc.make!UnionTypeDefinition(UnionTypeDefinitionEnum.NU
							, name
							, um
						);
					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an UnionMembers. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Directives, or equal. Found a '%s' at %s:%s.", 
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
			"Was expecting an union_. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstUnionMembers() const {
		return this.lex.front.type == TokenType.name;
	}

	UnionMembers parseUnionMembers() {
		try {
			return this.parseUnionMembersImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!UnionMembers(UnionMembersEnum.SPF
						, name
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an UnionMembers. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstUnionMembers()) {
				UnionMembers follow = this.parseUnionMembers();

				return this.alloc.make!UnionMembers(UnionMembersEnum.SF
					, name
					, follow
				);
			}
			return this.alloc.make!UnionMembers(UnionMembersEnum.S
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

	bool firstEnumTypeDefinition() const {
		return this.lex.front.type == TokenType.enum_;
	}

	EnumTypeDefinition parseEnumTypeDefinition() {
		try {
			return this.parseEnumTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

								return this.alloc.make!EnumTypeDefinition(EnumTypeDefinitionEnum.NDE
									, name
									, dir
									, evds
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
							"Was expecting an EnumValueDefinitions. Found a '%s' at %s:%s.", 
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

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstEnumValueDefinitions()) {
						EnumValueDefinitions evds = this.parseEnumValueDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return this.alloc.make!EnumTypeDefinition(EnumTypeDefinitionEnum.NE
								, name
								, evds
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
						"Was expecting an EnumValueDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
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
			"Was expecting an enum_. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstEnumValueDefinitions() const {
		return this.firstEnumValueDefinition();
	}

	EnumValueDefinitions parseEnumValueDefinitions() {
		try {
			return this.parseEnumValueDefinitionsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!EnumValueDefinitions(EnumValueDefinitionsEnum.DCE
						, evd
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an EnumValueDefinitions. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstEnumValueDefinitions()) {
				EnumValueDefinitions follow = this.parseEnumValueDefinitions();

				return this.alloc.make!EnumValueDefinitions(EnumValueDefinitionsEnum.DE
					, evd
					, follow
				);
			}
			return this.alloc.make!EnumValueDefinitions(EnumValueDefinitionsEnum.D
				, evd
			);
		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an EnumValueDefinition. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstEnumValueDefinition() const {
		return this.lex.front.type == TokenType.name;
	}

	EnumValueDefinition parseEnumValueDefinition() {
		try {
			return this.parseEnumValueDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

				return this.alloc.make!EnumValueDefinition(EnumValueDefinitionEnum.ED
					, name
					, dirs
				);
			}
			return this.alloc.make!EnumValueDefinition(EnumValueDefinitionEnum.E
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

	bool firstInputTypeDefinition() const {
		return this.lex.front.type == TokenType.input;
	}

	InputTypeDefinition parseInputTypeDefinition() {
		try {
			return this.parseInputTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

								return this.alloc.make!InputTypeDefinition(InputTypeDefinitionEnum.NDE
									, name
									, dir
									, ivds
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
							"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
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

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstInputValueDefinitions()) {
						InputValueDefinitions ivds = this.parseInputValueDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return this.alloc.make!InputTypeDefinition(InputTypeDefinitionEnum.NE
								, name
								, ivds
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
						"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
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
			"Was expecting an input. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstTypeExtensionDefinition() const {
		return this.lex.front.type == TokenType.extend;
	}

	TypeExtensionDefinition parseTypeExtensionDefinition() {
		try {
			return this.parseTypeExtensionDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

				return this.alloc.make!TypeExtensionDefinition(TypeExtensionDefinitionEnum.O
					, otd
				);
			}
			auto app = AllocAppender!string(this.alloc);
			formattedWrite(&app, 
				"Was expecting an ObjectTypeDefinition. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an extend. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirectiveDefinition() const {
		return this.lex.front.type == TokenType.directive;
	}

	DirectiveDefinition parseDirectiveDefinition() {
		try {
			return this.parseDirectiveDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

								return this.alloc.make!DirectiveDefinition(DirectiveDefinitionEnum.AD
									, name
									, ad
									, dl
								);
							}
							auto app = AllocAppender!string(this.alloc);
							formattedWrite(&app, 
								"Was expecting an DirectiveLocations. Found a '%s' at %s:%s.", 
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

					} else if(this.lex.front.type == TokenType.on_) {
						this.lex.popFront();
						if(this.firstDirectiveLocations()) {
							DirectiveLocations dl = this.parseDirectiveLocations();

							return this.alloc.make!DirectiveDefinition(DirectiveDefinitionEnum.D
								, name
								, dl
							);
						}
						auto app = AllocAppender!string(this.alloc);
						formattedWrite(&app, 
							"Was expecting an DirectiveLocations. Found a '%s' at %s:%s.", 
							this.lex.front, this.lex.line, this.lex.column
						);
						throw this.alloc.make!ParseException(app.data,
							__FILE__, __LINE__
						);

					}
					auto app = AllocAppender!string(this.alloc);
					formattedWrite(&app, 
						"Was expecting an ArgumentsDefinition, or on_. Found a '%s' at %s:%s.", 
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
				"Was expecting an at. Found a '%s' at %s:%s.", 
				this.lex.front, this.lex.line, this.lex.column
			);
			throw this.alloc.make!ParseException(app.data,
				__FILE__, __LINE__
			);

		}
		auto app = AllocAppender!string(this.alloc);
		formattedWrite(&app, 
			"Was expecting an directive. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

	bool firstDirectiveLocations() const {
		return this.lex.front.type == TokenType.name;
	}

	DirectiveLocations parseDirectiveLocations() {
		try {
			return this.parseDirectiveLocationsImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

					return this.alloc.make!DirectiveLocations(DirectiveLocationsEnum.NPF
						, name
						, follow
					);
				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an DirectiveLocations. Found a '%s' at %s:%s.", 
					this.lex.front, this.lex.line, this.lex.column
				);
				throw this.alloc.make!ParseException(app.data,
					__FILE__, __LINE__
				);

			} else if(this.firstDirectiveLocations()) {
				DirectiveLocations follow = this.parseDirectiveLocations();

				return this.alloc.make!DirectiveLocations(DirectiveLocationsEnum.NF
					, name
					, follow
				);
			}
			return this.alloc.make!DirectiveLocations(DirectiveLocationsEnum.N
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

	bool firstInputObjectTypeDefinition() const {
		return this.lex.front.type == TokenType.input;
	}

	InputObjectTypeDefinition parseInputObjectTypeDefinition() {
		try {
			return this.parseInputObjectTypeDefinitionImpl();
		} catch(ParseException e) {
			throw this.alloc.make!(ParseException)(
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

								return this.alloc.make!InputObjectTypeDefinition(InputObjectTypeDefinitionEnum.NDI
									, name
									, dirs
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
							"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
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

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					if(this.firstInputValueDefinitions()) {
						this.parseInputValueDefinitions();
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return this.alloc.make!InputObjectTypeDefinition(InputObjectTypeDefinitionEnum.NI
								, name
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
						"Was expecting an InputValueDefinitions. Found a '%s' at %s:%s.", 
						this.lex.front, this.lex.line, this.lex.column
					);
					throw this.alloc.make!ParseException(app.data,
						__FILE__, __LINE__
					);

				}
				auto app = AllocAppender!string(this.alloc);
				formattedWrite(&app, 
					"Was expecting an Directives, or lcurly. Found a '%s' at %s:%s.", 
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
			"Was expecting an input. Found a '%s' at %s:%s.", 
			this.lex.front, this.lex.line, this.lex.column
		);
		throw this.alloc.make!ParseException(app.data,
			__FILE__, __LINE__
		);

	}

}
