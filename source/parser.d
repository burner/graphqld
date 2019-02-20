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
		string[] subRules;
		subRules = ["Defi"];
		if(this.firstDefinitions()) {
			Definitions defs = this.parseDefinitions();

			return new Document(DocumentEnum.Defi
				, defs
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["directive -> Definition","enum_ -> Definition","extend -> Definition","fragment -> Definition","input -> Definition","interface_ -> Definition","lcurly -> Definition","mutation -> Definition","query -> Definition","scalar -> Definition","schema -> Definition","subscription -> Definition","type -> Definition","union_ -> Definition"]
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
		string[] subRules;
		subRules = ["Def", "Defs"];
		if(this.firstDefinition()) {
			Definition def = this.parseDefinition();
			subRules = ["Defs"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["directive -> TypeSystemDefinition","enum_ -> TypeSystemDefinition","extend -> TypeSystemDefinition","fragment -> FragmentDefinition","input -> TypeSystemDefinition","interface_ -> TypeSystemDefinition","lcurly -> OperationDefinition","mutation -> OperationDefinition","query -> OperationDefinition","scalar -> TypeSystemDefinition","schema -> TypeSystemDefinition","subscription -> OperationDefinition","type -> TypeSystemDefinition","union_ -> TypeSystemDefinition"]
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
		string[] subRules;
		subRules = ["O"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lcurly -> SelectionSet","mutation -> OperationType","query -> OperationType","subscription -> OperationType","fragment","directive -> DirectiveDefinition","enum_ -> TypeDefinition","extend -> TypeExtensionDefinition","input -> TypeDefinition","interface_ -> TypeDefinition","scalar -> TypeDefinition","schema -> SchemaDefinition","type -> TypeDefinition","union_ -> TypeDefinition"]
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
		string[] subRules;
		subRules = ["SelSet"];
		if(this.firstSelectionSet()) {
			SelectionSet ss = this.parseSelectionSet();

			return new OperationDefinition(OperationDefinitionEnum.SelSet
				, ss
			);
		} else if(this.firstOperationType()) {
			OperationType ot = this.parseOperationType();
			subRules = ["OT", "OT_D", "OT_V", "OT_VD"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["OT_V", "OT_VD"];
				if(this.firstVariableDefinitions()) {
					VariableDefinitions vd = this.parseVariableDefinitions();
					subRules = ["OT_VD"];
					if(this.firstDirectives()) {
						Directives d = this.parseDirectives();
						subRules = ["OT_VD"];
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
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["lcurly"]
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
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["at -> Directive","lcurly"]
					);

				} else if(this.firstDirectives()) {
					Directives d = this.parseDirectives();
					subRules = ["OT_D"];
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
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lparen","at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lcurly","mutation","query","subscription"]
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
		string[] subRules;
		subRules = ["SS"];
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			subRules = ["SS"];
			if(this.firstSelections()) {
				Selections sel = this.parseSelections();
				subRules = ["SS"];
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return new SelectionSet(SelectionSetEnum.SS
						, sel
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["dots -> Selection","name -> Selection","schema__ -> Selection","type -> Selection"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lcurly"]
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
		string[] subRules;
		subRules = ["Query"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["query","mutation","subscription"]
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
		string[] subRules;
		subRules = ["Sel", "Sels", "Selsc"];
		if(this.firstSelection()) {
			Selection sel = this.parseSelection();
			subRules = ["Sels"];
			if(this.firstSelections()) {
				Selections follow = this.parseSelections();

				return new Selections(SelectionsEnum.Sels
					, sel
					, follow
				);
			} else if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["Selsc"];
				if(this.firstSelections()) {
					Selections follow = this.parseSelections();

					return new Selections(SelectionsEnum.Selsc
						, sel
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dots -> Selection","name -> Selection","schema__ -> Selection","type -> Selection"]
				);

			}
			return new Selections(SelectionsEnum.Sel
				, sel
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["dots","name -> Field","schema__ -> Field","type -> Field"]
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
		string[] subRules;
		subRules = ["Field"];
		if(this.firstField()) {
			Field field = this.parseField();

			return new Selection(SelectionEnum.Field
				, field
			);
		} else if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			subRules = ["Spread"];
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
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name","at -> Directives","lcurly -> SelectionSet","on_"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name -> FieldName","schema__ -> FieldName","type -> FieldName","dots"]
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
		string[] subRules;
		subRules = ["F", "FD"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["FD"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["TDS", "TS"];
		if(this.lex.front.type == TokenType.on_) {
			this.lex.popFront();
			subRules = ["TDS", "TS"];
			if(this.lex.front.type == TokenType.name) {
				Token tc = this.lex.front;
				this.lex.popFront();
				subRules = ["TDS"];
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					subRules = ["TDS"];
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
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		} else if(this.firstDirectives()) {
			Directives dirs = this.parseDirectives();
			subRules = ["DS"];
			if(this.firstSelectionSet()) {
				SelectionSet ss = this.parseSelectionSet();

				return new InlineFragment(InlineFragmentEnum.DS
					, dirs
					, ss
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["lcurly"]
			);

		} else if(this.firstSelectionSet()) {
			SelectionSet ss = this.parseSelectionSet();

			return new InlineFragment(InlineFragmentEnum.S
				, ss
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["on_","at -> Directive","lcurly"]
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
		string[] subRules;
		subRules = ["F", "FA", "FAD", "FADS", "FAS", "FD", "FDS", "FS"];
		if(this.firstFieldName()) {
			FieldName name = this.parseFieldName();
			subRules = ["FA", "FAD", "FADS", "FAS"];
			if(this.firstArguments()) {
				Arguments args = this.parseArguments();
				subRules = ["FAD", "FADS"];
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					subRules = ["FADS"];
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
				subRules = ["FDS"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name","schema__","type"]
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
		string[] subRules;
		subRules = ["A", "N"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["A"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["A"];
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name","type","schema__"]
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
		string[] subRules;
		subRules = ["Empty", "List"];
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			subRules = ["List"];
			if(this.firstArgumentList()) {
				ArgumentList arg = this.parseArgumentList();
				subRules = ["List"];
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return new Arguments(ArgumentsEnum.List
						, arg
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rparen"]
				);

			} else if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				return new Arguments(ArgumentsEnum.Empty
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name -> Argument","rparen"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lparen"]
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
		string[] subRules;
		subRules = ["A", "ACS", "AS"];
		if(this.firstArgument()) {
			Argument arg = this.parseArgument();
			subRules = ["ACS"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["ACS"];
				if(this.firstArgumentList()) {
					ArgumentList follow = this.parseArgumentList();

					return new ArgumentList(ArgumentListEnum.ACS
						, arg
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> Argument"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["Name"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["Name"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["Name"];
				if(this.firstValueOrVariable()) {
					ValueOrVariable vv = this.parseValueOrVariable();

					return new Argument(ArgumentEnum.Name
						, name
						, vv
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dollar -> Variable","false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","stringValue -> Value","true_ -> Value"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["FTDS", "FTS"];
		if(this.lex.front.type == TokenType.fragment) {
			this.lex.popFront();
			subRules = ["FTDS", "FTS"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["FTDS", "FTS"];
				if(this.lex.front.type == TokenType.on_) {
					this.lex.popFront();
					subRules = ["FTDS", "FTS"];
					if(this.lex.front.type == TokenType.name) {
						Token tc = this.lex.front;
						this.lex.popFront();
						subRules = ["FTDS"];
						if(this.firstDirectives()) {
							Directives dirs = this.parseDirectives();
							subRules = ["FTDS"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["lcurly"]
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
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["at -> Directive","lcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["on_"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["fragment"]
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
		string[] subRules;
		subRules = ["Dir", "Dirs"];
		if(this.firstDirective()) {
			Directive dir = this.parseDirective();
			subRules = ["Dirs"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["at"]
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
		string[] subRules;
		subRules = ["N", "NArg"];
		if(this.lex.front.type == TokenType.at) {
			this.lex.popFront();
			subRules = ["N", "NArg"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["NArg"];
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
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["at"]
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
		string[] subRules;
		subRules = ["Empty", "Vars"];
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			subRules = ["Empty"];
			if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				return new VariableDefinitions(VariableDefinitionsEnum.Empty
				);
			} else if(this.firstVariableDefinitionList()) {
				VariableDefinitionList vars = this.parseVariableDefinitionList();
				subRules = ["Vars"];
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return new VariableDefinitions(VariableDefinitionsEnum.Vars
						, vars
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rparen"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["rparen","dollar -> VariableDefinition"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lparen"]
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
		string[] subRules;
		subRules = ["V", "VCF", "VF"];
		if(this.firstVariableDefinition()) {
			VariableDefinition var = this.parseVariableDefinition();
			subRules = ["VCF"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["VCF"];
				if(this.firstVariableDefinitionList()) {
					VariableDefinitionList follow = this.parseVariableDefinitionList();

					return new VariableDefinitionList(VariableDefinitionListEnum.VCF
						, var
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dollar -> VariableDefinition"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["dollar -> Variable"]
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
		string[] subRules;
		subRules = ["Var", "VarD"];
		if(this.firstVariable()) {
			this.parseVariable();
			subRules = ["Var", "VarD"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["Var", "VarD"];
				if(this.firstType()) {
					Type type = this.parseType();
					subRules = ["VarD"];
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lbrack -> ListType","name"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["dollar"]
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
		string[] subRules;
		subRules = ["Var"];
		if(this.lex.front.type == TokenType.dollar) {
			this.lex.popFront();
			subRules = ["Var"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();

				return new Variable(VariableEnum.Var
					, name
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["dollar"]
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
		string[] subRules;
		subRules = ["DV"];
		if(this.lex.front.type == TokenType.equal) {
			this.lex.popFront();
			subRules = ["DV"];
			if(this.firstValue()) {
				Value value = this.parseValue();

				return new DefaultValue(DefaultValueEnum.DV
					, value
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","stringValue","true_"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["equal"]
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
		string[] subRules;
		subRules = ["Val"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","stringValue","true_","dollar"]
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
		string[] subRules;
		subRules = ["STR"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["stringValue","intValue","floatValue","true_","false_","lbrack","lcurly"]
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
		string[] subRules;
		subRules = ["T", "TN"];
		if(this.lex.front.type == TokenType.name) {
			Token tname = this.lex.front;
			this.lex.popFront();
			subRules = ["TN"];
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
			subRules = ["LN"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name","lbrack"]
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
		string[] subRules;
		subRules = ["T"];
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			subRules = ["T"];
			if(this.firstType()) {
				Type type = this.parseType();
				subRules = ["T"];
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					return new ListType(ListTypeEnum.T
						, type
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rbrack"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["lbrack -> ListType","name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lbrack"]
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
		string[] subRules;
		subRules = ["Val", "Vals"];
		if(this.firstValue()) {
			Value val = this.parseValue();
			subRules = ["Vals"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["Vals"];
				if(this.firstValues()) {
					Values follow = this.parseValues();

					return new Values(ValuesEnum.Vals
						, val
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","stringValue -> Value","true_ -> Value"]
				);

			}
			return new Values(ValuesEnum.Val
				, val
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","stringValue","true_"]
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
		string[] subRules;
		subRules = ["Empty", "Value"];
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			subRules = ["Empty"];
			if(this.lex.front.type == TokenType.rbrack) {
				this.lex.popFront();

				return new Array(ArrayEnum.Empty
				);
			} else if(this.firstValues()) {
				Values vals = this.parseValues();
				subRules = ["Value"];
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					return new Array(ArrayEnum.Value
						, vals
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rbrack"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["rbrack","false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","stringValue -> Value","true_ -> Value"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lbrack"]
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
		string[] subRules;
		subRules = ["V", "Vs", "Vsc"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["V", "Vs", "Vsc"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["V", "Vs", "Vsc"];
				if(this.firstValue()) {
					Value val = this.parseValue();
					subRules = ["Vsc"];
					if(this.lex.front.type == TokenType.comma) {
						this.lex.popFront();
						subRules = ["Vsc"];
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
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name"]
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","stringValue","true_"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["V"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["V"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["V"];
				if(this.firstValue()) {
					Value val = this.parseValue();

					return new ObjectValue(ObjectValueEnum.V
						, name
						, val
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","stringValue","true_"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["Var"];
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			subRules = ["Var"];
			if(this.firstObjectValues()) {
				ObjectValues vals = this.parseObjectValues();
				subRules = ["Var"];
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					return new ObjectType(ObjectTypeEnum.Var
						, vals
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lcurly"]
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
		string[] subRules;
		subRules = ["S"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["schema","enum_ -> EnumTypeDefinition","input -> InputObjectTypeDefinition","interface_ -> InterfaceTypeDefinition","scalar -> ScalarTypeDefinition","type -> ObjectTypeDefinition","union_ -> UnionTypeDefinition","extend","directive"]
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
		string[] subRules;
		subRules = ["S"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["scalar","type","interface_","union_","enum_","input"]
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
		string[] subRules;
		subRules = ["DO", "O"];
		if(this.lex.front.type == TokenType.schema) {
			this.lex.popFront();
			subRules = ["DO"];
			if(this.firstDirectives()) {
				Directives dir = this.parseDirectives();
				subRules = ["DO"];
				if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["DO"];
					if(this.firstOperationTypeDefinitions()) {
						OperationTypeDefinitions otds = this.parseOperationTypeDefinitions();
						subRules = ["DO"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new SchemaDefinition(SchemaDefinitionEnum.DO
								, dir
								, otds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["rcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["mutation -> OperationTypeDefinition","query -> OperationTypeDefinition","subscription -> OperationTypeDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lcurly"]
				);

			} else if(this.lex.front.type == TokenType.lcurly) {
				this.lex.popFront();
				subRules = ["O"];
				if(this.firstOperationTypeDefinitions()) {
					OperationTypeDefinitions otds = this.parseOperationTypeDefinitions();
					subRules = ["O"];
					if(this.lex.front.type == TokenType.rcurly) {
						this.lex.popFront();

						return new SchemaDefinition(SchemaDefinitionEnum.O
							, otds
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["rcurly"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["mutation -> OperationTypeDefinition","query -> OperationTypeDefinition","subscription -> OperationTypeDefinition"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["at -> Directive","lcurly"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["schema"]
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
		string[] subRules;
		subRules = ["O", "OCS", "OS"];
		if(this.firstOperationTypeDefinition()) {
			OperationTypeDefinition otd = this.parseOperationTypeDefinition();
			subRules = ["OCS"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["OCS"];
				if(this.firstOperationTypeDefinitions()) {
					OperationTypeDefinitions follow = this.parseOperationTypeDefinitions();

					return new OperationTypeDefinitions(OperationTypeDefinitionsEnum.OCS
						, otd
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["mutation -> OperationTypeDefinition","query -> OperationTypeDefinition","subscription -> OperationTypeDefinition"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["mutation -> OperationType","query -> OperationType","subscription -> OperationType"]
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
		string[] subRules;
		subRules = ["O"];
		if(this.firstOperationType()) {
			OperationType ot = this.parseOperationType();
			subRules = ["O"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["O"];
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["mutation","query","subscription"]
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
		string[] subRules;
		subRules = ["D", "S"];
		if(this.lex.front.type == TokenType.scalar) {
			this.lex.popFront();
			subRules = ["D", "S"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["D"];
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
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["scalar"]
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
		string[] subRules;
		subRules = ["D", "F", "I", "ID"];
		if(this.lex.front.type == TokenType.type) {
			this.lex.popFront();
			subRules = ["D", "F", "I", "ID"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["I", "ID"];
				if(this.firstImplementsInterfaces()) {
					ImplementsInterfaces ii = this.parseImplementsInterfaces();
					subRules = ["ID"];
					if(this.firstDirectives()) {
						Directives dir = this.parseDirectives();
						subRules = ["ID"];
						if(this.lex.front.type == TokenType.lcurly) {
							this.lex.popFront();
							subRules = ["ID"];
							if(this.firstFieldDefinitions()) {
								FieldDefinitions fds = this.parseFieldDefinitions();
								subRules = ["ID"];
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
									"Found a '%s' while looking for", 
									this.lex.front
								);
								throw new ParseException(app.data,
									__FILE__, __LINE__,
									subRules,
									["rcurly"]
								);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["name -> FieldDefinition"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["lcurly"]
						);

					} else if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["I"];
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							subRules = ["I"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["rcurly"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> FieldDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["at -> Directive","lcurly"]
					);

				} else if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();
					subRules = ["D"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["D"];
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							subRules = ["D"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["rcurly"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> FieldDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["F"];
					if(this.firstFieldDefinitions()) {
						FieldDefinitions fds = this.parseFieldDefinitions();
						subRules = ["F"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new ObjectTypeDefinition(ObjectTypeDefinitionEnum.F
								, name
								, fds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["rcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> FieldDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["implements","at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["type"]
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
		string[] subRules;
		subRules = ["F", "FC", "FNC"];
		if(this.firstFieldDefinition()) {
			FieldDefinition fd = this.parseFieldDefinition();
			subRules = ["FC"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["FC"];
				if(this.firstFieldDefinitions()) {
					FieldDefinitions follow = this.parseFieldDefinitions();

					return new FieldDefinitions(FieldDefinitionsEnum.FC
						, fd
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> FieldDefinition"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["A", "AD", "D", "T"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["A", "AD"];
			if(this.firstArgumentsDefinition()) {
				ArgumentsDefinition arg = this.parseArgumentsDefinition();
				subRules = ["A", "AD"];
				if(this.lex.front.type == TokenType.colon) {
					this.lex.popFront();
					subRules = ["A", "AD"];
					if(this.firstType()) {
						Type typ = this.parseType();
						subRules = ["AD"];
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
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lbrack -> ListType","name"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["colon"]
				);

			} else if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["D", "T"];
				if(this.firstType()) {
					Type typ = this.parseType();
					subRules = ["D"];
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lbrack -> ListType","name"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["lparen","colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["N"];
		if(this.lex.front.type == TokenType.implements) {
			this.lex.popFront();
			subRules = ["N"];
			if(this.firstNamedTypes()) {
				NamedTypes nts = this.parseNamedTypes();

				return new ImplementsInterfaces(ImplementsInterfacesEnum.N
					, nts
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["implements"]
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
		string[] subRules;
		subRules = ["N", "NCS", "NS"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["NCS"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["NCS"];
				if(this.firstNamedTypes()) {
					NamedTypes follow = this.parseNamedTypes();

					return new NamedTypes(NamedTypesEnum.NCS
						, name
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["A"];
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			subRules = ["A"];
			if(this.firstInputValueDefinitions()) {
				this.parseInputValueDefinitions();
				subRules = ["A"];
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					return new ArgumentsDefinition(ArgumentsDefinitionEnum.A
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rparen"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name -> InputValueDefinition"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lparen"]
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
		string[] subRules;
		subRules = ["I", "ICF", "IF"];
		if(this.firstInputValueDefinition()) {
			InputValueDefinition iv = this.parseInputValueDefinition();
			subRules = ["ICF"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["ICF"];
				if(this.firstInputValueDefinitions()) {
					InputValueDefinitions follow = this.parseInputValueDefinitions();

					return new InputValueDefinitions(InputValueDefinitionsEnum.ICF
						, iv
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> InputValueDefinition"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["T", "TD", "TV", "TVD"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["T", "TD", "TV", "TVD"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["T", "TD", "TV", "TVD"];
				if(this.firstType()) {
					Type type = this.parseType();
					subRules = ["TV", "TVD"];
					if(this.firstDefaultValue()) {
						DefaultValue df = this.parseDefaultValue();
						subRules = ["TVD"];
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
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lbrack -> ListType","name"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["colon"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["NDF", "NF"];
		if(this.lex.front.type == TokenType.interface_) {
			this.lex.popFront();
			subRules = ["NDF", "NF"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["NDF"];
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					subRules = ["NDF"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDF"];
						if(this.firstFieldDefinitions()) {
							FieldDefinitions fds = this.parseFieldDefinitions();
							subRules = ["NDF"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["rcurly"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> FieldDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["NF"];
					if(this.firstFieldDefinitions()) {
						FieldDefinitions fds = this.parseFieldDefinitions();
						subRules = ["NF"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new InterfaceTypeDefinition(InterfaceTypeDefinitionEnum.NF
								, name
								, fds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["rcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> FieldDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["interface_"]
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
		string[] subRules;
		subRules = ["NDU", "NU"];
		if(this.lex.front.type == TokenType.union_) {
			this.lex.popFront();
			subRules = ["NDU", "NU"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["NDU"];
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					subRules = ["NDU"];
					if(this.lex.front.type == TokenType.equal) {
						this.lex.popFront();
						subRules = ["NDU"];
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
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["equal"]
					);

				} else if(this.lex.front.type == TokenType.equal) {
					this.lex.popFront();
					subRules = ["NU"];
					if(this.firstUnionMembers()) {
						UnionMembers um = this.parseUnionMembers();

						return new UnionTypeDefinition(UnionTypeDefinitionEnum.NU
							, name
							, um
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","equal"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["union_"]
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
		string[] subRules;
		subRules = ["S", "SF", "SPF"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["SPF"];
			if(this.lex.front.type == TokenType.pipe) {
				this.lex.popFront();
				subRules = ["SPF"];
				if(this.firstUnionMembers()) {
					UnionMembers follow = this.parseUnionMembers();

					return new UnionMembers(UnionMembersEnum.SPF
						, name
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["NDE", "NE"];
		if(this.lex.front.type == TokenType.enum_) {
			this.lex.popFront();
			subRules = ["NDE", "NE"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["NDE"];
				if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();
					subRules = ["NDE"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDE"];
						if(this.firstEnumValueDefinitions()) {
							EnumValueDefinitions evds = this.parseEnumValueDefinitions();
							subRules = ["NDE"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["rcurly"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> EnumValueDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["NE"];
					if(this.firstEnumValueDefinitions()) {
						EnumValueDefinitions evds = this.parseEnumValueDefinitions();
						subRules = ["NE"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new EnumTypeDefinition(EnumTypeDefinitionEnum.NE
								, name
								, evds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["rcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> EnumValueDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["enum_"]
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
		string[] subRules;
		subRules = ["D", "DCE", "DE"];
		if(this.firstEnumValueDefinition()) {
			EnumValueDefinition evd = this.parseEnumValueDefinition();
			subRules = ["DCE"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["DCE"];
				if(this.firstEnumValueDefinitions()) {
					EnumValueDefinitions follow = this.parseEnumValueDefinitions();

					return new EnumValueDefinitions(EnumValueDefinitionsEnum.DCE
						, evd
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> EnumValueDefinition"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["E", "ED"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["ED"];
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["NDE", "NE"];
		if(this.lex.front.type == TokenType.input) {
			this.lex.popFront();
			subRules = ["NDE", "NE"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["NDE"];
				if(this.firstDirectives()) {
					Directives dir = this.parseDirectives();
					subRules = ["NDE"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDE"];
						if(this.firstInputValueDefinitions()) {
							InputValueDefinitions ivds = this.parseInputValueDefinitions();
							subRules = ["NDE"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["rcurly"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> InputValueDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["NE"];
					if(this.firstInputValueDefinitions()) {
						InputValueDefinitions ivds = this.parseInputValueDefinitions();
						subRules = ["NE"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new InputTypeDefinition(InputTypeDefinitionEnum.NE
								, name
								, ivds
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["rcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> InputValueDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["input"]
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
		string[] subRules;
		subRules = ["O"];
		if(this.lex.front.type == TokenType.extend) {
			this.lex.popFront();
			subRules = ["O"];
			if(this.firstObjectTypeDefinition()) {
				ObjectTypeDefinition otd = this.parseObjectTypeDefinition();

				return new TypeExtensionDefinition(TypeExtensionDefinitionEnum.O
					, otd
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["type"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["extend"]
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
		string[] subRules;
		subRules = ["AD", "D"];
		if(this.lex.front.type == TokenType.directive) {
			this.lex.popFront();
			subRules = ["AD", "D"];
			if(this.lex.front.type == TokenType.at) {
				this.lex.popFront();
				subRules = ["AD", "D"];
				if(this.lex.front.type == TokenType.name) {
					Token name = this.lex.front;
					this.lex.popFront();
					subRules = ["AD"];
					if(this.firstArgumentsDefinition()) {
						ArgumentsDefinition ad = this.parseArgumentsDefinition();
						subRules = ["AD"];
						if(this.lex.front.type == TokenType.on_) {
							this.lex.popFront();
							subRules = ["AD"];
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
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["name"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["on_"]
						);

					} else if(this.lex.front.type == TokenType.on_) {
						this.lex.popFront();
						subRules = ["D"];
						if(this.firstDirectiveLocations()) {
							DirectiveLocations dl = this.parseDirectiveLocations();

							return new DirectiveDefinition(DirectiveDefinitionEnum.D
								, name
								, dl
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lparen","on_"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["at"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["directive"]
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
		string[] subRules;
		subRules = ["N", "NF", "NPF"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["NPF"];
			if(this.lex.front.type == TokenType.pipe) {
				this.lex.popFront();
				subRules = ["NPF"];
				if(this.firstDirectiveLocations()) {
					DirectiveLocations follow = this.parseDirectiveLocations();

					return new DirectiveLocations(DirectiveLocationsEnum.NPF
						, name
						, follow
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
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
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
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
		string[] subRules;
		subRules = ["NDI", "NI"];
		if(this.lex.front.type == TokenType.input) {
			this.lex.popFront();
			subRules = ["NDI", "NI"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["NDI"];
				if(this.firstDirectives()) {
					Directives dirs = this.parseDirectives();
					subRules = ["NDI"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDI"];
						if(this.firstInputValueDefinitions()) {
							this.parseInputValueDefinitions();
							subRules = ["NDI"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								return new InputObjectTypeDefinition(InputObjectTypeDefinitionEnum.NDI
									, name
									, dirs
								);
							}
							auto app = appender!string();
							formattedWrite(app, 
								"Found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["rcurly"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> InputValueDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["NI"];
					if(this.firstInputValueDefinitions()) {
						this.parseInputValueDefinitions();
						subRules = ["NI"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							return new InputObjectTypeDefinition(InputObjectTypeDefinitionEnum.NI
								, name
							);
						}
						auto app = appender!string();
						formattedWrite(app, 
							"Found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["rcurly"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"Found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> InputValueDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"Found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","lcurly"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"Found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"Found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["input"]
		);

	}

}
