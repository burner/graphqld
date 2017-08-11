module parser;

import std.typecons : RefCounted, refCounted;
import std.format : format;
import ast;
public import parsercustom;

import tokenmodule;

import lexer;

import exception;

struct Parser {
	Lexer lex;

	this(Lexer lex) {
		this.lex = lex;
	}

	bool firstDocument() const {
		return this.firstDefinitions();
	}

	DocumentPtr parseDocument() {
		try {
			return this.parseDocumentImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Document an Exception was thrown.", e);
		}
	}

	DocumentPtr parseDocumentImpl() {
		DocumentPtr ret = refCounted!Document();
		if(this.firstDefinitions()) {
			ret.defs = this.parseDefinitions();
			ret.ruleSelection = DocumentEnum.Defi;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an Definitions. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstDefinitions() const {
		return this.firstDefinition();
	}

	DefinitionsPtr parseDefinitions() {
		try {
			return this.parseDefinitionsImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Definitions an Exception was thrown.", e);
		}
	}

	DefinitionsPtr parseDefinitionsImpl() {
		DefinitionsPtr ret = refCounted!Definitions();
		if(this.firstDefinition()) {
			ret.def = this.parseDefinition();
			if(this.firstDefinitions()) {
				ret.follow = this.parseDefinitions();
				ret.ruleSelection = DefinitionsEnum.Defs;
				return ret;
			}
		}
		throw new ParseException(format(
			"Was expecting an Definition. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstDefinition() const {
		return this.firstOperationDefinition()
			 || this.firstFragmentDefinition();
	}

	DefinitionPtr parseDefinition() {
		try {
			return this.parseDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Definition an Exception was thrown.", e);
		}
	}

	DefinitionPtr parseDefinitionImpl() {
		DefinitionPtr ret = refCounted!Definition();
		if(this.firstOperationDefinition()) {
			ret.op = this.parseOperationDefinition();
			ret.ruleSelection = DefinitionEnum.Op;
			return ret;
		} else if(this.firstFragmentDefinition()) {
			ret.frag = this.parseFragmentDefinition();
			ret.ruleSelection = DefinitionEnum.Frag;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an OperationDefinition, or FragmentDefinition. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstOperationDefinition() const {
		return this.firstSelectionSet()
			 || this.firstOperationType();
	}

	OperationDefinitionPtr parseOperationDefinition() {
		try {
			return this.parseOperationDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a OperationDefinition an Exception was thrown.", e);
		}
	}

	OperationDefinitionPtr parseOperationDefinitionImpl() {
		OperationDefinitionPtr ret = refCounted!OperationDefinition();
		if(this.firstSelectionSet()) {
			ret.ss = this.parseSelectionSet();
			ret.ruleSelection = OperationDefinitionEnum.SelSet;
			return ret;
		} else if(this.firstOperationType()) {
			ret.ot = this.parseOperationType();
			if(this.lex.front.type == TokenType.name) {
				ret.name = this.lex.front;
				this.lex.popFront();
				if(this.firstVariableDefinitions()) {
					ret.vd = this.parseVariableDefinitions();
					if(this.firstDirectives()) {
						ret.d = this.parseDirectives();
						if(this.firstSelectionSet()) {
							ret.ss = this.parseSelectionSet();
							ret.ruleSelection = OperationDefinitionEnum.OT_VD;
							return ret;
						}
						throw new ParseException(format(
							"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front.type,this.lex.line, this.lex.column)
						);
					} else if(this.firstSelectionSet()) {
						ret.ss = this.parseSelectionSet();
						ret.ruleSelection = OperationDefinitionEnum.OT_V;
						return ret;
					}
					throw new ParseException(format(
						"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				} else if(this.firstDirectives()) {
					ret.d = this.parseDirectives();
					if(this.firstSelectionSet()) {
						ret.ss = this.parseSelectionSet();
						ret.ruleSelection = OperationDefinitionEnum.OT_D;
						return ret;
					}
					throw new ParseException(format(
						"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				} else if(this.firstSelectionSet()) {
					ret.ss = this.parseSelectionSet();
					ret.ruleSelection = OperationDefinitionEnum.OT;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an VariableDefinitions, Directives, or SelectionSet. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an SelectionSet, or OperationType. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstSelectionSet() const {
		return this.lex.front.type == TokenType.lcurly;
	}

	SelectionSetPtr parseSelectionSet() {
		try {
			return this.parseSelectionSetImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a SelectionSet an Exception was thrown.", e);
		}
	}

	SelectionSetPtr parseSelectionSetImpl() {
		SelectionSetPtr ret = refCounted!SelectionSet();
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			if(this.firstSelections()) {
				ret.sel = this.parseSelections();
				if(this.lex.front.type == TokenType.rcurly) {
					this.lex.popFront();
					ret.ruleSelection = SelectionSetEnum.SS;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an rcurly. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an Selections. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an lcurly. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstOperationType() const {
		return this.lex.front.type == TokenType.query
			 || this.lex.front.type == TokenType.mutation;
	}

	OperationTypePtr parseOperationType() {
		try {
			return this.parseOperationTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a OperationType an Exception was thrown.", e);
		}
	}

	OperationTypePtr parseOperationTypeImpl() {
		OperationTypePtr ret = refCounted!OperationType();
		if(this.lex.front.type == TokenType.query) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = OperationTypeEnum.Query;
			return ret;
		} else if(this.lex.front.type == TokenType.mutation) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = OperationTypeEnum.Mutation;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an query, or mutation. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstSelection() const {
		return this.firstField()
			 || this.firstFragmentSpread()
			 || this.firstInlineFragment();
	}

	SelectionPtr parseSelection() {
		try {
			return this.parseSelectionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Selection an Exception was thrown.", e);
		}
	}

	SelectionPtr parseSelectionImpl() {
		SelectionPtr ret = refCounted!Selection();
		if(this.firstField()) {
			ret.field = this.parseField();
			ret.ruleSelection = SelectionEnum.Field;
			return ret;
		} else if(this.firstFragmentSpread()) {
			ret.frag = this.parseFragmentSpread();
			ret.ruleSelection = SelectionEnum.Frag;
			return ret;
		} else if(this.firstInlineFragment()) {
			ret.ifrag = this.parseInlineFragment();
			ret.ruleSelection = SelectionEnum.IFrag;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an Field, FragmentSpread, or InlineFragment. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstField() const {
		return this.firstFieldName();
	}

	FieldPtr parseField() {
		try {
			return this.parseFieldImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Field an Exception was thrown.", e);
		}
	}

	FieldPtr parseFieldImpl() {
		FieldPtr ret = refCounted!Field();
		if(this.firstFieldName()) {
			ret.name = this.parseFieldName();
			if(this.firstArguments()) {
				ret.args = this.parseArguments();
				if(this.firstDirectives()) {
					ret.dirs = this.parseDirectives();
					if(this.firstSelectionSet()) {
						ret.ss = this.parseSelectionSet();
						ret.ruleSelection = FieldEnum.FADS;
						return ret;
					}
					throw new ParseException(format(
						"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				} else if(this.firstSelectionSet()) {
					ret.ss = this.parseSelectionSet();
					ret.ruleSelection = FieldEnum.FAS;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			} else if(this.firstDirectives()) {
				ret.dirs = this.parseDirectives();
				if(this.firstSelectionSet()) {
					ret.ss = this.parseSelectionSet();
					ret.ruleSelection = FieldEnum.FDS;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			} else if(this.firstSelectionSet()) {
				ret.ss = this.parseSelectionSet();
				ret.ruleSelection = FieldEnum.FS;
				return ret;
			}
			throw new ParseException(format(
				"Was expecting an Arguments, Directives, or SelectionSet. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an FieldName. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstFieldName() const {
		return this.lex.front.type == TokenType.alias_
			 || this.lex.front.type == TokenType.name;
	}

	FieldNamePtr parseFieldName() {
		try {
			return this.parseFieldNameImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a FieldName an Exception was thrown.", e);
		}
	}

	FieldNamePtr parseFieldNameImpl() {
		FieldNamePtr ret = refCounted!FieldName();
		if(this.lex.front.type == TokenType.alias_) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = FieldNameEnum.A;
			return ret;
		} else if(this.lex.front.type == TokenType.name) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = FieldNameEnum.N;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an alias_, or name. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstAlias() const {
		return this.lex.front.type == TokenType.name;
	}

	AliasPtr parseAlias() {
		try {
			return this.parseAliasImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Alias an Exception was thrown.", e);
		}
	}

	AliasPtr parseAliasImpl() {
		AliasPtr ret = refCounted!Alias();
		if(this.lex.front.type == TokenType.name) {
			ret.from = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.lex.front.type == TokenType.name) {
					ret.to = this.lex.front;
					this.lex.popFront();
					ret.ruleSelection = AliasEnum.A;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an name. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstArgument() const {
		return this.lex.front.type == TokenType.name;
	}

	ArgumentPtr parseArgument() {
		try {
			return this.parseArgumentImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Argument an Exception was thrown.", e);
		}
	}

	ArgumentPtr parseArgumentImpl() {
		ArgumentPtr ret = refCounted!Argument();
		if(this.lex.front.type == TokenType.name) {
			ret.name = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstValueOrVariable()) {
					this.parseValueOrVariable();
					ret.ruleSelection = ArgumentEnum.Name;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an ValueOrVariable. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstFragmentSpread() const {
		return this.lex.front.type == TokenType.dots;
	}

	FragmentSpreadPtr parseFragmentSpread() {
		try {
			return this.parseFragmentSpreadImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a FragmentSpread an Exception was thrown.", e);
		}
	}

	FragmentSpreadPtr parseFragmentSpreadImpl() {
		FragmentSpreadPtr ret = refCounted!FragmentSpread();
		if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				ret.name = this.lex.front;
				this.lex.popFront();
				if(this.firstDirectives()) {
					ret.dirs = this.parseDirectives();
					ret.ruleSelection = FragmentSpreadEnum.FD;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an Directives. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an dots. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstInlineFragment() const {
		return this.lex.front.type == TokenType.dots;
	}

	InlineFragmentPtr parseInlineFragment() {
		try {
			return this.parseInlineFragmentImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a InlineFragment an Exception was thrown.", e);
		}
	}

	InlineFragmentPtr parseInlineFragmentImpl() {
		InlineFragmentPtr ret = refCounted!InlineFragment();
		if(this.lex.front.type == TokenType.dots) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.on_) {
				this.lex.popFront();
				if(this.firstTypeCondition()) {
					ret.tc = this.parseTypeCondition();
					if(this.firstDirectives()) {
						ret.dirs = this.parseDirectives();
						if(this.firstSelectionSet()) {
							ret.ss = this.parseSelectionSet();
							ret.ruleSelection = InlineFragmentEnum.TDS;
							return ret;
						}
						throw new ParseException(format(
							"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front.type,this.lex.line, this.lex.column)
						);
					} else if(this.firstSelectionSet()) {
						ret.ss = this.parseSelectionSet();
						ret.ruleSelection = InlineFragmentEnum.TS;
						return ret;
					}
					throw new ParseException(format(
						"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				}
				throw new ParseException(format(
					"Was expecting an TypeCondition. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an on_. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an dots. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstFragmentDefinition() const {
		return this.lex.front.type == TokenType.fragment;
	}

	FragmentDefinitionPtr parseFragmentDefinition() {
		try {
			return this.parseFragmentDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a FragmentDefinition an Exception was thrown.", e);
		}
	}

	FragmentDefinitionPtr parseFragmentDefinitionImpl() {
		FragmentDefinitionPtr ret = refCounted!FragmentDefinition();
		if(this.lex.front.type == TokenType.fragment) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				ret.name = this.lex.front;
				this.lex.popFront();
				if(this.lex.front.type == TokenType.on_) {
					this.lex.popFront();
					if(this.firstTypeCondition()) {
						ret.tc = this.parseTypeCondition();
						if(this.firstDirectives()) {
							ret.dirs = this.parseDirectives();
							if(this.firstSelectionSet()) {
								ret.ss = this.parseSelectionSet();
								ret.ruleSelection = FragmentDefinitionEnum.FTDS;
								return ret;
							}
							throw new ParseException(format(
								"Was expecting an SelectionSet. Found a '%s' at %s:%s.", 
								this.lex.front.type,this.lex.line, this.lex.column)
							);
						} else if(this.firstSelectionSet()) {
							ret.ss = this.parseSelectionSet();
							ret.ruleSelection = FragmentDefinitionEnum.FTS;
							return ret;
						}
						throw new ParseException(format(
							"Was expecting an Directives, or SelectionSet. Found a '%s' at %s:%s.", 
							this.lex.front.type,this.lex.line, this.lex.column)
						);
					}
					throw new ParseException(format(
						"Was expecting an TypeCondition. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				}
				throw new ParseException(format(
					"Was expecting an on_. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an fragment. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstDirective() const {
		return this.lex.front.type == TokenType.at;
	}

	DirectivePtr parseDirective() {
		try {
			return this.parseDirectiveImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Directive an Exception was thrown.", e);
		}
	}

	DirectivePtr parseDirectiveImpl() {
		DirectivePtr ret = refCounted!Directive();
		if(this.lex.front.type == TokenType.at) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				ret.name = this.lex.front;
				this.lex.popFront();
				if(this.lex.front.type == TokenType.colon) {
					this.lex.popFront();
					if(this.firstValueOrVariable()) {
						ret.vv = this.parseValueOrVariable();
						ret.ruleSelection = DirectiveEnum.NVV;
						return ret;
					}
					throw new ParseException(format(
						"Was expecting an ValueOrVariable. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				} else if(this.lex.front.type == TokenType.lparen) {
					this.lex.popFront();
					if(this.firstArgument()) {
						ret.arg = this.parseArgument();
						if(this.lex.front.type == TokenType.rparen) {
							this.lex.popFront();
							ret.ruleSelection = DirectiveEnum.NArg;
							return ret;
						}
						throw new ParseException(format(
							"Was expecting an rparen. Found a '%s' at %s:%s.", 
							this.lex.front.type,this.lex.line, this.lex.column)
						);
					}
					throw new ParseException(format(
						"Was expecting an Argument. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				}
				throw new ParseException(format(
					"Was expecting an colon, or lparen. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an at. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstTypeCondition() const {
		return this.lex.front.type == TokenType.name;
	}

	TypeConditionPtr parseTypeCondition() {
		try {
			return this.parseTypeConditionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a TypeCondition an Exception was thrown.", e);
		}
	}

	TypeConditionPtr parseTypeConditionImpl() {
		TypeConditionPtr ret = refCounted!TypeCondition();
		if(this.lex.front.type == TokenType.name) {
			ret.tname = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = TypeConditionEnum.TN;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstVariableDefinition() const {
		return this.firstVariable();
	}

	VariableDefinitionPtr parseVariableDefinition() {
		try {
			return this.parseVariableDefinitionImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a VariableDefinition an Exception was thrown.", e);
		}
	}

	VariableDefinitionPtr parseVariableDefinitionImpl() {
		VariableDefinitionPtr ret = refCounted!VariableDefinition();
		if(this.firstVariable()) {
			this.parseVariable();
			if(this.lex.front.type == TokenType.colon) {
				this.lex.popFront();
				if(this.firstType()) {
					ret.type = this.parseType();
					if(this.firstDefaultValue()) {
						ret.dvalue = this.parseDefaultValue();
						ret.ruleSelection = VariableDefinitionEnum.VarD;
						return ret;
					}
					throw new ParseException(format(
						"Was expecting an DefaultValue. Found a '%s' at %s:%s.", 
						this.lex.front.type,this.lex.line, this.lex.column)
					);
				}
				throw new ParseException(format(
					"Was expecting an Type. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an colon. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an Variable. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstVariable() const {
		return this.lex.front.type == TokenType.dollar;
	}

	VariablePtr parseVariable() {
		try {
			return this.parseVariableImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Variable an Exception was thrown.", e);
		}
	}

	VariablePtr parseVariableImpl() {
		VariablePtr ret = refCounted!Variable();
		if(this.lex.front.type == TokenType.dollar) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.name) {
				ret.name = this.lex.front;
				this.lex.popFront();
				ret.ruleSelection = VariableEnum.Var;
				return ret;
			}
			throw new ParseException(format(
				"Was expecting an name. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an dollar. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstDefaultValue() const {
		return this.lex.front.type == TokenType.equal;
	}

	DefaultValuePtr parseDefaultValue() {
		try {
			return this.parseDefaultValueImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a DefaultValue an Exception was thrown.", e);
		}
	}

	DefaultValuePtr parseDefaultValueImpl() {
		DefaultValuePtr ret = refCounted!DefaultValue();
		if(this.lex.front.type == TokenType.equal) {
			this.lex.popFront();
			if(this.firstValue()) {
				ret.value = this.parseValue();
				ret.ruleSelection = DefaultValueEnum.DV;
				return ret;
			}
			throw new ParseException(format(
				"Was expecting an Value. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an equal. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstValueOrVariable() const {
		return this.firstValue()
			 || this.firstVariable();
	}

	ValueOrVariablePtr parseValueOrVariable() {
		try {
			return this.parseValueOrVariableImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ValueOrVariable an Exception was thrown.", e);
		}
	}

	ValueOrVariablePtr parseValueOrVariableImpl() {
		ValueOrVariablePtr ret = refCounted!ValueOrVariable();
		if(this.firstValue()) {
			ret.val = this.parseValue();
			ret.ruleSelection = ValueOrVariableEnum.Val;
			return ret;
		} else if(this.firstVariable()) {
			ret.var = this.parseVariable();
			ret.ruleSelection = ValueOrVariableEnum.Var;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an Value, or Variable. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstValue() const {
		return this.lex.front.type == TokenType.stringValue
			 || this.lex.front.type == TokenType.intValue
			 || this.lex.front.type == TokenType.floatValue
			 || this.lex.front.type == TokenType.true_
			 || this.lex.front.type == TokenType.false_
			 || this.firstArray();
	}

	ValuePtr parseValue() {
		try {
			return this.parseValueImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Value an Exception was thrown.", e);
		}
	}

	ValuePtr parseValueImpl() {
		ValuePtr ret = refCounted!Value();
		if(this.lex.front.type == TokenType.stringValue) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = ValueEnum.STR;
			return ret;
		} else if(this.lex.front.type == TokenType.intValue) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = ValueEnum.INT;
			return ret;
		} else if(this.lex.front.type == TokenType.floatValue) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = ValueEnum.FLOAT;
			return ret;
		} else if(this.lex.front.type == TokenType.true_) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = ValueEnum.T;
			return ret;
		} else if(this.lex.front.type == TokenType.false_) {
			ret.tok = this.lex.front;
			this.lex.popFront();
			ret.ruleSelection = ValueEnum.F;
			return ret;
		} else if(this.firstArray()) {
			ret.arr = this.parseArray();
			ret.ruleSelection = ValueEnum.ARR;
			return ret;
		}
		throw new ParseException(format(
			"Was expecting an stringValue, intValue, floatValue, true_, false_, or Array. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstType() const {
		return this.lex.front.type == TokenType.name;
	}

	TypePtr parseType() {
		try {
			return this.parseTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Type an Exception was thrown.", e);
		}
	}

	TypePtr parseTypeImpl() {
		TypePtr ret = refCounted!Type();
		if(this.lex.front.type == TokenType.name) {
			ret.tname = this.lex.front;
			this.lex.popFront();
			if(this.lex.front.type == TokenType.exclamation) {
				this.lex.popFront();
				ret.ruleSelection = TypeEnum.TN;
				return ret;
			}
			throw new ParseException(format(
				"Was expecting an exclamation. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an name. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstListType() const {
		return this.lex.front.type == TokenType.lbrack;
	}

	ListTypePtr parseListType() {
		try {
			return this.parseListTypeImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a ListType an Exception was thrown.", e);
		}
	}

	ListTypePtr parseListTypeImpl() {
		ListTypePtr ret = refCounted!ListType();
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			if(this.firstType()) {
				ret.type = this.parseType();
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();
					ret.ruleSelection = ListTypeEnum.T;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an rbrack. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an Type. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an lbrack. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

	bool firstArray() const {
		return this.lex.front.type == TokenType.lbrack;
	}

	ArrayPtr parseArray() {
		try {
			return this.parseArrayImpl();
		} catch(ParseException e) {
			throw new ParseException("While parsing a Array an Exception was thrown.", e);
		}
	}

	ArrayPtr parseArrayImpl() {
		ArrayPtr ret = refCounted!Array();
		if(this.lex.front.type == TokenType.lbrack) {
			this.lex.popFront();
			if(this.lex.front.type == TokenType.rbrack) {
				this.lex.popFront();
				ret.ruleSelection = ArrayEnum.Empty;
				return ret;
			} else if(this.firstValues()) {
				ret.vals = this.parseValues();
				if(this.lex.front.type == TokenType.rbrack) {
					this.lex.popFront();
					ret.ruleSelection = ArrayEnum.Value;
					return ret;
				}
				throw new ParseException(format(
					"Was expecting an rbrack. Found a '%s' at %s:%s.", 
					this.lex.front.type,this.lex.line, this.lex.column)
				);
			}
			throw new ParseException(format(
				"Was expecting an rbrack, or Values. Found a '%s' at %s:%s.", 
				this.lex.front.type,this.lex.line, this.lex.column)
			);
		}
		throw new ParseException(format(
			"Was expecting an lbrack. Found a '%s' at %s:%s.", 
			this.lex.front.type,this.lex.line, this.lex.column)
		);
	}

}
