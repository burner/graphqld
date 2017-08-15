module exception;

class ParseException : Exception {
	int line;
	this(string msg) {
		super(msg);
	}

	this(string msg, string f, int l) {
		super(msg, f, l);
		this.line = l;
	}

	this(string msg, ParseException other) {
		super(msg, other);
	}

	this(string msg, ParseException other, string f, int l) {
		super(msg, f, l, other);
		this.line = l;
	}

	override string toString() {
		import std.format : format;
		return format("%s at %d:", super.msg, this.line);
	}
}
