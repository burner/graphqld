module graphql.parser;

import std.array : appender;
import std.format : formattedWrite;
import std.format : format;

import graphql.ast;
import graphql.tokenmodule;

import graphql.lexer;

import graphql.exception;

struct Parser {
@safe :

	Document[] documents;
	Definitions[] definitionss;
	Definition[] definitions;
	OperationDefinition[] operationDefinitions;
	SelectionSet[] selectionSets;
	OperationType[] operationTypes;
	Selections[] selectionss;
	Selection[] selections;
	FragmentSpread[] fragmentSpreads;
	InlineFragment[] inlineFragments;
	Field[] fields;
	FieldName[] fieldNames;
	Arguments[] argumentss;
	ArgumentList[] argumentLists;
	Argument[] arguments;
	FragmentDefinition[] fragmentDefinitions;
	Directives[] directivess;
	Directive[] directives;
	VariableDefinitions[] variableDefinitionss;
	VariableDefinitionList[] variableDefinitionLists;
	VariableDefinition[] variableDefinitions;
	Variable[] variables;
	DefaultValue[] defaultValues;
	ValueOrVariable[] valueOrVariables;
	Value[] values;
	Type[] types;
	ListType[] listTypes;
	Values[] valuess;
	Array[] arrays;
	ObjectValues[] objectValuess;
	ObjectType[] objectTypes;
	TypeSystemDefinition[] typeSystemDefinitions;
	TypeDefinition[] typeDefinitions;
	SchemaDefinition[] schemaDefinitions;
	OperationTypeDefinitions[] operationTypeDefinitionss;
	OperationTypeDefinition[] operationTypeDefinitions;
	ScalarTypeDefinition[] scalarTypeDefinitions;
	ObjectTypeDefinition[] objectTypeDefinitions;
	FieldDefinitions[] fieldDefinitionss;
	FieldDefinition[] fieldDefinitions;
	ImplementsInterfaces[] implementsInterfacess;
	NamedTypes[] namedTypess;
	ArgumentsDefinition[] argumentsDefinitions;
	InputValueDefinitions[] inputValueDefinitionss;
	InputValueDefinition[] inputValueDefinitions;
	InterfaceTypeDefinition[] interfaceTypeDefinitions;
	UnionTypeDefinition[] unionTypeDefinitions;
	UnionMembers[] unionMemberss;
	EnumTypeDefinition[] enumTypeDefinitions;
	EnumValueDefinitions[] enumValueDefinitionss;
	EnumValueDefinition[] enumValueDefinitions;
	InputTypeDefinition[] inputTypeDefinitions;
	TypeExtensionDefinition[] typeExtensionDefinitions;
	DirectiveDefinition[] directiveDefinitions;
	DirectiveLocations[] directiveLocationss;
	InputObjectTypeDefinition[] inputObjectTypeDefinitions;
	Description[] descriptions;
	Lexer lex;

	this(Lexer lex) {
		this.lex = lex;
	}

	bool firstDocument() const pure @nogc @safe {
		return this.firstDefinitions();
	}

	uint parseDocument() {
		try {
			return this.parseDocumentImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Document an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDocumentImpl() {
		string[] subRules;
		subRules = ["Defi"];
		if(this.firstDefinitions()) {
			uint defs = this.parseDefinitions();

			this.documents ~= Document.ConstructDefi(defs);
			return cast(uint)(this.documents.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Document' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["directive -> Definition","enum_ -> Definition","extend -> Definition","fragment -> Definition","input -> Definition","interface_ -> Definition","lcurly -> Definition","mutation -> Definition","query -> Definition","scalar -> Definition","schema -> Definition","stringValue -> Definition","subscription -> Definition","type -> Definition","union_ -> Definition"]
		);

	}

	bool firstDefinitions() const pure @nogc @safe {
		return this.firstDefinition();
	}

	uint parseDefinitions() {
		try {
			return this.parseDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Definitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDefinitionsImpl() {
		string[] subRules;
		subRules = ["Def", "Defs"];
		if(this.firstDefinition()) {
			uint def = this.parseDefinition();
			subRules = ["Defs"];
			if(this.firstDefinitions()) {
				uint follow = this.parseDefinitions();

				this.definitionss ~= Definitions.ConstructDefs(def, follow);
				return cast(uint)(this.definitionss.length - 1);

			}
			this.definitionss ~= Definitions.ConstructDef(def);
			return cast(uint)(this.definitionss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Definitions' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["directive -> TypeSystemDefinition","enum_ -> TypeSystemDefinition","extend -> TypeSystemDefinition","fragment -> FragmentDefinition","input -> TypeSystemDefinition","interface_ -> TypeSystemDefinition","lcurly -> OperationDefinition","mutation -> OperationDefinition","query -> OperationDefinition","scalar -> TypeSystemDefinition","schema -> TypeSystemDefinition","stringValue -> TypeSystemDefinition","subscription -> OperationDefinition","type -> TypeSystemDefinition","union_ -> TypeSystemDefinition"]
		);

	}

	bool firstDefinition() const pure @nogc @safe {
		return this.firstOperationDefinition()
			 || this.firstFragmentDefinition()
			 || this.firstTypeSystemDefinition();
	}

	uint parseDefinition() {
		try {
			return this.parseDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Definition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDefinitionImpl() {
		string[] subRules;
		subRules = ["O"];
		if(this.firstOperationDefinition()) {
			uint op = this.parseOperationDefinition();

			this.definitions ~= Definition.ConstructO(op);
			return cast(uint)(this.definitions.length - 1);

		} else if(this.firstFragmentDefinition()) {
			uint frag = this.parseFragmentDefinition();

			this.definitions ~= Definition.ConstructF(frag);
			return cast(uint)(this.definitions.length - 1);

		} else if(this.firstTypeSystemDefinition()) {
			uint type = this.parseTypeSystemDefinition();

			this.definitions ~= Definition.ConstructT(type);
			return cast(uint)(this.definitions.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Definition' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lcurly -> SelectionSet","mutation -> OperationType","query -> OperationType","subscription -> OperationType","fragment","directive -> DirectiveDefinition","enum_ -> TypeDefinition","extend -> TypeExtensionDefinition","input -> TypeDefinition","interface_ -> TypeDefinition","scalar -> TypeDefinition","schema -> SchemaDefinition","stringValue -> Description","type -> TypeDefinition","union_ -> TypeDefinition"]
		);

	}

	bool firstOperationDefinition() const pure @nogc @safe {
		return this.firstSelectionSet()
			 || this.firstOperationType();
	}

	uint parseOperationDefinition() {
		try {
			return this.parseOperationDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseOperationDefinitionImpl() {
		string[] subRules;
		subRules = ["SelSet"];
		if(this.firstSelectionSet()) {
			uint ss = this.parseSelectionSet();

			this.operationDefinitions ~= OperationDefinition.ConstructSelSet(ss);
			return cast(uint)(this.operationDefinitions.length - 1);

		} else if(this.firstOperationType()) {
			uint ot = this.parseOperationType();
			subRules = ["OT_N", "OT_N_D", "OT_N_V", "OT_N_VD"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["OT_N_V", "OT_N_VD"];
				if(this.firstVariableDefinitions()) {
					uint vd = this.parseVariableDefinitions();
					subRules = ["OT_N_VD"];
					if(this.firstDirectives()) {
						uint d = this.parseDirectives();
						subRules = ["OT_N_VD"];
						if(this.firstSelectionSet()) {
							uint ss = this.parseSelectionSet();

							this.operationDefinitions ~= OperationDefinition.ConstructOT_N_VD(ot, name, vd, d, ss);
							return cast(uint)(this.operationDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'OperationDefinition' found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["lcurly"]
						);

					} else if(this.firstSelectionSet()) {
						uint ss = this.parseSelectionSet();

						this.operationDefinitions ~= OperationDefinition.ConstructOT_N_V(ot, name, vd, ss);
						return cast(uint)(this.operationDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'OperationDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["at -> Directive","lcurly"]
					);

				} else if(this.firstDirectives()) {
					uint d = this.parseDirectives();
					subRules = ["OT_N_D"];
					if(this.firstSelectionSet()) {
						uint ss = this.parseSelectionSet();

						this.operationDefinitions ~= OperationDefinition.ConstructOT_N_D(ot, name, d, ss);
						return cast(uint)(this.operationDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'OperationDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.firstSelectionSet()) {
					uint ss = this.parseSelectionSet();

					this.operationDefinitions ~= OperationDefinition.ConstructOT_N(ot, name, ss);
					return cast(uint)(this.operationDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'OperationDefinition' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lparen","at -> Directive","lcurly"]
				);

			} else if(this.firstVariableDefinitions()) {
				uint vd = this.parseVariableDefinitions();
				subRules = ["OT_VD"];
				if(this.firstDirectives()) {
					uint d = this.parseDirectives();
					subRules = ["OT_VD"];
					if(this.firstSelectionSet()) {
						uint ss = this.parseSelectionSet();

						this.operationDefinitions ~= OperationDefinition.ConstructOT_VD(ot, vd, d, ss);
						return cast(uint)(this.operationDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'OperationDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.firstSelectionSet()) {
					uint ss = this.parseSelectionSet();

					this.operationDefinitions ~= OperationDefinition.ConstructOT_V(ot, vd, ss);
					return cast(uint)(this.operationDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'OperationDefinition' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["at -> Directive","lcurly"]
				);

			} else if(this.firstDirectives()) {
				uint d = this.parseDirectives();
				subRules = ["OT_D"];
				if(this.firstSelectionSet()) {
					uint ss = this.parseSelectionSet();

					this.operationDefinitions ~= OperationDefinition.ConstructOT_D(ot, d, ss);
					return cast(uint)(this.operationDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'OperationDefinition' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["lcurly"]
				);

			} else if(this.firstSelectionSet()) {
				uint ss = this.parseSelectionSet();

				this.operationDefinitions ~= OperationDefinition.ConstructOT(ot, ss);
				return cast(uint)(this.operationDefinitions.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'OperationDefinition' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name","lparen","at -> Directive","lcurly"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'OperationDefinition' found a '%s' while looking for", 
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

	uint parseSelectionSet() {
		try {
			return this.parseSelectionSetImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a SelectionSet an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseSelectionSetImpl() {
		string[] subRules;
		subRules = ["SS"];
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			subRules = ["SS"];
			if(this.firstSelections()) {
				uint sel = this.parseSelections();
				subRules = ["SS"];
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					this.selectionSets ~= SelectionSet.ConstructSS(sel);
					return cast(uint)(this.selectionSets.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'SelectionSet' found a '%s' while looking for", 
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
				"In 'SelectionSet' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["dots -> Selection","name -> Selection"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'SelectionSet' found a '%s' while looking for", 
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

	uint parseOperationType() {
		try {
			return this.parseOperationTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseOperationTypeImpl() {
		string[] subRules;
		subRules = ["Query"];
		if(this.lex.front.type == TokenType.query) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.operationTypes ~= OperationType.ConstructQuery(tok);
			return cast(uint)(this.operationTypes.length - 1);

		} else if(this.lex.front.type == TokenType.mutation) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.operationTypes ~= OperationType.ConstructMutation(tok);
			return cast(uint)(this.operationTypes.length - 1);

		} else if(this.lex.front.type == TokenType.subscription) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.operationTypes ~= OperationType.ConstructSub(tok);
			return cast(uint)(this.operationTypes.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'OperationType' found a '%s' while looking for", 
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

	uint parseSelections() {
		try {
			return this.parseSelectionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Selections an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseSelectionsImpl() {
		string[] subRules;
		subRules = ["Sel", "Sels", "Selsc"];
		if(this.firstSelection()) {
			uint sel = this.parseSelection();
			subRules = ["Sels"];
			if(this.firstSelections()) {
				uint follow = this.parseSelections();

				this.selectionss ~= Selections.ConstructSels(sel, follow);
				return cast(uint)(this.selectionss.length - 1);

			} else if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["Selsc"];
				if(this.firstSelections()) {
					uint follow = this.parseSelections();

					this.selectionss ~= Selections.ConstructSelsc(sel, follow);
					return cast(uint)(this.selectionss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'Selections' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dots -> Selection","name -> Selection"]
				);

			}
			this.selectionss ~= Selections.ConstructSel(sel);
			return cast(uint)(this.selectionss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Selections' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["dots","name -> Field"]
		);

	}

	bool firstSelection() const pure @nogc @safe {
		return this.firstField()
			 || this.lex.front.type == TokenType.dots;
	}

	uint parseSelection() {
		try {
			return this.parseSelectionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Selection an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseSelectionImpl() {
		string[] subRules;
		subRules = ["Field"];
		if(this.firstField()) {
			uint field = this.parseField();

			this.selections ~= Selection.ConstructField(field);
			return cast(uint)(this.selections.length - 1);

		} else if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			subRules = ["Spread"];
			if(this.firstFragmentSpread()) {
				uint frag = this.parseFragmentSpread();

				this.selections ~= Selection.ConstructSpread(frag);
				return cast(uint)(this.selections.length - 1);

			} else if(this.firstInlineFragment()) {
				uint ifrag = this.parseInlineFragment();

				this.selections ~= Selection.ConstructIFrag(ifrag);
				return cast(uint)(this.selections.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Selection' found a '%s' while looking for", 
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
			"In 'Selection' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name -> FieldName","dots"]
		);

	}

	bool firstFragmentSpread() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	uint parseFragmentSpread() {
		try {
			return this.parseFragmentSpreadImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FragmentSpread an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseFragmentSpreadImpl() {
		string[] subRules;
		subRules = ["F", "FD"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["FD"];
			if(this.firstDirectives()) {
				uint dirs = this.parseDirectives();

				this.fragmentSpreads ~= FragmentSpread.ConstructFD(name, dirs);
				return cast(uint)(this.fragmentSpreads.length - 1);

			}
			this.fragmentSpreads ~= FragmentSpread.ConstructF(name);
			return cast(uint)(this.fragmentSpreads.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'FragmentSpread' found a '%s' while looking for", 
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

	uint parseInlineFragment() {
		try {
			return this.parseInlineFragmentImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InlineFragment an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseInlineFragmentImpl() {
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
					uint dirs = this.parseDirectives();
					subRules = ["TDS"];
					if(this.firstSelectionSet()) {
						uint ss = this.parseSelectionSet();

						this.inlineFragments ~= InlineFragment.ConstructTDS(tc, dirs, ss);
						return cast(uint)(this.inlineFragments.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'InlineFragment' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["lcurly"]
					);

				} else if(this.firstSelectionSet()) {
					uint ss = this.parseSelectionSet();

					this.inlineFragments ~= InlineFragment.ConstructTS(tc, ss);
					return cast(uint)(this.inlineFragments.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'InlineFragment' found a '%s' while looking for", 
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
				"In 'InlineFragment' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name"]
			);

		} else if(this.firstDirectives()) {
			uint dirs = this.parseDirectives();
			subRules = ["DS"];
			if(this.firstSelectionSet()) {
				uint ss = this.parseSelectionSet();

				this.inlineFragments ~= InlineFragment.ConstructDS(dirs, ss);
				return cast(uint)(this.inlineFragments.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'InlineFragment' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["lcurly"]
			);

		} else if(this.firstSelectionSet()) {
			uint ss = this.parseSelectionSet();

			this.inlineFragments ~= InlineFragment.ConstructS(ss);
			return cast(uint)(this.inlineFragments.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'InlineFragment' found a '%s' while looking for", 
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

	uint parseField() {
		try {
			return this.parseFieldImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Field an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseFieldImpl() {
		string[] subRules;
		subRules = ["F", "FA", "FAD", "FADS", "FAS", "FD", "FDS", "FS"];
		if(this.firstFieldName()) {
			uint name = this.parseFieldName();
			subRules = ["FA", "FAD", "FADS", "FAS"];
			if(this.firstArguments()) {
				uint args = this.parseArguments();
				subRules = ["FAD", "FADS"];
				if(this.firstDirectives()) {
					uint dirs = this.parseDirectives();
					subRules = ["FADS"];
					if(this.firstSelectionSet()) {
						uint ss = this.parseSelectionSet();

						this.fields ~= Field.ConstructFADS(name, args, dirs, ss);
						return cast(uint)(this.fields.length - 1);

					}
					this.fields ~= Field.ConstructFAD(name, args, dirs);
					return cast(uint)(this.fields.length - 1);

				} else if(this.firstSelectionSet()) {
					uint ss = this.parseSelectionSet();

					this.fields ~= Field.ConstructFAS(name, args, ss);
					return cast(uint)(this.fields.length - 1);

				}
				this.fields ~= Field.ConstructFA(name, args);
				return cast(uint)(this.fields.length - 1);

			} else if(this.firstDirectives()) {
				uint dirs = this.parseDirectives();
				subRules = ["FDS"];
				if(this.firstSelectionSet()) {
					uint ss = this.parseSelectionSet();

					this.fields ~= Field.ConstructFDS(name, dirs, ss);
					return cast(uint)(this.fields.length - 1);

				}
				this.fields ~= Field.ConstructFD(name, dirs);
				return cast(uint)(this.fields.length - 1);

			} else if(this.firstSelectionSet()) {
				uint ss = this.parseSelectionSet();

				this.fields ~= Field.ConstructFS(name, ss);
				return cast(uint)(this.fields.length - 1);

			}
			this.fields ~= Field.ConstructF(name);
			return cast(uint)(this.fields.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Field' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
		);

	}

	bool firstFieldName() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name;
	}

	uint parseFieldName() {
		try {
			return this.parseFieldNameImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FieldName an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseFieldNameImpl() {
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

					this.fieldNames ~= FieldName.ConstructA(name, aka);
					return cast(uint)(this.fieldNames.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'FieldName' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
				);

			}
			this.fieldNames ~= FieldName.ConstructN(name);
			return cast(uint)(this.fieldNames.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'FieldName' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name"]
		);

	}

	bool firstArguments() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lparen;
	}

	uint parseArguments() {
		try {
			return this.parseArgumentsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Arguments an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseArgumentsImpl() {
		string[] subRules;
		subRules = ["Empty", "List"];
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			subRules = ["List"];
			if(this.firstArgumentList()) {
				uint arg = this.parseArgumentList();
				subRules = ["List"];
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					this.argumentss ~= Arguments.ConstructList(arg);
					return cast(uint)(this.argumentss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'Arguments' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rparen"]
				);

			} else if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				this.argumentss ~= Arguments.ConstructEmpty();
				return cast(uint)(this.argumentss.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Arguments' found a '%s' while looking for", 
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
			"In 'Arguments' found a '%s' while looking for", 
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

	uint parseArgumentList() {
		try {
			return this.parseArgumentListImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ArgumentList an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseArgumentListImpl() {
		string[] subRules;
		subRules = ["A", "ACS", "AS"];
		if(this.firstArgument()) {
			uint arg = this.parseArgument();
			subRules = ["ACS"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["ACS"];
				if(this.firstArgumentList()) {
					uint follow = this.parseArgumentList();

					this.argumentLists ~= ArgumentList.ConstructACS(arg, follow);
					return cast(uint)(this.argumentLists.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'ArgumentList' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> Argument"]
				);

			} else if(this.firstArgumentList()) {
				uint follow = this.parseArgumentList();

				this.argumentLists ~= ArgumentList.ConstructAS(arg, follow);
				return cast(uint)(this.argumentLists.length - 1);

			}
			this.argumentLists ~= ArgumentList.ConstructA(arg);
			return cast(uint)(this.argumentLists.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'ArgumentList' found a '%s' while looking for", 
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

	uint parseArgument() {
		try {
			return this.parseArgumentImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Argument an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseArgumentImpl() {
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
					uint vv = this.parseValueOrVariable();

					this.arguments ~= Argument.ConstructName(name, vv);
					return cast(uint)(this.arguments.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'Argument' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dollar -> Variable","false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","name -> Value","null_ -> Value","stringValue -> Value","true_ -> Value"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Argument' found a '%s' while looking for", 
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
			"In 'Argument' found a '%s' while looking for", 
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

	uint parseFragmentDefinition() {
		try {
			return this.parseFragmentDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FragmentDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseFragmentDefinitionImpl() {
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
							uint dirs = this.parseDirectives();
							subRules = ["FTDS"];
							if(this.firstSelectionSet()) {
								uint ss = this.parseSelectionSet();

								this.fragmentDefinitions ~= FragmentDefinition.ConstructFTDS(name, tc, dirs, ss);
								return cast(uint)(this.fragmentDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'FragmentDefinition' found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["lcurly"]
							);

						} else if(this.firstSelectionSet()) {
							uint ss = this.parseSelectionSet();

							this.fragmentDefinitions ~= FragmentDefinition.ConstructFTS(name, tc, ss);
							return cast(uint)(this.fragmentDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'FragmentDefinition' found a '%s' while looking for", 
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
						"In 'FragmentDefinition' found a '%s' while looking for", 
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
					"In 'FragmentDefinition' found a '%s' while looking for", 
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
				"In 'FragmentDefinition' found a '%s' while looking for", 
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
			"In 'FragmentDefinition' found a '%s' while looking for", 
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

	uint parseDirectives() {
		try {
			return this.parseDirectivesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Directives an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDirectivesImpl() {
		string[] subRules;
		subRules = ["Dir", "Dirs"];
		if(this.firstDirective()) {
			uint dir = this.parseDirective();
			subRules = ["Dirs"];
			if(this.firstDirectives()) {
				uint follow = this.parseDirectives();

				this.directivess ~= Directives.ConstructDirs(dir, follow);
				return cast(uint)(this.directivess.length - 1);

			}
			this.directivess ~= Directives.ConstructDir(dir);
			return cast(uint)(this.directivess.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Directives' found a '%s' while looking for", 
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

	uint parseDirective() {
		try {
			return this.parseDirectiveImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Directive an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDirectiveImpl() {
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
					uint arg = this.parseArguments();

					this.directives ~= Directive.ConstructNArg(name, arg);
					return cast(uint)(this.directives.length - 1);

				}
				this.directives ~= Directive.ConstructN(name);
				return cast(uint)(this.directives.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Directive' found a '%s' while looking for", 
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
			"In 'Directive' found a '%s' while looking for", 
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

	uint parseVariableDefinitions() {
		try {
			return this.parseVariableDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a VariableDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseVariableDefinitionsImpl() {
		string[] subRules;
		subRules = ["Empty", "Vars"];
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			subRules = ["Empty"];
			if(this.lex.front.type == TokenType.rparen) {
				this.lex.popFront();

				this.variableDefinitionss ~= VariableDefinitions.ConstructEmpty();
				return cast(uint)(this.variableDefinitionss.length - 1);

			} else if(this.firstVariableDefinitionList()) {
				uint vars = this.parseVariableDefinitionList();
				subRules = ["Vars"];
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					this.variableDefinitionss ~= VariableDefinitions.ConstructVars(vars);
					return cast(uint)(this.variableDefinitionss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'VariableDefinitions' found a '%s' while looking for", 
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
				"In 'VariableDefinitions' found a '%s' while looking for", 
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
			"In 'VariableDefinitions' found a '%s' while looking for", 
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

	uint parseVariableDefinitionList() {
		try {
			return this.parseVariableDefinitionListImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a VariableDefinitionList an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseVariableDefinitionListImpl() {
		string[] subRules;
		subRules = ["V", "VCF", "VF"];
		if(this.firstVariableDefinition()) {
			uint var = this.parseVariableDefinition();
			subRules = ["VCF"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["VCF"];
				if(this.firstVariableDefinitionList()) {
					uint follow = this.parseVariableDefinitionList();

					this.variableDefinitionLists ~= VariableDefinitionList.ConstructVCF(var, follow);
					return cast(uint)(this.variableDefinitionLists.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'VariableDefinitionList' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dollar -> VariableDefinition"]
				);

			} else if(this.firstVariableDefinitionList()) {
				uint follow = this.parseVariableDefinitionList();

				this.variableDefinitionLists ~= VariableDefinitionList.ConstructVF(var, follow);
				return cast(uint)(this.variableDefinitionLists.length - 1);

			}
			this.variableDefinitionLists ~= VariableDefinitionList.ConstructV(var);
			return cast(uint)(this.variableDefinitionLists.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'VariableDefinitionList' found a '%s' while looking for", 
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

	uint parseVariableDefinition() {
		try {
			return this.parseVariableDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a VariableDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseVariableDefinitionImpl() {
		string[] subRules;
		subRules = ["Var", "VarD"];
		if(this.firstVariable()) {
			uint var = this.parseVariable();
			subRules = ["Var", "VarD"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["Var", "VarD"];
				if(this.firstType()) {
					uint type = this.parseType();
					subRules = ["VarD"];
					if(this.firstDefaultValue()) {
						uint dvalue = this.parseDefaultValue();

						this.variableDefinitions ~= VariableDefinition.ConstructVarD(var, type, dvalue);
						return cast(uint)(this.variableDefinitions.length - 1);

					}
					this.variableDefinitions ~= VariableDefinition.ConstructVar(var, type);
					return cast(uint)(this.variableDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'VariableDefinition' found a '%s' while looking for", 
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
				"In 'VariableDefinition' found a '%s' while looking for", 
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
			"In 'VariableDefinition' found a '%s' while looking for", 
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

	uint parseVariable() {
		try {
			return this.parseVariableImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Variable an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseVariableImpl() {
		string[] subRules;
		subRules = ["Var"];
		if(this.lex.front.type == TokenType.dollar) {
			this.lex.popFront();
			subRules = ["Var"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();

				this.variables ~= Variable.ConstructVar(name);
				return cast(uint)(this.variables.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Variable' found a '%s' while looking for", 
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
			"In 'Variable' found a '%s' while looking for", 
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

	uint parseDefaultValue() {
		try {
			return this.parseDefaultValueImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a DefaultValue an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDefaultValueImpl() {
		string[] subRules;
		subRules = ["DV"];
		if(this.lex.front.type == TokenType.equal) {
			this.lex.popFront();
			subRules = ["DV"];
			if(this.firstValue()) {
				uint value = this.parseValue();

				this.defaultValues ~= DefaultValue.ConstructDV(value);
				return cast(uint)(this.defaultValues.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'DefaultValue' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","name","null_","stringValue","true_"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'DefaultValue' found a '%s' while looking for", 
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

	uint parseValueOrVariable() {
		try {
			return this.parseValueOrVariableImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ValueOrVariable an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseValueOrVariableImpl() {
		string[] subRules;
		subRules = ["Val"];
		if(this.firstValue()) {
			uint val = this.parseValue();

			this.valueOrVariables ~= ValueOrVariable.ConstructVal(val);
			return cast(uint)(this.valueOrVariables.length - 1);

		} else if(this.firstVariable()) {
			uint var = this.parseVariable();

			this.valueOrVariables ~= ValueOrVariable.ConstructVar(var);
			return cast(uint)(this.valueOrVariables.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'ValueOrVariable' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","name","null_","stringValue","true_","dollar"]
		);

	}

	bool firstValue() const pure @nogc @safe {
		return this.lex.front.type == TokenType.stringValue
			 || this.lex.front.type == TokenType.intValue
			 || this.lex.front.type == TokenType.floatValue
			 || this.lex.front.type == TokenType.true_
			 || this.lex.front.type == TokenType.false_
			 || this.firstArray()
			 || this.firstObjectType()
			 || this.lex.front.type == TokenType.name
			 || this.lex.front.type == TokenType.null_;
	}

	uint parseValue() {
		try {
			return this.parseValueImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Value an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseValueImpl() {
		string[] subRules;
		subRules = ["STR"];
		if(this.lex.front.type == TokenType.stringValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructSTR(tok);
			return cast(uint)(this.values.length - 1);

		} else if(this.lex.front.type == TokenType.intValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructINT(tok);
			return cast(uint)(this.values.length - 1);

		} else if(this.lex.front.type == TokenType.floatValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructFLOAT(tok);
			return cast(uint)(this.values.length - 1);

		} else if(this.lex.front.type == TokenType.true_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructT(tok);
			return cast(uint)(this.values.length - 1);

		} else if(this.lex.front.type == TokenType.false_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructF(tok);
			return cast(uint)(this.values.length - 1);

		} else if(this.firstArray()) {
			uint arr = this.parseArray();

			this.values ~= Value.ConstructARR(arr);
			return cast(uint)(this.values.length - 1);

		} else if(this.firstObjectType()) {
			uint obj = this.parseObjectType();

			this.values ~= Value.ConstructO(obj);
			return cast(uint)(this.values.length - 1);

		} else if(this.lex.front.type == TokenType.name) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructE(tok);
			return cast(uint)(this.values.length - 1);

		} else if(this.lex.front.type == TokenType.null_) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.values ~= Value.ConstructN(tok);
			return cast(uint)(this.values.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Value' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["stringValue","intValue","floatValue","true_","false_","lbrack","lcurly","name","null_"]
		);

	}

	bool firstType() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name
			 || this.firstListType();
	}

	uint parseType() {
		try {
			return this.parseTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Type an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseTypeImpl() {
		string[] subRules;
		subRules = ["T", "TN"];
		if(this.lex.front.type == TokenType.name) {
			Token tname = this.lex.front;
			this.lex.popFront();
			subRules = ["TN"];
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();

				this.types ~= Type.ConstructTN(tname);
				return cast(uint)(this.types.length - 1);

			}
			this.types ~= Type.ConstructT(tname);
			return cast(uint)(this.types.length - 1);

		} else if(this.firstListType()) {
			uint list = this.parseListType();
			subRules = ["LN"];
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();

				this.types ~= Type.ConstructLN(list);
				return cast(uint)(this.types.length - 1);

			}
			this.types ~= Type.ConstructL(list);
			return cast(uint)(this.types.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Type' found a '%s' while looking for", 
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

	uint parseListType() {
		try {
			return this.parseListTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ListType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseListTypeImpl() {
		string[] subRules;
		subRules = ["T"];
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			subRules = ["T"];
			if(this.firstType()) {
				uint type = this.parseType();
				subRules = ["T"];
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					this.listTypes ~= ListType.ConstructT(type);
					return cast(uint)(this.listTypes.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'ListType' found a '%s' while looking for", 
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
				"In 'ListType' found a '%s' while looking for", 
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
			"In 'ListType' found a '%s' while looking for", 
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

	uint parseValues() {
		try {
			return this.parseValuesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Values an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseValuesImpl() {
		string[] subRules;
		subRules = ["Val", "Vals"];
		if(this.firstValue()) {
			uint val = this.parseValue();
			subRules = ["Vals"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["Vals"];
				if(this.firstValues()) {
					uint follow = this.parseValues();

					this.valuess ~= Values.ConstructVals(val, follow);
					return cast(uint)(this.valuess.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'Values' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","name -> Value","null_ -> Value","stringValue -> Value","true_ -> Value"]
				);

			}
			this.valuess ~= Values.ConstructVal(val);
			return cast(uint)(this.valuess.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Values' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["false_","floatValue","intValue","lbrack -> Array","lcurly -> ObjectType","name","null_","stringValue","true_"]
		);

	}

	bool firstArray() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lbrack;
	}

	uint parseArray() {
		try {
			return this.parseArrayImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Array an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseArrayImpl() {
		string[] subRules;
		subRules = ["Empty", "Value"];
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			subRules = ["Empty"];
			if(this.lex.front.type == TokenType.rbrack) {
				this.lex.popFront();

				this.arrays ~= Array.ConstructEmpty();
				return cast(uint)(this.arrays.length - 1);

			} else if(this.firstValues()) {
				uint vals = this.parseValues();
				subRules = ["Value"];
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();

					this.arrays ~= Array.ConstructValue(vals);
					return cast(uint)(this.arrays.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'Array' found a '%s' while looking for", 
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
				"In 'Array' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["rbrack","false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","name -> Value","null_ -> Value","stringValue -> Value","true_ -> Value"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Array' found a '%s' while looking for", 
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

	uint parseObjectValues() {
		try {
			return this.parseObjectValuesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectValues an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseObjectValuesImpl() {
		string[] subRules;
		subRules = ["V", "Vs", "Vsc"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["V", "Vs", "Vsc"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["V", "Vs", "Vsc"];
				if(this.firstValueOrVariable()) {
					uint val = this.parseValueOrVariable();
					subRules = ["Vsc"];
					if(this.lex.front.type == TokenType.comma) {
						this.lex.popFront();
						subRules = ["Vsc"];
						if(this.firstObjectValues()) {
							uint follow = this.parseObjectValues();

							this.objectValuess ~= ObjectValues.ConstructVsc(name, val, follow);
							return cast(uint)(this.objectValuess.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'ObjectValues' found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name"]
						);

					} else if(this.firstObjectValues()) {
						uint follow = this.parseObjectValues();

						this.objectValuess ~= ObjectValues.ConstructVs(name, val, follow);
						return cast(uint)(this.objectValuess.length - 1);

					}
					this.objectValuess ~= ObjectValues.ConstructV(name, val);
					return cast(uint)(this.objectValuess.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'ObjectValues' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["dollar -> Variable","false_ -> Value","floatValue -> Value","intValue -> Value","lbrack -> Value","lcurly -> Value","name -> Value","null_ -> Value","stringValue -> Value","true_ -> Value"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'ObjectValues' found a '%s' while looking for", 
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
			"In 'ObjectValues' found a '%s' while looking for", 
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

	uint parseObjectType() {
		try {
			return this.parseObjectTypeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectType an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseObjectTypeImpl() {
		string[] subRules;
		subRules = ["Var"];
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			subRules = ["Var"];
			if(this.firstObjectValues()) {
				uint vals = this.parseObjectValues();
				subRules = ["Var"];
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();

					this.objectTypes ~= ObjectType.ConstructVar(vals);
					return cast(uint)(this.objectTypes.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'ObjectType' found a '%s' while looking for", 
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
				"In 'ObjectType' found a '%s' while looking for", 
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
			"In 'ObjectType' found a '%s' while looking for", 
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
			 || this.firstDirectiveDefinition()
			 || this.firstDescription();
	}

	uint parseTypeSystemDefinition() {
		try {
			return this.parseTypeSystemDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TypeSystemDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseTypeSystemDefinitionImpl() {
		string[] subRules;
		subRules = ["S"];
		if(this.firstSchemaDefinition()) {
			uint sch = this.parseSchemaDefinition();

			this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructS(sch);
			return cast(uint)(this.typeSystemDefinitions.length - 1);

		} else if(this.firstTypeDefinition()) {
			uint td = this.parseTypeDefinition();

			this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructT(td);
			return cast(uint)(this.typeSystemDefinitions.length - 1);

		} else if(this.firstTypeExtensionDefinition()) {
			uint ted = this.parseTypeExtensionDefinition();

			this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructTE(ted);
			return cast(uint)(this.typeSystemDefinitions.length - 1);

		} else if(this.firstDirectiveDefinition()) {
			uint dd = this.parseDirectiveDefinition();

			this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructD(dd);
			return cast(uint)(this.typeSystemDefinitions.length - 1);

		} else if(this.firstDescription()) {
			uint des = this.parseDescription();
			subRules = ["DS"];
			if(this.firstSchemaDefinition()) {
				uint sch = this.parseSchemaDefinition();

				this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructDS(des, sch);
				return cast(uint)(this.typeSystemDefinitions.length - 1);

			} else if(this.firstTypeDefinition()) {
				uint td = this.parseTypeDefinition();

				this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructDT(des, td);
				return cast(uint)(this.typeSystemDefinitions.length - 1);

			} else if(this.firstTypeExtensionDefinition()) {
				uint ted = this.parseTypeExtensionDefinition();

				this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructDTE(des, ted);
				return cast(uint)(this.typeSystemDefinitions.length - 1);

			} else if(this.firstDirectiveDefinition()) {
				uint dd = this.parseDirectiveDefinition();

				this.typeSystemDefinitions ~= TypeSystemDefinition.ConstructDD(des, dd);
				return cast(uint)(this.typeSystemDefinitions.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'TypeSystemDefinition' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["schema","enum_ -> EnumTypeDefinition","input -> InputObjectTypeDefinition","interface_ -> InterfaceTypeDefinition","scalar -> ScalarTypeDefinition","type -> ObjectTypeDefinition","union_ -> UnionTypeDefinition","extend","directive"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'TypeSystemDefinition' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["schema","enum_ -> EnumTypeDefinition","input -> InputObjectTypeDefinition","interface_ -> InterfaceTypeDefinition","scalar -> ScalarTypeDefinition","type -> ObjectTypeDefinition","union_ -> UnionTypeDefinition","extend","directive","stringValue"]
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

	uint parseTypeDefinition() {
		try {
			return this.parseTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseTypeDefinitionImpl() {
		string[] subRules;
		subRules = ["S"];
		if(this.firstScalarTypeDefinition()) {
			uint std = this.parseScalarTypeDefinition();

			this.typeDefinitions ~= TypeDefinition.ConstructS(std);
			return cast(uint)(this.typeDefinitions.length - 1);

		} else if(this.firstObjectTypeDefinition()) {
			uint otd = this.parseObjectTypeDefinition();

			this.typeDefinitions ~= TypeDefinition.ConstructO(otd);
			return cast(uint)(this.typeDefinitions.length - 1);

		} else if(this.firstInterfaceTypeDefinition()) {
			uint itd = this.parseInterfaceTypeDefinition();

			this.typeDefinitions ~= TypeDefinition.ConstructI(itd);
			return cast(uint)(this.typeDefinitions.length - 1);

		} else if(this.firstUnionTypeDefinition()) {
			uint utd = this.parseUnionTypeDefinition();

			this.typeDefinitions ~= TypeDefinition.ConstructU(utd);
			return cast(uint)(this.typeDefinitions.length - 1);

		} else if(this.firstEnumTypeDefinition()) {
			uint etd = this.parseEnumTypeDefinition();

			this.typeDefinitions ~= TypeDefinition.ConstructE(etd);
			return cast(uint)(this.typeDefinitions.length - 1);

		} else if(this.firstInputObjectTypeDefinition()) {
			uint iod = this.parseInputObjectTypeDefinition();

			this.typeDefinitions ~= TypeDefinition.ConstructIO(iod);
			return cast(uint)(this.typeDefinitions.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'TypeDefinition' found a '%s' while looking for", 
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

	uint parseSchemaDefinition() {
		try {
			return this.parseSchemaDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a SchemaDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseSchemaDefinitionImpl() {
		string[] subRules;
		subRules = ["DO", "O"];
		if(this.lex.front.type == TokenType.schema) {
			this.lex.popFront();
			subRules = ["DO"];
			if(this.firstDirectives()) {
				uint dir = this.parseDirectives();
				subRules = ["DO"];
				if(this.lex.front.type == TokenType.lcurly) {
					this.lex.popFront();
					subRules = ["DO"];
					if(this.firstOperationTypeDefinitions()) {
						uint otds = this.parseOperationTypeDefinitions();
						subRules = ["DO"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							this.schemaDefinitions ~= SchemaDefinition.ConstructDO(dir, otds);
							return cast(uint)(this.schemaDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'SchemaDefinition' found a '%s' while looking for", 
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
						"In 'SchemaDefinition' found a '%s' while looking for", 
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
					"In 'SchemaDefinition' found a '%s' while looking for", 
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
					uint otds = this.parseOperationTypeDefinitions();
					subRules = ["O"];
					if(this.lex.front.type == TokenType.rcurly) {
						this.lex.popFront();

						this.schemaDefinitions ~= SchemaDefinition.ConstructO(otds);
						return cast(uint)(this.schemaDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'SchemaDefinition' found a '%s' while looking for", 
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
					"In 'SchemaDefinition' found a '%s' while looking for", 
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
				"In 'SchemaDefinition' found a '%s' while looking for", 
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
			"In 'SchemaDefinition' found a '%s' while looking for", 
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

	uint parseOperationTypeDefinitions() {
		try {
			return this.parseOperationTypeDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationTypeDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseOperationTypeDefinitionsImpl() {
		string[] subRules;
		subRules = ["O", "OCS", "OS"];
		if(this.firstOperationTypeDefinition()) {
			uint otd = this.parseOperationTypeDefinition();
			subRules = ["OCS"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["OCS"];
				if(this.firstOperationTypeDefinitions()) {
					uint follow = this.parseOperationTypeDefinitions();

					this.operationTypeDefinitionss ~= OperationTypeDefinitions.ConstructOCS(otd, follow);
					return cast(uint)(this.operationTypeDefinitionss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'OperationTypeDefinitions' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["mutation -> OperationTypeDefinition","query -> OperationTypeDefinition","subscription -> OperationTypeDefinition"]
				);

			} else if(this.firstOperationTypeDefinitions()) {
				uint follow = this.parseOperationTypeDefinitions();

				this.operationTypeDefinitionss ~= OperationTypeDefinitions.ConstructOS(otd, follow);
				return cast(uint)(this.operationTypeDefinitionss.length - 1);

			}
			this.operationTypeDefinitionss ~= OperationTypeDefinitions.ConstructO(otd);
			return cast(uint)(this.operationTypeDefinitionss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'OperationTypeDefinitions' found a '%s' while looking for", 
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

	uint parseOperationTypeDefinition() {
		try {
			return this.parseOperationTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OperationTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseOperationTypeDefinitionImpl() {
		string[] subRules;
		subRules = ["O"];
		if(this.firstOperationType()) {
			uint ot = this.parseOperationType();
			subRules = ["O"];
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				subRules = ["O"];
				if(this.lex.front.type == TokenType.name) {
					Token nt = this.lex.front;
					this.lex.popFront();

					this.operationTypeDefinitions ~= OperationTypeDefinition.ConstructO(ot, nt);
					return cast(uint)(this.operationTypeDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'OperationTypeDefinition' found a '%s' while looking for", 
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
				"In 'OperationTypeDefinition' found a '%s' while looking for", 
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
			"In 'OperationTypeDefinition' found a '%s' while looking for", 
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

	uint parseScalarTypeDefinition() {
		try {
			return this.parseScalarTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ScalarTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseScalarTypeDefinitionImpl() {
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
					uint dir = this.parseDirectives();

					this.scalarTypeDefinitions ~= ScalarTypeDefinition.ConstructD(name, dir);
					return cast(uint)(this.scalarTypeDefinitions.length - 1);

				}
				this.scalarTypeDefinitions ~= ScalarTypeDefinition.ConstructS(name);
				return cast(uint)(this.scalarTypeDefinitions.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'ScalarTypeDefinition' found a '%s' while looking for", 
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
			"In 'ScalarTypeDefinition' found a '%s' while looking for", 
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

	uint parseObjectTypeDefinition() {
		try {
			return this.parseObjectTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ObjectTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseObjectTypeDefinitionImpl() {
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
					uint ii = this.parseImplementsInterfaces();
					subRules = ["ID"];
					if(this.firstDirectives()) {
						uint dir = this.parseDirectives();
						subRules = ["ID"];
						if(this.lex.front.type == TokenType.lcurly) {
							this.lex.popFront();
							subRules = ["ID"];
							if(this.firstFieldDefinitions()) {
								uint fds = this.parseFieldDefinitions();
								subRules = ["ID"];
								if(this.lex.front.type == TokenType.rcurly) {
									this.lex.popFront();

									this.objectTypeDefinitions ~= ObjectTypeDefinition.ConstructID(name, ii, dir, fds);
									return cast(uint)(this.objectTypeDefinitions.length - 1);

								}
								auto app = appender!string();
								formattedWrite(app, 
									"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
								"In 'ObjectTypeDefinition' found a '%s' while looking for", 
								this.lex.front
							);
							throw new ParseException(app.data,
								__FILE__, __LINE__,
								subRules,
								["name -> FieldDefinition","stringValue -> FieldDefinition"]
							);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
							uint fds = this.parseFieldDefinitions();
							subRules = ["I"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								this.objectTypeDefinitions ~= ObjectTypeDefinition.ConstructI(name, ii, fds);
								return cast(uint)(this.objectTypeDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
							"In 'ObjectTypeDefinition' found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> FieldDefinition","stringValue -> FieldDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'ObjectTypeDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["at -> Directive","lcurly"]
					);

				} else if(this.firstDirectives()) {
					uint dir = this.parseDirectives();
					subRules = ["D"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["D"];
						if(this.firstFieldDefinitions()) {
							uint fds = this.parseFieldDefinitions();
							subRules = ["D"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								this.objectTypeDefinitions ~= ObjectTypeDefinition.ConstructD(name, dir, fds);
								return cast(uint)(this.objectTypeDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
							"In 'ObjectTypeDefinition' found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> FieldDefinition","stringValue -> FieldDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
						uint fds = this.parseFieldDefinitions();
						subRules = ["F"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							this.objectTypeDefinitions ~= ObjectTypeDefinition.ConstructF(name, fds);
							return cast(uint)(this.objectTypeDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
						"In 'ObjectTypeDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> FieldDefinition","stringValue -> FieldDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
				"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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
			"In 'ObjectTypeDefinition' found a '%s' while looking for", 
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

	uint parseFieldDefinitions() {
		try {
			return this.parseFieldDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FieldDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseFieldDefinitionsImpl() {
		string[] subRules;
		subRules = ["F", "FC", "FNC"];
		if(this.firstFieldDefinition()) {
			uint fd = this.parseFieldDefinition();
			subRules = ["FC"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["FC"];
				if(this.firstFieldDefinitions()) {
					uint follow = this.parseFieldDefinitions();

					this.fieldDefinitionss ~= FieldDefinitions.ConstructFC(fd, follow);
					return cast(uint)(this.fieldDefinitionss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'FieldDefinitions' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> FieldDefinition","stringValue -> FieldDefinition"]
				);

			} else if(this.firstFieldDefinitions()) {
				uint follow = this.parseFieldDefinitions();

				this.fieldDefinitionss ~= FieldDefinitions.ConstructFNC(fd, follow);
				return cast(uint)(this.fieldDefinitionss.length - 1);

			}
			this.fieldDefinitionss ~= FieldDefinitions.ConstructF(fd);
			return cast(uint)(this.fieldDefinitionss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'FieldDefinitions' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name","stringValue -> Description"]
		);

	}

	bool firstFieldDefinition() const pure @nogc @safe {
		return this.lex.front.type == TokenType.name
			 || this.firstDescription();
	}

	uint parseFieldDefinition() {
		try {
			return this.parseFieldDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a FieldDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseFieldDefinitionImpl() {
		string[] subRules;
		subRules = ["A", "AD", "D", "T"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["A", "AD"];
			if(this.firstArgumentsDefinition()) {
				uint arg = this.parseArgumentsDefinition();
				subRules = ["A", "AD"];
				if(this.lex.front.type == TokenType.colon) {
					this.lex.popFront();
					subRules = ["A", "AD"];
					if(this.firstType()) {
						uint typ = this.parseType();
						subRules = ["AD"];
						if(this.firstDirectives()) {
							uint dir = this.parseDirectives();

							this.fieldDefinitions ~= FieldDefinition.ConstructAD(name, arg, typ, dir);
							return cast(uint)(this.fieldDefinitions.length - 1);

						}
						this.fieldDefinitions ~= FieldDefinition.ConstructA(name, arg, typ);
						return cast(uint)(this.fieldDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'FieldDefinition' found a '%s' while looking for", 
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
					"In 'FieldDefinition' found a '%s' while looking for", 
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
					uint typ = this.parseType();
					subRules = ["D"];
					if(this.firstDirectives()) {
						uint dir = this.parseDirectives();

						this.fieldDefinitions ~= FieldDefinition.ConstructD(name, typ, dir);
						return cast(uint)(this.fieldDefinitions.length - 1);

					}
					this.fieldDefinitions ~= FieldDefinition.ConstructT(name, typ);
					return cast(uint)(this.fieldDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'FieldDefinition' found a '%s' while looking for", 
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
				"In 'FieldDefinition' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["lparen","colon"]
			);

		} else if(this.firstDescription()) {
			uint des = this.parseDescription();
			subRules = ["DA", "DAD", "DD", "DT"];
			if(this.lex.front.type == TokenType.name) {
				Token name = this.lex.front;
				this.lex.popFront();
				subRules = ["DA", "DAD"];
				if(this.firstArgumentsDefinition()) {
					uint arg = this.parseArgumentsDefinition();
					subRules = ["DA", "DAD"];
					if(this.lex.front.type == TokenType.colon) {
						this.lex.popFront();
						subRules = ["DA", "DAD"];
						if(this.firstType()) {
							uint typ = this.parseType();
							subRules = ["DAD"];
							if(this.firstDirectives()) {
								uint dir = this.parseDirectives();

								this.fieldDefinitions ~= FieldDefinition.ConstructDAD(des, name, arg, typ, dir);
								return cast(uint)(this.fieldDefinitions.length - 1);

							}
							this.fieldDefinitions ~= FieldDefinition.ConstructDA(des, name, arg, typ);
							return cast(uint)(this.fieldDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'FieldDefinition' found a '%s' while looking for", 
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
						"In 'FieldDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["colon"]
					);

				} else if(this.lex.front.type == TokenType.colon) {
					this.lex.popFront();
					subRules = ["DD", "DT"];
					if(this.firstType()) {
						uint typ = this.parseType();
						subRules = ["DD"];
						if(this.firstDirectives()) {
							uint dir = this.parseDirectives();

							this.fieldDefinitions ~= FieldDefinition.ConstructDD(des, name, typ, dir);
							return cast(uint)(this.fieldDefinitions.length - 1);

						}
						this.fieldDefinitions ~= FieldDefinition.ConstructDT(des, name, typ);
						return cast(uint)(this.fieldDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'FieldDefinition' found a '%s' while looking for", 
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
					"In 'FieldDefinition' found a '%s' while looking for", 
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
				"In 'FieldDefinition' found a '%s' while looking for", 
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
			"In 'FieldDefinition' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["name","stringValue"]
		);

	}

	bool firstImplementsInterfaces() const pure @nogc @safe {
		return this.lex.front.type == TokenType.implements;
	}

	uint parseImplementsInterfaces() {
		try {
			return this.parseImplementsInterfacesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ImplementsInterfaces an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseImplementsInterfacesImpl() {
		string[] subRules;
		subRules = ["N"];
		if(this.lex.front.type == TokenType.implements) {
			this.lex.popFront();
			subRules = ["N"];
			if(this.firstNamedTypes()) {
				uint nts = this.parseNamedTypes();

				this.implementsInterfacess ~= ImplementsInterfaces.ConstructN(nts);
				return cast(uint)(this.implementsInterfacess.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'ImplementsInterfaces' found a '%s' while looking for", 
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
			"In 'ImplementsInterfaces' found a '%s' while looking for", 
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

	uint parseNamedTypes() {
		try {
			return this.parseNamedTypesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a NamedTypes an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseNamedTypesImpl() {
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
					uint follow = this.parseNamedTypes();

					this.namedTypess ~= NamedTypes.ConstructNCS(name, follow);
					return cast(uint)(this.namedTypess.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'NamedTypes' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
				);

			} else if(this.firstNamedTypes()) {
				uint follow = this.parseNamedTypes();

				this.namedTypess ~= NamedTypes.ConstructNS(name, follow);
				return cast(uint)(this.namedTypess.length - 1);

			}
			this.namedTypess ~= NamedTypes.ConstructN(name);
			return cast(uint)(this.namedTypess.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'NamedTypes' found a '%s' while looking for", 
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

	uint parseArgumentsDefinition() {
		try {
			return this.parseArgumentsDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a ArgumentsDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseArgumentsDefinitionImpl() {
		string[] subRules;
		subRules = ["A", "DA"];
		if(this.lex.front.type == TokenType.lparen) {
			this.lex.popFront();
			subRules = ["A"];
			if(this.firstInputValueDefinitions()) {
				this.parseInputValueDefinitions();
				subRules = ["A"];
				if(this.lex.front.type == TokenType.rparen) {
					this.lex.popFront();

					this.argumentsDefinitions ~= ArgumentsDefinition.ConstructA();
					return cast(uint)(this.argumentsDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'ArgumentsDefinition' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["rparen"]
				);

			} else if(this.firstDescription()) {
				uint des = this.parseDescription();
				subRules = ["DA"];
				if(this.firstInputValueDefinitions()) {
					this.parseInputValueDefinitions();
					subRules = ["DA"];
					if(this.lex.front.type == TokenType.rparen) {
						this.lex.popFront();

						this.argumentsDefinitions ~= ArgumentsDefinition.ConstructDA(des);
						return cast(uint)(this.argumentsDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'ArgumentsDefinition' found a '%s' while looking for", 
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
					"In 'ArgumentsDefinition' found a '%s' while looking for", 
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
				"In 'ArgumentsDefinition' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["name -> InputValueDefinition","stringValue"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'ArgumentsDefinition' found a '%s' while looking for", 
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

	uint parseInputValueDefinitions() {
		try {
			return this.parseInputValueDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputValueDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseInputValueDefinitionsImpl() {
		string[] subRules;
		subRules = ["I", "ICF", "IF"];
		if(this.firstInputValueDefinition()) {
			uint iv = this.parseInputValueDefinition();
			subRules = ["ICF"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["ICF"];
				if(this.firstInputValueDefinitions()) {
					uint follow = this.parseInputValueDefinitions();

					this.inputValueDefinitionss ~= InputValueDefinitions.ConstructICF(iv, follow);
					return cast(uint)(this.inputValueDefinitionss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'InputValueDefinitions' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> InputValueDefinition"]
				);

			} else if(this.firstInputValueDefinitions()) {
				uint follow = this.parseInputValueDefinitions();

				this.inputValueDefinitionss ~= InputValueDefinitions.ConstructIF(iv, follow);
				return cast(uint)(this.inputValueDefinitionss.length - 1);

			}
			this.inputValueDefinitionss ~= InputValueDefinitions.ConstructI(iv);
			return cast(uint)(this.inputValueDefinitionss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'InputValueDefinitions' found a '%s' while looking for", 
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

	uint parseInputValueDefinition() {
		try {
			return this.parseInputValueDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputValueDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseInputValueDefinitionImpl() {
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
					uint type = this.parseType();
					subRules = ["TV", "TVD"];
					if(this.firstDefaultValue()) {
						uint df = this.parseDefaultValue();
						subRules = ["TVD"];
						if(this.firstDirectives()) {
							uint dirs = this.parseDirectives();

							this.inputValueDefinitions ~= InputValueDefinition.ConstructTVD(name, type, df, dirs);
							return cast(uint)(this.inputValueDefinitions.length - 1);

						}
						this.inputValueDefinitions ~= InputValueDefinition.ConstructTV(name, type, df);
						return cast(uint)(this.inputValueDefinitions.length - 1);

					} else if(this.firstDirectives()) {
						uint dirs = this.parseDirectives();

						this.inputValueDefinitions ~= InputValueDefinition.ConstructTD(name, type, dirs);
						return cast(uint)(this.inputValueDefinitions.length - 1);

					}
					this.inputValueDefinitions ~= InputValueDefinition.ConstructT(name, type);
					return cast(uint)(this.inputValueDefinitions.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'InputValueDefinition' found a '%s' while looking for", 
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
				"In 'InputValueDefinition' found a '%s' while looking for", 
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
			"In 'InputValueDefinition' found a '%s' while looking for", 
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

	uint parseInterfaceTypeDefinition() {
		try {
			return this.parseInterfaceTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InterfaceTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseInterfaceTypeDefinitionImpl() {
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
					uint dirs = this.parseDirectives();
					subRules = ["NDF"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDF"];
						if(this.firstFieldDefinitions()) {
							uint fds = this.parseFieldDefinitions();
							subRules = ["NDF"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								this.interfaceTypeDefinitions ~= InterfaceTypeDefinition.ConstructNDF(name, dirs, fds);
								return cast(uint)(this.interfaceTypeDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
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
							"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
							this.lex.front
						);
						throw new ParseException(app.data,
							__FILE__, __LINE__,
							subRules,
							["name -> FieldDefinition","stringValue -> FieldDefinition"]
						);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
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
						uint fds = this.parseFieldDefinitions();
						subRules = ["NF"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							this.interfaceTypeDefinitions ~= InterfaceTypeDefinition.ConstructNF(name, fds);
							return cast(uint)(this.interfaceTypeDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
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
						"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["name -> FieldDefinition","stringValue -> FieldDefinition"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
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
				"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
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
			"In 'InterfaceTypeDefinition' found a '%s' while looking for", 
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

	uint parseUnionTypeDefinition() {
		try {
			return this.parseUnionTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a UnionTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseUnionTypeDefinitionImpl() {
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
					uint dirs = this.parseDirectives();
					subRules = ["NDU"];
					if(this.lex.front.type == TokenType.equal) {
						this.lex.popFront();
						subRules = ["NDU"];
						if(this.firstUnionMembers()) {
							uint um = this.parseUnionMembers();

							this.unionTypeDefinitions ~= UnionTypeDefinition.ConstructNDU(name, dirs, um);
							return cast(uint)(this.unionTypeDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'UnionTypeDefinition' found a '%s' while looking for", 
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
						"In 'UnionTypeDefinition' found a '%s' while looking for", 
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
						uint um = this.parseUnionMembers();

						this.unionTypeDefinitions ~= UnionTypeDefinition.ConstructNU(name, um);
						return cast(uint)(this.unionTypeDefinitions.length - 1);

					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'UnionTypeDefinition' found a '%s' while looking for", 
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
					"In 'UnionTypeDefinition' found a '%s' while looking for", 
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
				"In 'UnionTypeDefinition' found a '%s' while looking for", 
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
			"In 'UnionTypeDefinition' found a '%s' while looking for", 
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

	uint parseUnionMembers() {
		try {
			return this.parseUnionMembersImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a UnionMembers an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseUnionMembersImpl() {
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
					uint follow = this.parseUnionMembers();

					this.unionMemberss ~= UnionMembers.ConstructSPF(name, follow);
					return cast(uint)(this.unionMemberss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'UnionMembers' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
				);

			} else if(this.firstUnionMembers()) {
				uint follow = this.parseUnionMembers();

				this.unionMemberss ~= UnionMembers.ConstructSF(name, follow);
				return cast(uint)(this.unionMemberss.length - 1);

			}
			this.unionMemberss ~= UnionMembers.ConstructS(name);
			return cast(uint)(this.unionMemberss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'UnionMembers' found a '%s' while looking for", 
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

	uint parseEnumTypeDefinition() {
		try {
			return this.parseEnumTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a EnumTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseEnumTypeDefinitionImpl() {
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
					uint dir = this.parseDirectives();
					subRules = ["NDE"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDE"];
						if(this.firstEnumValueDefinitions()) {
							uint evds = this.parseEnumValueDefinitions();
							subRules = ["NDE"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								this.enumTypeDefinitions ~= EnumTypeDefinition.ConstructNDE(name, dir, evds);
								return cast(uint)(this.enumTypeDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
							"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
						"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
						uint evds = this.parseEnumValueDefinitions();
						subRules = ["NE"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							this.enumTypeDefinitions ~= EnumTypeDefinition.ConstructNE(name, evds);
							return cast(uint)(this.enumTypeDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
						"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
					"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
				"In 'EnumTypeDefinition' found a '%s' while looking for", 
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
			"In 'EnumTypeDefinition' found a '%s' while looking for", 
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

	uint parseEnumValueDefinitions() {
		try {
			return this.parseEnumValueDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a EnumValueDefinitions an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseEnumValueDefinitionsImpl() {
		string[] subRules;
		subRules = ["D", "DCE", "DE"];
		if(this.firstEnumValueDefinition()) {
			uint evd = this.parseEnumValueDefinition();
			subRules = ["DCE"];
			if(this.lex.front.type == TokenType.comma) {
				this.lex.popFront();
				subRules = ["DCE"];
				if(this.firstEnumValueDefinitions()) {
					uint follow = this.parseEnumValueDefinitions();

					this.enumValueDefinitionss ~= EnumValueDefinitions.ConstructDCE(evd, follow);
					return cast(uint)(this.enumValueDefinitionss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'EnumValueDefinitions' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name -> EnumValueDefinition"]
				);

			} else if(this.firstEnumValueDefinitions()) {
				uint follow = this.parseEnumValueDefinitions();

				this.enumValueDefinitionss ~= EnumValueDefinitions.ConstructDE(evd, follow);
				return cast(uint)(this.enumValueDefinitionss.length - 1);

			}
			this.enumValueDefinitionss ~= EnumValueDefinitions.ConstructD(evd);
			return cast(uint)(this.enumValueDefinitionss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'EnumValueDefinitions' found a '%s' while looking for", 
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

	uint parseEnumValueDefinition() {
		try {
			return this.parseEnumValueDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a EnumValueDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseEnumValueDefinitionImpl() {
		string[] subRules;
		subRules = ["E", "ED"];
		if(this.lex.front.type == TokenType.name) {
			Token name = this.lex.front;
			this.lex.popFront();
			subRules = ["ED"];
			if(this.firstDirectives()) {
				uint dirs = this.parseDirectives();

				this.enumValueDefinitions ~= EnumValueDefinition.ConstructED(name, dirs);
				return cast(uint)(this.enumValueDefinitions.length - 1);

			}
			this.enumValueDefinitions ~= EnumValueDefinition.ConstructE(name);
			return cast(uint)(this.enumValueDefinitions.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'EnumValueDefinition' found a '%s' while looking for", 
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

	uint parseInputTypeDefinition() {
		try {
			return this.parseInputTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseInputTypeDefinitionImpl() {
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
					uint dir = this.parseDirectives();
					subRules = ["NDE"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDE"];
						if(this.firstInputValueDefinitions()) {
							uint ivds = this.parseInputValueDefinitions();
							subRules = ["NDE"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								this.inputTypeDefinitions ~= InputTypeDefinition.ConstructNDE(name, dir, ivds);
								return cast(uint)(this.inputTypeDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'InputTypeDefinition' found a '%s' while looking for", 
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
							"In 'InputTypeDefinition' found a '%s' while looking for", 
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
						"In 'InputTypeDefinition' found a '%s' while looking for", 
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
						uint ivds = this.parseInputValueDefinitions();
						subRules = ["NE"];
						if(this.lex.front.type == TokenType.rcurly) {
							this.lex.popFront();

							this.inputTypeDefinitions ~= InputTypeDefinition.ConstructNE(name, ivds);
							return cast(uint)(this.inputTypeDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'InputTypeDefinition' found a '%s' while looking for", 
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
						"In 'InputTypeDefinition' found a '%s' while looking for", 
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
					"In 'InputTypeDefinition' found a '%s' while looking for", 
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
				"In 'InputTypeDefinition' found a '%s' while looking for", 
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
			"In 'InputTypeDefinition' found a '%s' while looking for", 
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

	uint parseTypeExtensionDefinition() {
		try {
			return this.parseTypeExtensionDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TypeExtensionDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseTypeExtensionDefinitionImpl() {
		string[] subRules;
		subRules = ["O"];
		if(this.lex.front.type == TokenType.extend) {
			this.lex.popFront();
			subRules = ["O"];
			if(this.firstObjectTypeDefinition()) {
				uint otd = this.parseObjectTypeDefinition();

				this.typeExtensionDefinitions ~= TypeExtensionDefinition.ConstructO(otd);
				return cast(uint)(this.typeExtensionDefinitions.length - 1);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'TypeExtensionDefinition' found a '%s' while looking for", 
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
			"In 'TypeExtensionDefinition' found a '%s' while looking for", 
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

	uint parseDirectiveDefinition() {
		try {
			return this.parseDirectiveDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a DirectiveDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDirectiveDefinitionImpl() {
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
						uint ad = this.parseArgumentsDefinition();
						subRules = ["AD"];
						if(this.lex.front.type == TokenType.on_) {
							this.lex.popFront();
							subRules = ["AD"];
							if(this.firstDirectiveLocations()) {
								uint dl = this.parseDirectiveLocations();

								this.directiveDefinitions ~= DirectiveDefinition.ConstructAD(name, ad, dl);
								return cast(uint)(this.directiveDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'DirectiveDefinition' found a '%s' while looking for", 
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
							"In 'DirectiveDefinition' found a '%s' while looking for", 
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
							uint dl = this.parseDirectiveLocations();

							this.directiveDefinitions ~= DirectiveDefinition.ConstructD(name, dl);
							return cast(uint)(this.directiveDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'DirectiveDefinition' found a '%s' while looking for", 
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
						"In 'DirectiveDefinition' found a '%s' while looking for", 
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
					"In 'DirectiveDefinition' found a '%s' while looking for", 
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
				"In 'DirectiveDefinition' found a '%s' while looking for", 
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
			"In 'DirectiveDefinition' found a '%s' while looking for", 
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

	uint parseDirectiveLocations() {
		try {
			return this.parseDirectiveLocationsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a DirectiveLocations an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDirectiveLocationsImpl() {
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
					uint follow = this.parseDirectiveLocations();

					this.directiveLocationss ~= DirectiveLocations.ConstructNPF(name, follow);
					return cast(uint)(this.directiveLocationss.length - 1);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'DirectiveLocations' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["name"]
				);

			} else if(this.firstDirectiveLocations()) {
				uint follow = this.parseDirectiveLocations();

				this.directiveLocationss ~= DirectiveLocations.ConstructNF(name, follow);
				return cast(uint)(this.directiveLocationss.length - 1);

			}
			this.directiveLocationss ~= DirectiveLocations.ConstructN(name);
			return cast(uint)(this.directiveLocationss.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'DirectiveLocations' found a '%s' while looking for", 
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

	uint parseInputObjectTypeDefinition() {
		try {
			return this.parseInputObjectTypeDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a InputObjectTypeDefinition an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseInputObjectTypeDefinitionImpl() {
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
					uint dirs = this.parseDirectives();
					subRules = ["NDI"];
					if(this.lex.front.type == TokenType.lcurly) {
						this.lex.popFront();
						subRules = ["NDI"];
						if(this.firstInputValueDefinitions()) {
							this.parseInputValueDefinitions();
							subRules = ["NDI"];
							if(this.lex.front.type == TokenType.rcurly) {
								this.lex.popFront();

								this.inputObjectTypeDefinitions ~= InputObjectTypeDefinition.ConstructNDI(name, dirs);
								return cast(uint)(this.inputObjectTypeDefinitions.length - 1);

							}
							auto app = appender!string();
							formattedWrite(app, 
								"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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
							"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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
						"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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

							this.inputObjectTypeDefinitions ~= InputObjectTypeDefinition.ConstructNI(name);
							return cast(uint)(this.inputObjectTypeDefinitions.length - 1);

						}
						auto app = appender!string();
						formattedWrite(app, 
							"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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
						"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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
					"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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
				"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
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
			"In 'InputObjectTypeDefinition' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["input"]
		);

	}

	bool firstDescription() const pure @nogc @safe {
		return this.lex.front.type == TokenType.stringValue;
	}

	uint parseDescription() {
		try {
			return this.parseDescriptionImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Description an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	uint parseDescriptionImpl() {
		string[] subRules;
		subRules = ["S"];
		if(this.lex.front.type == TokenType.stringValue) {
			Token tok = this.lex.front;
			this.lex.popFront();

			this.descriptions ~= Description.ConstructS(tok);
			return cast(uint)(this.descriptions.length - 1);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Description' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["stringValue"]
		);

	}

}
