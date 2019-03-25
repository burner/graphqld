module graphql.validation.exception;

@safe:

class ValidationException : Exception {
	this(string msg, string f, size_t l) {
		import std.format : format;
		super(msg, f, l);
	}
}

class FragmentNotFoundException : ValidationException {
	this(string msg, string f, size_t l) {
		import std.format : format;
		super(msg, f, l);
	}
}

class FragmentCycleException : ValidationException {
	this(string msg, string f, size_t l) {
		import std.format : format;
		super(msg, f, l);
	}
}

class FragmentNameAlreadyInUseException : ValidationException {
	this(string msg, string f, size_t l) {
		import std.format : format;
		super(msg, f, l);
	}
}
