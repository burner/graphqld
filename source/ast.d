module ast;

import std.typecons : RefCounted, refCounted;

import tokenmodule;

enum DocumentEnum {
	Defi,
}

class Document {
	DocumentEnum ruleSelection;
	Definitions defs;

	this(DocumentEnum ruleSelection, Definitions defs) {
		this.ruleSelection = ruleSelection;
		this.defs = defs;
	}

}

enum DefinitionsEnum {
	Def,
	Defs,
}

class Definitions {
	DefinitionsEnum ruleSelection;
	Definition def;
	Definitions follow;

	this(DefinitionsEnum ruleSelection, Definition def) {
		this.ruleSelection = ruleSelection;
		this.def = def;
	}

	this(DefinitionsEnum ruleSelection, Definition def, Definitions follow) {
		this.ruleSelection = ruleSelection;
		this.def = def;
		this.follow = follow;
	}

}

enum DefinitionEnum {
	Op,
	Frag,
}

class Definition {
	DefinitionEnum ruleSelection;
	OperationDefinition op;
	FragmentDefinition frag;

	this(DefinitionEnum ruleSelection, OperationDefinition op) {
		this.ruleSelection = ruleSelection;
		this.op = op;
	}

	this(DefinitionEnum ruleSelection, FragmentDefinition frag) {
		this.ruleSelection = ruleSelection;
		this.frag = frag;
	}

}

enum OperationDefinitionEnum {
	SelSet,
	OT_VD,
	OT_V,
	OT_D,
	OT,
}

class OperationDefinition {
	OperationDefinitionEnum ruleSelection;
	Token name;
	SelectionSet ss;
	Directives d;
	OperationType ot;
	VariableDefinitions vd;

	this(OperationDefinitionEnum ruleSelection, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, Token name, VariableDefinitions vd, Directives d, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.name = name;
		this.vd = vd;
		this.d = d;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, Token name, VariableDefinitions vd, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.name = name;
		this.vd = vd;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, Token name, Directives d, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.name = name;
		this.d = d;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, Token name, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.name = name;
		this.ss = ss;
	}

}

enum SelectionSetEnum {
	Empty,
	SS,
}

class SelectionSet {
	SelectionSetEnum ruleSelection;
	Selections sel;

	this(SelectionSetEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	this(SelectionSetEnum ruleSelection, Selections sel) {
		this.ruleSelection = ruleSelection;
		this.sel = sel;
	}

}

enum OperationTypeEnum {
	Query,
	Mutation,
	Sub,
}

class OperationType {
	OperationTypeEnum ruleSelection;
	Token tok;

	this(OperationTypeEnum ruleSelection, Token tok) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
	}

}

enum SelectionsEnum {
	Sel,
	Sels,
	Selsc,
}

class Selections {
	SelectionsEnum ruleSelection;
	Selection sel;
	Selections follow;

	this(SelectionsEnum ruleSelection, Selection sel) {
		this.ruleSelection = ruleSelection;
		this.sel = sel;
	}

	this(SelectionsEnum ruleSelection, Selection sel, Selections follow) {
		this.ruleSelection = ruleSelection;
		this.sel = sel;
		this.follow = follow;
	}

}

enum SelectionEnum {
	Field,
	Frag,
	IFrag,
}

class Selection {
	SelectionEnum ruleSelection;
	InlineFragment ifrag;
	FragmentSpread frag;
	Field field;

	this(SelectionEnum ruleSelection, Field field) {
		this.ruleSelection = ruleSelection;
		this.field = field;
	}

	this(SelectionEnum ruleSelection, FragmentSpread frag) {
		this.ruleSelection = ruleSelection;
		this.frag = frag;
	}

	this(SelectionEnum ruleSelection, InlineFragment ifrag) {
		this.ruleSelection = ruleSelection;
		this.ifrag = ifrag;
	}

}

enum FieldEnum {
	FADS,
	FAS,
	FAD,
	FDS,
	FS,
	FD,
	FA,
	F,
}

class Field {
	FieldEnum ruleSelection;
	Arguments args;
	FieldName name;
	SelectionSet ss;
	Directives dirs;

	this(FieldEnum ruleSelection, FieldName name, Arguments args, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.args = args;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(FieldEnum ruleSelection, FieldName name, Arguments args, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.args = args;
		this.ss = ss;
	}

	this(FieldEnum ruleSelection, FieldName name, Arguments args, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.args = args;
		this.dirs = dirs;
	}

	this(FieldEnum ruleSelection, FieldName name, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(FieldEnum ruleSelection, FieldName name, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.ss = ss;
	}

	this(FieldEnum ruleSelection, FieldName name, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
	}

	this(FieldEnum ruleSelection, FieldName name, Arguments args) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.args = args;
	}

	this(FieldEnum ruleSelection, FieldName name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

}

enum FieldNameEnum {
	A,
	N,
}

class FieldName {
	FieldNameEnum ruleSelection;
	Token tok;
	Token aka;

	this(FieldNameEnum ruleSelection, Token tok, Token aka) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
		this.aka = aka;
	}

	this(FieldNameEnum ruleSelection, Token tok) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
	}

}

enum ArgumentsEnum {
	Arg,
	Args,
}

class Arguments {
	ArgumentsEnum ruleSelection;
	Argument arg;
	Arguments follow;

	this(ArgumentsEnum ruleSelection, Argument arg) {
		this.ruleSelection = ruleSelection;
		this.arg = arg;
	}

	this(ArgumentsEnum ruleSelection, Argument arg, Arguments follow) {
		this.ruleSelection = ruleSelection;
		this.arg = arg;
		this.follow = follow;
	}

}

enum ArgumentEnum {
	Name,
}

class Argument {
	ArgumentEnum ruleSelection;
	Token name;

	this(ArgumentEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

}

enum FragmentSpreadEnum {
	FD,
	F,
}

class FragmentSpread {
	FragmentSpreadEnum ruleSelection;
	Token name;
	Directives dirs;

	this(FragmentSpreadEnum ruleSelection, Token name, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
	}

	this(FragmentSpreadEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

}

enum InlineFragmentEnum {
	TDS,
	TS,
}

class InlineFragment {
	InlineFragmentEnum ruleSelection;
	TypeCondition tc;
	SelectionSet ss;
	Directives dirs;

	this(InlineFragmentEnum ruleSelection, TypeCondition tc, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.tc = tc;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(InlineFragmentEnum ruleSelection, TypeCondition tc, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.tc = tc;
		this.ss = ss;
	}

}

enum FragmentDefinitionEnum {
	FTDS,
	FTS,
}

class FragmentDefinition {
	FragmentDefinitionEnum ruleSelection;
	TypeCondition tc;
	Token name;
	SelectionSet ss;
	Directives dirs;

	this(FragmentDefinitionEnum ruleSelection, Token name, TypeCondition tc, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.tc = tc;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(FragmentDefinitionEnum ruleSelection, Token name, TypeCondition tc, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.tc = tc;
		this.ss = ss;
	}

}

enum DirectivesEnum {
	Dir,
	Dirs,
}

class Directives {
	DirectivesEnum ruleSelection;
	Directive dir;
	Directives follow;

	this(DirectivesEnum ruleSelection, Directive dir) {
		this.ruleSelection = ruleSelection;
		this.dir = dir;
	}

	this(DirectivesEnum ruleSelection, Directive dir, Directives follow) {
		this.ruleSelection = ruleSelection;
		this.dir = dir;
		this.follow = follow;
	}

}

enum DirectiveEnum {
	NVV,
	NArg,
	N,
}

class Directive {
	DirectiveEnum ruleSelection;
	ValueOrVariable vv;
	Token name;
	Argument arg;

	this(DirectiveEnum ruleSelection, Token name, ValueOrVariable vv) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.vv = vv;
	}

	this(DirectiveEnum ruleSelection, Token name, Argument arg) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.arg = arg;
	}

	this(DirectiveEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

}

enum TypeConditionEnum {
	TN,
}

class TypeCondition {
	TypeConditionEnum ruleSelection;
	Token tname;

	this(TypeConditionEnum ruleSelection, Token tname) {
		this.ruleSelection = ruleSelection;
		this.tname = tname;
	}

}

enum VariableDefinitionsEnum {
	Empty,
	Vars,
}

class VariableDefinitions {
	VariableDefinitionsEnum ruleSelection;
	VariableDefinitionList vars;

	this(VariableDefinitionsEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	this(VariableDefinitionsEnum ruleSelection, VariableDefinitionList vars) {
		this.ruleSelection = ruleSelection;
		this.vars = vars;
	}

}

enum VariableDefinitionListEnum {
	Var,
	Vars,
}

class VariableDefinitionList {
	VariableDefinitionListEnum ruleSelection;
	VariableDefinition var;
	VariableDefinitionList follow;

	this(VariableDefinitionListEnum ruleSelection, VariableDefinition var) {
		this.ruleSelection = ruleSelection;
		this.var = var;
	}

	this(VariableDefinitionListEnum ruleSelection, VariableDefinition var, VariableDefinitionList follow) {
		this.ruleSelection = ruleSelection;
		this.var = var;
		this.follow = follow;
	}

}

enum VariableDefinitionEnum {
	VarD,
	Var,
}

class VariableDefinition {
	VariableDefinitionEnum ruleSelection;
	Type type;
	DefaultValue dvalue;

	this(VariableDefinitionEnum ruleSelection, Type type, DefaultValue dvalue) {
		this.ruleSelection = ruleSelection;
		this.type = type;
		this.dvalue = dvalue;
	}

	this(VariableDefinitionEnum ruleSelection, Type type) {
		this.ruleSelection = ruleSelection;
		this.type = type;
	}

}

enum VariableEnum {
	Var,
}

class Variable {
	VariableEnum ruleSelection;
	Token name;

	this(VariableEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

}

enum DefaultValueEnum {
	DV,
}

class DefaultValue {
	DefaultValueEnum ruleSelection;
	Value value;

	this(DefaultValueEnum ruleSelection, Value value) {
		this.ruleSelection = ruleSelection;
		this.value = value;
	}

}

enum ValueOrVariableEnum {
	Val,
	Var,
}

class ValueOrVariable {
	ValueOrVariableEnum ruleSelection;
	Value val;
	Variable var;

	this(ValueOrVariableEnum ruleSelection, Value val) {
		this.ruleSelection = ruleSelection;
		this.val = val;
	}

	this(ValueOrVariableEnum ruleSelection, Variable var) {
		this.ruleSelection = ruleSelection;
		this.var = var;
	}

}

enum ValueEnum {
	STR,
	INT,
	FLOAT,
	T,
	F,
	ARR,
	O,
}

class Value {
	ValueEnum ruleSelection;
	Array arr;
	Token tok;
	ObjectType obj;

	this(ValueEnum ruleSelection, Token tok) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
	}

	this(ValueEnum ruleSelection, Array arr) {
		this.ruleSelection = ruleSelection;
		this.arr = arr;
	}

	this(ValueEnum ruleSelection, ObjectType obj) {
		this.ruleSelection = ruleSelection;
		this.obj = obj;
	}

}

enum TypeEnum {
	TN,
	T,
	LN,
	L,
}

class Type {
	TypeEnum ruleSelection;
	Token tname;
	ListType list;

	this(TypeEnum ruleSelection, Token tname) {
		this.ruleSelection = ruleSelection;
		this.tname = tname;
	}

	this(TypeEnum ruleSelection, ListType list) {
		this.ruleSelection = ruleSelection;
		this.list = list;
	}

}

enum ListTypeEnum {
	T,
}

class ListType {
	ListTypeEnum ruleSelection;
	Type type;

	this(ListTypeEnum ruleSelection, Type type) {
		this.ruleSelection = ruleSelection;
		this.type = type;
	}

}

enum ValuesEnum {
	Val,
	Vals,
}

class Values {
	ValuesEnum ruleSelection;
	Value val;
	Values follow;

	this(ValuesEnum ruleSelection, Value val) {
		this.ruleSelection = ruleSelection;
		this.val = val;
	}

	this(ValuesEnum ruleSelection, Value val, Values follow) {
		this.ruleSelection = ruleSelection;
		this.val = val;
		this.follow = follow;
	}

}

enum ArrayEnum {
	Empty,
	Value,
}

class Array {
	ArrayEnum ruleSelection;
	Values vals;

	this(ArrayEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	this(ArrayEnum ruleSelection, Values vals) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
	}

}

enum ObjectValuesEnum {
	V,
	Vsc,
	Vs,
}

class ObjectValues {
	ObjectValuesEnum ruleSelection;
	Token name;
	Value val;
	ObjectValues follow;

	this(ObjectValuesEnum ruleSelection, Token name, Value val) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.val = val;
	}

	this(ObjectValuesEnum ruleSelection, Token name, Value val, ObjectValues follow) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.val = val;
		this.follow = follow;
	}

}

enum ObjectValueEnum {
	V,
}

class ObjectValue {
	ObjectValueEnum ruleSelection;
	Token name;
	Value val;

	this(ObjectValueEnum ruleSelection, Token name, Value val) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.val = val;
	}

}

enum ObjectTypeEnum {
	Var,
}

class ObjectType {
	ObjectTypeEnum ruleSelection;
	ObjectValues vals;

	this(ObjectTypeEnum ruleSelection, ObjectValues vals) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
	}

}

