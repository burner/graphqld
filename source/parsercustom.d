module parsercustom;

import std.typecons : RefCounted, refCounted;
import std.format : format;

import tokenmodule;
import parser;
import ast;
import astcustom;
import exception;

bool firstDefinitions(ref const(Parser) this_) {
	return this_.firstDefinition();
}

DefinitionsPtr parseDefinitions(ref Parser this_) {
	try {
		return this_.parseDefinitionsImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a Definitions an Exception was thrown.", e);
	}
}

DefinitionsPtr parseDefinitionsImpl(ref Parser this_) {
	DefinitionsPtr ret = refCounted!Definitions(Definitions());
	ret.ruleSelection = DefinitionsEnum.Def;
	while(this_.firstDefinition()) {
		ret.defs ~= this_.parseDefinition();
	}
	return ret;
}

bool firstSelections(ref const(Parser) this_) {
	return this_.firstSelection();
}

SelectionsPtr parseSelections(ref Parser this_) {
	try {
		return this_.parseSelectionsImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a Selections an Exception was thrown.", e);
	}
}

SelectionsPtr parseSelectionsImpl(ref Parser this_) {
	SelectionsPtr ret = refCounted!Selections(Selections());
	if(this_.firstSelection()) {
		ret.sels ~= this_.parseSelection();
		while(this_.lex.front.type == TokenType.comma 
			|| this_.firstSelection()) 
		{
			if(this_.lex.front.type == TokenType.comma) {
				this_.lex.popFront();
			}
			if(this_.firstSelection()) {
				ret.sels ~= this_.parseSelection();
				continue;
			}
			throw new ParseException(format(
				"Was expecting an Selection. Found a '%s' at %s:%s.", 
				this_.lex.front.type,this_.lex.line, this_.lex.column)
			);
		}
		return ret;
	}
	throw new ParseException(format(
		"Was expecting an Selection. Found a '%s' at %s:%s.", 
		this_.lex.front.type,this_.lex.line, this_.lex.column)
	);
}

bool firstDirectives(ref const(Parser) this_) {
	return this_.firstDirective();
}

DirectivesPtr parseDirectives(ref Parser this_) {
	try {
		return this_.parseDirectivesImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a Directives an Exception was thrown.", e);
	}
}

DirectivesPtr parseDirectivesImpl(ref Parser this_) {
	DirectivesPtr ret = refCounted!Directives(Directives());
	ret.ruleSelection = DirectivesEnum.Der;
	while(this_.firstDirective()) {
		ret.dirs ~= this_.parseDirective();
	}
	return ret;
}

bool firstArguments(ref const(Parser) this_) {
	return this_.lex.front.type == TokenType.lparen;
}

ArgumentsPtr parseArguments(ref Parser this_) {
	try {
		return this_.parseArgumentsImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a Arguments an Exception was thrown.", e);
	}
}

ArgumentsPtr parseArgumentsImpl(ref Parser this_) {
	ArgumentsPtr ret = refCounted!Arguments(Arguments());
	if(this_.lex.front.type == TokenType.lparen) {
		this_.lex.popFront();
		if(this_.firstArgument()) {
			ret.args ~= this_.parseArgument();
			while(this_.lex.front.type == TokenType.comma) {
				this_.lex.popFront();
				if(this_.firstArgument()) {
					ret.args ~= this_.parseArgument();
					continue;
				}
				throw new ParseException(format(
					"Was expecting an Argument. Found a '%s' at %s:%s.", 
					this_.lex.front.type,this_.lex.line, this_.lex.column)
				);
			}
			if(this_.lex.front.type == TokenType.rparen) {
				this_.lex.popFront();
				return ret;
			}
			throw new ParseException(format(
				"Was expecting an rparen. Found a '%s' at %s:%s.", 
				this_.lex.front.type,this_.lex.line, this_.lex.column)
			);
		}
	}
	throw new ParseException(format(
		"Was expecting an lparen. Found a '%s' at %s:%s.", 
		this_.lex.front.type,this_.lex.line, this_.lex.column)
	);
}

bool firstValues(ref const(Parser) this_) {
	return this_.firstValue();
}

ValuesPtr parseValues(ref Parser this_) {
	try {
		return this_.parseValuesImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a Values an Exception was thrown.", e);
	}
}

ValuesPtr parseValuesImpl(ref Parser this_) {
	ValuesPtr ret = refCounted!Values(Values());
	if(this_.firstValue()) {
		ret.vals ~= this_.parseValue();
		while(this_.lex.front.type == TokenType.comma) {
			this_.lex.popFront();
			if(this_.firstValue()) {
				ret.vals ~= this_.parseValue();
				continue;
			}
			throw new ParseException(format(
				"Was expecting an Value. Found a '%s' at %s:%s.", 
				this_.lex.front.type,this_.lex.line, this_.lex.column)
			);
		}
		return ret;
	}
	throw new ParseException(format(
		"Was expecting an Value. Found a '%s' at %s:%s.", 
		this_.lex.front.type,this_.lex.line, this_.lex.column)
	);
}

bool firstVariableDefinitions(ref const(Parser) this_) {
	return this_.firstVariableDefinition();
}

VariableDefinitionsPtr parseVariableDefinitions(ref Parser this_) {
	try {
		return this_.parseVariableDefinitionsImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a VariableDefinitions an Exception was thrown.", e);
	}
}

VariableDefinitionsPtr parseVariableDefinitionsImpl(ref Parser this_) {
	VariableDefinitionsPtr ret = refCounted!VariableDefinitions(VariableDefinitions());
	if(this_.lex.front.type == TokenType.lparen) {
		this_.lex.popFront();
		if(this_.firstVariableDefinition()) {
			ret.vars ~= this_.parseVariableDefinition();
			while(this_.lex.front.type == TokenType.comma) {
				this_.lex.popFront();
				if(this_.firstVariableDefinition()) {
					ret.vars ~= this_.parseVariableDefinition();
					continue;
				}
				throw new ParseException(format(
					"Was expecting an VariableDefinition. Found a '%s' at %s:%s.", 
					this_.lex.front.type,this_.lex.line, this_.lex.column)
				);
			}
			if(this_.lex.front.type == TokenType.rparen) {
				this_.lex.popFront();
				return ret;
			}
			throw new ParseException(format(
				"Was expecting an rparen. Found a '%s' at %s:%s.", 
				this_.lex.front.type,this_.lex.line, this_.lex.column)
			);
		}
	}
	throw new ParseException(format(
		"Was expecting an lparen. Found a '%s' at %s:%s.", 
		this_.lex.front.type,this_.lex.line, this_.lex.column)
	);
}
