module schema.directives;

@safe:

interface DefaultDirectives {
	void skip(bool _if);
	void include(bool _if);
}
