module graphql.exception;


class ParseException : Exception {
@safe:

	int line;
	string[] subRules;
	string[] follows;

	this(string msg) {
		super(msg);
	}

	this(string msg, string f, int l, string[] subRules, string[] follows) {
		import std.format : format;
		super(format(
			"%s [%(%s,%)]: While in subRules [%(%s, %)] at %s:%s",
			msg, follows, subRules, f, l), f, l
		);
		this.line = l;
		this.subRules = subRules;
		this.follows = follows;
	}

	this(string msg, ParseException other) {
		super(msg, other);
	}

	this(string msg, ParseException other, string f, int l) {
		super(msg, f, l, other);
		this.line = l;
	}
}

@safe:
class GQLDExecutionException : Exception {
	this(string msg, string f = __FILE__, size_t l = __LINE__) {
		super(msg, f, l);
		this.line = l;
	}
}
