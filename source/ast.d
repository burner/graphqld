module ast;

import std.typecons : RefCounted, refCounted;

public import astcustom;

import tokenmodule;

enum DocumentEnum {
	Defi,
}

struct Document {
	DocumentEnum ruleSelection;
	DefinitionsPtr defs;

}

alias DocumentPtr = RefCounted!(Document);

enum DefinitionEnum {
	Op,
	Frag,
}

struct Definition {
	DefinitionEnum ruleSelection;
	OperationDefinitionPtr op;
	FragmentDefinitionPtr frag;

}

alias DefinitionPtr = RefCounted!(Definition);

enum OperationDefinitionEnum {
	SelSet,
	OT_VD,
	OT_V,
	OT_D,
	OT,
}

struct OperationDefinition {
	OperationDefinitionEnum ruleSelection;
	Token name;
	SelectionSetPtr ss;
	DirectivesPtr d;
	OperationTypePtr ot;
	VariableDefinitionsPtr vd;

}

alias OperationDefinitionPtr = RefCounted!(OperationDefinition);

enum SelectionSetEnum {
	SS,
}

struct SelectionSet {
	SelectionSetEnum ruleSelection;
	SelectionsPtr sel;

}

alias SelectionSetPtr = RefCounted!(SelectionSet);

enum OperationTypeEnum {
	Query,
	Mutation,
}

struct OperationType {
	OperationTypeEnum ruleSelection;
	Token tok;

}

alias OperationTypePtr = RefCounted!(OperationType);

enum SelectionEnum {
	Field,
	Frag,
	IFrag,
}

struct Selection {
	SelectionEnum ruleSelection;
	InlineFragmentPtr ifrag;
	FragmentSpreadPtr frag;
	FieldPtr field;

}

alias SelectionPtr = RefCounted!(Selection);

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

struct Field {
	FieldEnum ruleSelection;
	ArgumentsPtr args;
	FieldNamePtr name;
	SelectionSetPtr ss;
	DirectivesPtr dirs;

}

alias FieldPtr = RefCounted!(Field);

enum FieldNameEnum {
	A,
	N,
}

struct FieldName {
	FieldNameEnum ruleSelection;
	Token tok;

}

alias FieldNamePtr = RefCounted!(FieldName);

enum AliasEnum {
	A,
}

struct Alias {
	AliasEnum ruleSelection;
	Token to;
	Token from;

}

alias AliasPtr = RefCounted!(Alias);

enum ArgumentEnum {
	Name,
}

struct Argument {
	ArgumentEnum ruleSelection;
	Token name;

}

alias ArgumentPtr = RefCounted!(Argument);

enum FragmentSpreadEnum {
	FD,
	F,
}

struct FragmentSpread {
	FragmentSpreadEnum ruleSelection;
	Token name;
	DirectivesPtr dirs;

}

alias FragmentSpreadPtr = RefCounted!(FragmentSpread);

enum InlineFragmentEnum {
	TDS,
	TS,
}

struct InlineFragment {
	InlineFragmentEnum ruleSelection;
	TypeConditionPtr tc;
	SelectionSetPtr ss;
	DirectivesPtr dirs;

}

alias InlineFragmentPtr = RefCounted!(InlineFragment);

enum FragmentDefinitionEnum {
	FTDS,
	FTS,
}

struct FragmentDefinition {
	FragmentDefinitionEnum ruleSelection;
	TypeConditionPtr tc;
	Token name;
	SelectionSetPtr ss;
	DirectivesPtr dirs;

}

alias FragmentDefinitionPtr = RefCounted!(FragmentDefinition);

enum DirectiveEnum {
	NVV,
	NArg,
	N,
}

struct Directive {
	DirectiveEnum ruleSelection;
	ValueOrVariablePtr vv;
	Token name;
	ArgumentPtr arg;

}

alias DirectivePtr = RefCounted!(Directive);

enum TypeConditionEnum {
	TN,
}

struct TypeCondition {
	TypeConditionEnum ruleSelection;
	Token tname;

}

alias TypeConditionPtr = RefCounted!(TypeCondition);

enum VariableDefinitionEnum {
	VarD,
	Var,
}

struct VariableDefinition {
	VariableDefinitionEnum ruleSelection;
	TypePtr type;
	DefaultValuePtr dvalue;

}

alias VariableDefinitionPtr = RefCounted!(VariableDefinition);

enum VariableEnum {
	Var,
}

struct Variable {
	VariableEnum ruleSelection;
	Token name;

}

alias VariablePtr = RefCounted!(Variable);

enum DefaultValueEnum {
	DV,
}

struct DefaultValue {
	DefaultValueEnum ruleSelection;
	ValuePtr value;

}

alias DefaultValuePtr = RefCounted!(DefaultValue);

enum ValueOrVariableEnum {
	Val,
	Var,
}

struct ValueOrVariable {
	ValueOrVariableEnum ruleSelection;
	ValuePtr val;
	VariablePtr var;

}

alias ValueOrVariablePtr = RefCounted!(ValueOrVariable);

enum ValueEnum {
	STR,
	INT,
	FLOAT,
	T,
	F,
	ARR,
	O,
}

struct Value {
	ValueEnum ruleSelection;
	ArrayPtr arr;
	Token tok;
	ObjectTypePtr obj;

}

alias ValuePtr = RefCounted!(Value);

enum TypeEnum {
	TN,
	T,
}

struct Type {
	TypeEnum ruleSelection;
	Token tname;

}

alias TypePtr = RefCounted!(Type);

enum ListTypeEnum {
	T,
}

struct ListType {
	ListTypeEnum ruleSelection;
	TypePtr type;

}

alias ListTypePtr = RefCounted!(ListType);

enum ArrayEnum {
	Empty,
	Value,
}

struct Array {
	ArrayEnum ruleSelection;
	ValuesPtr vals;

}

alias ArrayPtr = RefCounted!(Array);

enum ObjectValueEnum {
	V,
}

struct ObjectValue {
	ObjectValueEnum ruleSelection;
	Token name;
	ValuePtr val;

}

alias ObjectValuePtr = RefCounted!(ObjectValue);

