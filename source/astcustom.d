module astcustom;

static import std.container.array;
import std.typecons : RefCounted;

import ast;

enum DefinitionsEnum {
	Def,
}

struct Definitions {
	DefinitionsEnum ruleSelection;
	std.container.array.Array!(DefinitionPtr) defs;
}

alias DefinitionsPtr = RefCounted!(Definitions);


enum SelectionsEnum {
	Sel,
}

struct Selections {
	SelectionsEnum ruleSelection;
	std.container.array.Array!(SelectionPtr) sels;
}

alias SelectionsPtr = RefCounted!(Selections);


enum DirectivesEnum {
	Der,
}

struct Directives {
	DirectivesEnum ruleSelection;
	std.container.array.Array!(DirectivePtr) defs;
}

alias DirectivesPtr = RefCounted!(Directives);

enum ArgumentsEnum {
	args,
}

struct Arguments {
	ArgumentsEnum ruleSelection;
	std.container.array.Array!(ArgumentPtr) args;
}

alias ArgumentsPtr = RefCounted!(Arguments);
