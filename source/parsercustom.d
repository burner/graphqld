module parsercustom;

import parser;

bool firstDefinitions(ref Parser this_) {
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
	DefinitionsPtr ret = refCounted!Definitions();
	ret.ruleSelection = DefinitionsEnum.Def;
	while(this_.firstDefinition()) {
		ret.def ~= this_.parseDefinition();
	}
	return ret;
}

bool firstSelections(ref Parser this_) {
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
	SelectionsPtr ret = refCounted!Selections();
	if(this_.firstSelection()) {
		ret.sels ~= this_.parseSelection();
		while(this_.lex.front.type == TokenType.comma 
			|| this_.firstSelection()) 
		{
			if(this_.lex.front.type == TokenType.comma) {
				this_.popFront();
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

bool firstDirectives(ref Parser this_) {
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
	DirectivesPtr ret = refCounted!Directives();
	ret.ruleSelection = DirectivesEnum.Def;
	while(this_.firstDirective()) {
		ret.dir ~= this_.parseDirective();
	}
	return ret;
}

bool firstArguments(ref Parser this_) {
	return this_.firstArgument();
}

ArgumentsPtr parseArguments(ref Parser this_) {
	try {
		return this_.parseArgumentsImpl();
	} catch(ParseException e) {
		throw new ParseException("While parsing a Arguments an Exception was thrown.", e);
	}
}

ArgumentsPtr parseArgumentsImpl(ref Parser this_) {
	ArgumentsPtr ret = refCounted!Arguments();
	if(this_.lex.front.type == TokenType.lparen) {
		this_.popFront();
		if(this_.firstArgument()) {
			ret.args ~= this_.parseArgument();
			while(this_.lex.front.type == TokenType.comma) {
				this_.popFront();
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
				this_.popFront();
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

bool firstValues(ref Parser this_) {
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
	ValuesPtr ret = refCounted!Values();
	if(this_.firstValue()) {
		ret.vals ~= this_.parseValue();
		while(this_.lex.front.type == TokenType.comma) {
			this_.popFront();
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
