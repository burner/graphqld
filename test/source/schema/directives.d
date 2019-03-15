module schema.directives;

interface DefaultDirectives {
	void skip(_if: bool);
	void include(_if: bool);
}
