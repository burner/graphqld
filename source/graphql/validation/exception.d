module graphql.validation.exception;

@safe:

class ValidationException : Exception {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class FragmentNotFoundException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class FragmentCycleException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class FragmentNameAlreadyInUseException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class UnusedFragmentsException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class LoneAnonymousOperationException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class NonUniqueOperationNameException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class NoTypeSystemDefinitionException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class ArgumentsNotUniqueException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class VariablesNotUniqueException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class VariablesUseException : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class SingleRootField : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

class FieldDoesNotExist : ValidationException {
	this(string msg, string f, size_t l) {
		super(msg, f, l);
	}
}

