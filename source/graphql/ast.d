module graphql.ast;

import graphql.tokenmodule;

import graphql.visitor;

@safe :

class Node {}

enum DocumentEnum {
	Defi,
}

class Document : Node {
@safe :

	DocumentEnum ruleSelection;
	Definitions defs;

	this(DocumentEnum ruleSelection, Definitions defs) {
		this.ruleSelection = ruleSelection;
		this.defs = defs;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DefinitionsEnum {
	Def,
	Defs,
}

class Definitions : Node {
@safe :

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DefinitionEnum {
	O,
	F,
	T,
}

class Definition : Node {
@safe :

	DefinitionEnum ruleSelection;
	FragmentDefinition frag;
	TypeSystemDefinition type;
	OperationDefinition op;

	this(DefinitionEnum ruleSelection, OperationDefinition op) {
		this.ruleSelection = ruleSelection;
		this.op = op;
	}

	this(DefinitionEnum ruleSelection, FragmentDefinition frag) {
		this.ruleSelection = ruleSelection;
		this.frag = frag;
	}

	this(DefinitionEnum ruleSelection, TypeSystemDefinition type) {
		this.ruleSelection = ruleSelection;
		this.type = type;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OperationDefinitionEnum {
	SelSet,
	OT_N_VD,
	OT_N_V,
	OT_N_D,
	OT_N,
	OT_VD,
	OT_V,
	OT_D,
	OT,
}

class OperationDefinition : Node {
@safe :

	OperationDefinitionEnum ruleSelection;
	VariableDefinitions vd;
	OperationType ot;
	Directives d;
	SelectionSet ss;
	Token name;

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

	this(OperationDefinitionEnum ruleSelection, OperationType ot, VariableDefinitions vd, Directives d, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.vd = vd;
		this.d = d;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, VariableDefinitions vd, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.vd = vd;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, Directives d, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.d = d;
		this.ss = ss;
	}

	this(OperationDefinitionEnum ruleSelection, OperationType ot, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.ss = ss;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum SelectionSetEnum {
	SS,
}

class SelectionSet : Node {
@safe :

	SelectionSetEnum ruleSelection;
	Selections sel;

	this(SelectionSetEnum ruleSelection, Selections sel) {
		this.ruleSelection = ruleSelection;
		this.sel = sel;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OperationTypeEnum {
	Query,
	Mutation,
	Sub,
}

class OperationType : Node {
@safe :

	OperationTypeEnum ruleSelection;
	Token tok;

	this(OperationTypeEnum ruleSelection, Token tok) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum SelectionsEnum {
	Sel,
	Sels,
	Selsc,
}

class Selections : Node {
@safe :

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum SelectionEnum {
	Field,
	Spread,
	IFrag,
}

class Selection : Node {
@safe :

	SelectionEnum ruleSelection;
	FragmentSpread frag;
	Field field;
	InlineFragment ifrag;

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum FragmentSpreadEnum {
	FD,
	F,
}

class FragmentSpread : Node {
@safe :

	FragmentSpreadEnum ruleSelection;
	Directives dirs;
	Token name;

	this(FragmentSpreadEnum ruleSelection, Token name, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
	}

	this(FragmentSpreadEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum InlineFragmentEnum {
	TDS,
	TS,
	DS,
	S,
}

class InlineFragment : Node {
@safe :

	InlineFragmentEnum ruleSelection;
	Token tc;
	Directives dirs;
	SelectionSet ss;

	this(InlineFragmentEnum ruleSelection, Token tc, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.tc = tc;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(InlineFragmentEnum ruleSelection, Token tc, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.tc = tc;
		this.ss = ss;
	}

	this(InlineFragmentEnum ruleSelection, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(InlineFragmentEnum ruleSelection, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.ss = ss;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
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

class Field : Node {
@safe :

	FieldEnum ruleSelection;
	SelectionSet ss;
	Arguments args;
	Directives dirs;
	FieldName name;

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum FieldNameEnum {
	A,
	N,
}

class FieldName : Node {
@safe :

	FieldNameEnum ruleSelection;
	Token aka;
	Identifier name;

	this(FieldNameEnum ruleSelection, Identifier name, Token aka) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.aka = aka;
	}

	this(FieldNameEnum ruleSelection, Identifier name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum IdentifierEnum {
	I,
	Mutation,
	Subscription,
	Scalar,
	Schema,
	On,
	Directive,
	Enum,
	Extend,
	Input,
	Interface,
	Implements,
	False,
	Fragment,
	Query,
	True,
	Type,
	Null,
	Union,
}

class Identifier : Node {
@safe :

	IdentifierEnum ruleSelection;
	Token tok;

	this(IdentifierEnum ruleSelection, Token tok) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ArgumentsEnum {
	List,
	Empty,
}

class Arguments : Node {
@safe :

	ArgumentsEnum ruleSelection;
	ArgumentList arg;

	this(ArgumentsEnum ruleSelection, ArgumentList arg) {
		this.ruleSelection = ruleSelection;
		this.arg = arg;
	}

	this(ArgumentsEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ArgumentListEnum {
	A,
	ACS,
	AS,
}

class ArgumentList : Node {
@safe :

	ArgumentListEnum ruleSelection;
	Argument arg;
	ArgumentList follow;

	this(ArgumentListEnum ruleSelection, Argument arg) {
		this.ruleSelection = ruleSelection;
		this.arg = arg;
	}

	this(ArgumentListEnum ruleSelection, Argument arg, ArgumentList follow) {
		this.ruleSelection = ruleSelection;
		this.arg = arg;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ArgumentEnum {
	Name,
}

class Argument : Node {
@safe :

	ArgumentEnum ruleSelection;
	ValueOrVariable vv;
	Token name;

	this(ArgumentEnum ruleSelection, Token name, ValueOrVariable vv) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.vv = vv;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum FragmentDefinitionEnum {
	FTDS,
	FTS,
}

class FragmentDefinition : Node {
@safe :

	FragmentDefinitionEnum ruleSelection;
	SelectionSet ss;
	Token tc;
	Directives dirs;
	Token name;

	this(FragmentDefinitionEnum ruleSelection, Token name, Token tc, Directives dirs, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.tc = tc;
		this.dirs = dirs;
		this.ss = ss;
	}

	this(FragmentDefinitionEnum ruleSelection, Token name, Token tc, SelectionSet ss) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.tc = tc;
		this.ss = ss;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DirectivesEnum {
	Dir,
	Dirs,
}

class Directives : Node {
@safe :

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DirectiveEnum {
	NArg,
	N,
}

class Directive : Node {
@safe :

	DirectiveEnum ruleSelection;
	Arguments arg;
	Token name;

	this(DirectiveEnum ruleSelection, Token name, Arguments arg) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.arg = arg;
	}

	this(DirectiveEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum VariableDefinitionsEnum {
	Empty,
	Vars,
}

class VariableDefinitions : Node {
@safe :

	VariableDefinitionsEnum ruleSelection;
	VariableDefinitionList vars;

	this(VariableDefinitionsEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	this(VariableDefinitionsEnum ruleSelection, VariableDefinitionList vars) {
		this.ruleSelection = ruleSelection;
		this.vars = vars;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum VariableDefinitionListEnum {
	V,
	VCF,
	VF,
}

class VariableDefinitionList : Node {
@safe :

	VariableDefinitionListEnum ruleSelection;
	VariableDefinitionList follow;
	VariableDefinition var;

	this(VariableDefinitionListEnum ruleSelection, VariableDefinition var) {
		this.ruleSelection = ruleSelection;
		this.var = var;
	}

	this(VariableDefinitionListEnum ruleSelection, VariableDefinition var, VariableDefinitionList follow) {
		this.ruleSelection = ruleSelection;
		this.var = var;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum VariableDefinitionEnum {
	VarD,
	Var,
}

class VariableDefinition : Node {
@safe :

	VariableDefinitionEnum ruleSelection;
	Type type;
	DefaultValue dvalue;
	Variable var;

	this(VariableDefinitionEnum ruleSelection, Variable var, Type type, DefaultValue dvalue) {
		this.ruleSelection = ruleSelection;
		this.var = var;
		this.type = type;
		this.dvalue = dvalue;
	}

	this(VariableDefinitionEnum ruleSelection, Variable var, Type type) {
		this.ruleSelection = ruleSelection;
		this.var = var;
		this.type = type;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum VariableEnum {
	Var,
}

class Variable : Node {
@safe :

	VariableEnum ruleSelection;
	Token name;

	this(VariableEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DefaultValueEnum {
	DV,
}

class DefaultValue : Node {
@safe :

	DefaultValueEnum ruleSelection;
	Value value;

	this(DefaultValueEnum ruleSelection, Value value) {
		this.ruleSelection = ruleSelection;
		this.value = value;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ValueOrVariableEnum {
	Val,
	Var,
}

class ValueOrVariable : Node {
@safe :

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
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
	E,
	N,
}

class Value : Node {
@safe :

	ValueEnum ruleSelection;
	Token tok;
	Array arr;
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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TypeEnum {
	TN,
	LN,
	T,
	L,
}

class Type : Node {
@safe :

	TypeEnum ruleSelection;
	ListType list;
	Token tname;

	this(TypeEnum ruleSelection, Token tname) {
		this.ruleSelection = ruleSelection;
		this.tname = tname;
	}

	this(TypeEnum ruleSelection, ListType list) {
		this.ruleSelection = ruleSelection;
		this.list = list;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ListTypeEnum {
	T,
}

class ListType : Node {
@safe :

	ListTypeEnum ruleSelection;
	Type type;

	this(ListTypeEnum ruleSelection, Type type) {
		this.ruleSelection = ruleSelection;
		this.type = type;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ValuesEnum {
	Val,
	Vals,
	ValsNoComma,
}

class Values : Node {
@safe :

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

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ArrayEnum {
	Empty,
	Value,
}

class Array : Node {
@safe :

	ArrayEnum ruleSelection;
	Values vals;

	this(ArrayEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	this(ArrayEnum ruleSelection, Values vals) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ObjectValuesEnum {
	V,
	Vsc,
	Vs,
}

class ObjectValues : Node {
@safe :

	ObjectValuesEnum ruleSelection;
	ValueOrVariable val;
	ObjectValues follow;
	Token name;

	this(ObjectValuesEnum ruleSelection, Token name, ValueOrVariable val) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.val = val;
	}

	this(ObjectValuesEnum ruleSelection, Token name, ValueOrVariable val, ObjectValues follow) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.val = val;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ObjectTypeEnum {
	Var,
}

class ObjectType : Node {
@safe :

	ObjectTypeEnum ruleSelection;
	ObjectValues vals;

	this(ObjectTypeEnum ruleSelection, ObjectValues vals) {
		this.ruleSelection = ruleSelection;
		this.vals = vals;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TypeSystemDefinitionEnum {
	S,
	T,
	TE,
	D,
	DS,
	DT,
	DTE,
	DD,
}

class TypeSystemDefinition : Node {
@safe :

	TypeSystemDefinitionEnum ruleSelection;
	Description des;
	DirectiveDefinition dd;
	TypeExtensionDefinition ted;
	SchemaDefinition sch;
	TypeDefinition td;

	this(TypeSystemDefinitionEnum ruleSelection, SchemaDefinition sch) {
		this.ruleSelection = ruleSelection;
		this.sch = sch;
	}

	this(TypeSystemDefinitionEnum ruleSelection, TypeDefinition td) {
		this.ruleSelection = ruleSelection;
		this.td = td;
	}

	this(TypeSystemDefinitionEnum ruleSelection, TypeExtensionDefinition ted) {
		this.ruleSelection = ruleSelection;
		this.ted = ted;
	}

	this(TypeSystemDefinitionEnum ruleSelection, DirectiveDefinition dd) {
		this.ruleSelection = ruleSelection;
		this.dd = dd;
	}

	this(TypeSystemDefinitionEnum ruleSelection, Description des, SchemaDefinition sch) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.sch = sch;
	}

	this(TypeSystemDefinitionEnum ruleSelection, Description des, TypeDefinition td) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.td = td;
	}

	this(TypeSystemDefinitionEnum ruleSelection, Description des, TypeExtensionDefinition ted) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.ted = ted;
	}

	this(TypeSystemDefinitionEnum ruleSelection, Description des, DirectiveDefinition dd) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.dd = dd;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TypeDefinitionEnum {
	S,
	O,
	I,
	U,
	E,
	IO,
}

class TypeDefinition : Node {
@safe :

	TypeDefinitionEnum ruleSelection;
	ObjectTypeDefinition otd;
	ScalarTypeDefinition std;
	UnionTypeDefinition utd;
	InterfaceTypeDefinition itd;
	EnumTypeDefinition etd;
	InputObjectTypeDefinition iod;

	this(TypeDefinitionEnum ruleSelection, ScalarTypeDefinition std) {
		this.ruleSelection = ruleSelection;
		this.std = std;
	}

	this(TypeDefinitionEnum ruleSelection, ObjectTypeDefinition otd) {
		this.ruleSelection = ruleSelection;
		this.otd = otd;
	}

	this(TypeDefinitionEnum ruleSelection, InterfaceTypeDefinition itd) {
		this.ruleSelection = ruleSelection;
		this.itd = itd;
	}

	this(TypeDefinitionEnum ruleSelection, UnionTypeDefinition utd) {
		this.ruleSelection = ruleSelection;
		this.utd = utd;
	}

	this(TypeDefinitionEnum ruleSelection, EnumTypeDefinition etd) {
		this.ruleSelection = ruleSelection;
		this.etd = etd;
	}

	this(TypeDefinitionEnum ruleSelection, InputObjectTypeDefinition iod) {
		this.ruleSelection = ruleSelection;
		this.iod = iod;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum SchemaDefinitionEnum {
	DO,
	O,
}

class SchemaDefinition : Node {
@safe :

	SchemaDefinitionEnum ruleSelection;
	Directives dir;
	OperationTypeDefinitions otds;

	this(SchemaDefinitionEnum ruleSelection, Directives dir, OperationTypeDefinitions otds) {
		this.ruleSelection = ruleSelection;
		this.dir = dir;
		this.otds = otds;
	}

	this(SchemaDefinitionEnum ruleSelection, OperationTypeDefinitions otds) {
		this.ruleSelection = ruleSelection;
		this.otds = otds;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OperationTypeDefinitionsEnum {
	O,
	OCS,
	OS,
}

class OperationTypeDefinitions : Node {
@safe :

	OperationTypeDefinitionsEnum ruleSelection;
	OperationTypeDefinition otd;
	OperationTypeDefinitions follow;

	this(OperationTypeDefinitionsEnum ruleSelection, OperationTypeDefinition otd) {
		this.ruleSelection = ruleSelection;
		this.otd = otd;
	}

	this(OperationTypeDefinitionsEnum ruleSelection, OperationTypeDefinition otd, OperationTypeDefinitions follow) {
		this.ruleSelection = ruleSelection;
		this.otd = otd;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OperationTypeDefinitionEnum {
	O,
}

class OperationTypeDefinition : Node {
@safe :

	OperationTypeDefinitionEnum ruleSelection;
	OperationType ot;
	Token nt;

	this(OperationTypeDefinitionEnum ruleSelection, OperationType ot, Token nt) {
		this.ruleSelection = ruleSelection;
		this.ot = ot;
		this.nt = nt;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ScalarTypeDefinitionEnum {
	D,
	S,
}

class ScalarTypeDefinition : Node {
@safe :

	ScalarTypeDefinitionEnum ruleSelection;
	Directives dir;
	Token name;

	this(ScalarTypeDefinitionEnum ruleSelection, Token name, Directives dir) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dir = dir;
	}

	this(ScalarTypeDefinitionEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ObjectTypeDefinitionEnum {
	ID,
	I,
	D,
	F,
}

class ObjectTypeDefinition : Node {
@safe :

	ObjectTypeDefinitionEnum ruleSelection;
	Directives dir;
	ImplementsInterfaces ii;
	FieldDefinitions fds;
	Token name;

	this(ObjectTypeDefinitionEnum ruleSelection, Token name, ImplementsInterfaces ii, Directives dir, FieldDefinitions fds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.ii = ii;
		this.dir = dir;
		this.fds = fds;
	}

	this(ObjectTypeDefinitionEnum ruleSelection, Token name, ImplementsInterfaces ii, FieldDefinitions fds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.ii = ii;
		this.fds = fds;
	}

	this(ObjectTypeDefinitionEnum ruleSelection, Token name, Directives dir, FieldDefinitions fds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dir = dir;
		this.fds = fds;
	}

	this(ObjectTypeDefinitionEnum ruleSelection, Token name, FieldDefinitions fds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.fds = fds;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum FieldDefinitionsEnum {
	F,
	FC,
	FNC,
}

class FieldDefinitions : Node {
@safe :

	FieldDefinitionsEnum ruleSelection;
	FieldDefinitions follow;
	FieldDefinition fd;

	this(FieldDefinitionsEnum ruleSelection, FieldDefinition fd) {
		this.ruleSelection = ruleSelection;
		this.fd = fd;
	}

	this(FieldDefinitionsEnum ruleSelection, FieldDefinition fd, FieldDefinitions follow) {
		this.ruleSelection = ruleSelection;
		this.fd = fd;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum FieldDefinitionEnum {
	AD,
	A,
	D,
	T,
	DAD,
	DA,
	DD,
	DT,
}

class FieldDefinition : Node {
@safe :

	FieldDefinitionEnum ruleSelection;
	Description des;
	ArgumentsDefinition arg;
	Type typ;
	Directives dir;
	Identifier name;

	this(FieldDefinitionEnum ruleSelection, Identifier name, ArgumentsDefinition arg, Type typ, Directives dir) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.arg = arg;
		this.typ = typ;
		this.dir = dir;
	}

	this(FieldDefinitionEnum ruleSelection, Identifier name, ArgumentsDefinition arg, Type typ) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.arg = arg;
		this.typ = typ;
	}

	this(FieldDefinitionEnum ruleSelection, Identifier name, Type typ, Directives dir) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.typ = typ;
		this.dir = dir;
	}

	this(FieldDefinitionEnum ruleSelection, Identifier name, Type typ) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.typ = typ;
	}

	this(FieldDefinitionEnum ruleSelection, Description des, Identifier name, ArgumentsDefinition arg, Type typ, Directives dir) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.arg = arg;
		this.typ = typ;
		this.dir = dir;
	}

	this(FieldDefinitionEnum ruleSelection, Description des, Identifier name, ArgumentsDefinition arg, Type typ) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.arg = arg;
		this.typ = typ;
	}

	this(FieldDefinitionEnum ruleSelection, Description des, Identifier name, Type typ, Directives dir) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.typ = typ;
		this.dir = dir;
	}

	this(FieldDefinitionEnum ruleSelection, Description des, Identifier name, Type typ) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.typ = typ;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ImplementsInterfacesEnum {
	N,
}

class ImplementsInterfaces : Node {
@safe :

	ImplementsInterfacesEnum ruleSelection;
	NamedTypes nts;

	this(ImplementsInterfacesEnum ruleSelection, NamedTypes nts) {
		this.ruleSelection = ruleSelection;
		this.nts = nts;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum NamedTypesEnum {
	N,
	NCS,
	NS,
}

class NamedTypes : Node {
@safe :

	NamedTypesEnum ruleSelection;
	NamedTypes follow;
	Token name;

	this(NamedTypesEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	this(NamedTypesEnum ruleSelection, Token name, NamedTypes follow) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ArgumentsDefinitionEnum {
	A,
	NA,
}

class ArgumentsDefinition : Node {
@safe :

	ArgumentsDefinitionEnum ruleSelection;

	this(ArgumentsDefinitionEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum InputValueDefinitionsEnum {
	I,
	ICF,
	IF,
}

class InputValueDefinitions : Node {
@safe :

	InputValueDefinitionsEnum ruleSelection;
	InputValueDefinitions follow;
	InputValueDefinition iv;

	this(InputValueDefinitionsEnum ruleSelection, InputValueDefinition iv) {
		this.ruleSelection = ruleSelection;
		this.iv = iv;
	}

	this(InputValueDefinitionsEnum ruleSelection, InputValueDefinition iv, InputValueDefinitions follow) {
		this.ruleSelection = ruleSelection;
		this.iv = iv;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum InputValueDefinitionEnum {
	TVD,
	TD,
	TV,
	T,
	DTVD,
	DTD,
	DTV,
	DT,
}

class InputValueDefinition : Node {
@safe :

	InputValueDefinitionEnum ruleSelection;
	Type type;
	Description des;
	DefaultValue df;
	Directives dirs;
	Identifier name;

	this(InputValueDefinitionEnum ruleSelection, Identifier name, Type type, DefaultValue df, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.type = type;
		this.df = df;
		this.dirs = dirs;
	}

	this(InputValueDefinitionEnum ruleSelection, Identifier name, Type type, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.type = type;
		this.dirs = dirs;
	}

	this(InputValueDefinitionEnum ruleSelection, Identifier name, Type type, DefaultValue df) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.type = type;
		this.df = df;
	}

	this(InputValueDefinitionEnum ruleSelection, Identifier name, Type type) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.type = type;
	}

	this(InputValueDefinitionEnum ruleSelection, Description des, Identifier name, Type type, DefaultValue df, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.type = type;
		this.df = df;
		this.dirs = dirs;
	}

	this(InputValueDefinitionEnum ruleSelection, Description des, Identifier name, Type type, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.type = type;
		this.dirs = dirs;
	}

	this(InputValueDefinitionEnum ruleSelection, Description des, Identifier name, Type type, DefaultValue df) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.type = type;
		this.df = df;
	}

	this(InputValueDefinitionEnum ruleSelection, Description des, Identifier name, Type type) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.type = type;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum InterfaceTypeDefinitionEnum {
	NDF,
	NF,
}

class InterfaceTypeDefinition : Node {
@safe :

	InterfaceTypeDefinitionEnum ruleSelection;
	FieldDefinitions fds;
	Directives dirs;
	Token name;

	this(InterfaceTypeDefinitionEnum ruleSelection, Token name, Directives dirs, FieldDefinitions fds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
		this.fds = fds;
	}

	this(InterfaceTypeDefinitionEnum ruleSelection, Token name, FieldDefinitions fds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.fds = fds;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum UnionTypeDefinitionEnum {
	NDU,
	NU,
}

class UnionTypeDefinition : Node {
@safe :

	UnionTypeDefinitionEnum ruleSelection;
	UnionMembers um;
	Directives dirs;
	Token name;

	this(UnionTypeDefinitionEnum ruleSelection, Token name, Directives dirs, UnionMembers um) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
		this.um = um;
	}

	this(UnionTypeDefinitionEnum ruleSelection, Token name, UnionMembers um) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.um = um;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum UnionMembersEnum {
	S,
	SPF,
	SF,
}

class UnionMembers : Node {
@safe :

	UnionMembersEnum ruleSelection;
	UnionMembers follow;
	Token name;

	this(UnionMembersEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	this(UnionMembersEnum ruleSelection, Token name, UnionMembers follow) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum EnumTypeDefinitionEnum {
	NDE,
	NE,
}

class EnumTypeDefinition : Node {
@safe :

	EnumTypeDefinitionEnum ruleSelection;
	EnumValueDefinitions evds;
	Directives dir;
	Token name;

	this(EnumTypeDefinitionEnum ruleSelection, Token name, Directives dir, EnumValueDefinitions evds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dir = dir;
		this.evds = evds;
	}

	this(EnumTypeDefinitionEnum ruleSelection, Token name, EnumValueDefinitions evds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.evds = evds;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum EnumValueDefinitionsEnum {
	D,
	DCE,
	DE,
}

class EnumValueDefinitions : Node {
@safe :

	EnumValueDefinitionsEnum ruleSelection;
	EnumValueDefinition evd;
	EnumValueDefinitions follow;

	this(EnumValueDefinitionsEnum ruleSelection, EnumValueDefinition evd) {
		this.ruleSelection = ruleSelection;
		this.evd = evd;
	}

	this(EnumValueDefinitionsEnum ruleSelection, EnumValueDefinition evd, EnumValueDefinitions follow) {
		this.ruleSelection = ruleSelection;
		this.evd = evd;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum EnumValueDefinitionEnum {
	ED,
	E,
	DED,
	DE,
}

class EnumValueDefinition : Node {
@safe :

	EnumValueDefinitionEnum ruleSelection;
	Description des;
	Directives dirs;
	Token name;

	this(EnumValueDefinitionEnum ruleSelection, Token name, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
	}

	this(EnumValueDefinitionEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	this(EnumValueDefinitionEnum ruleSelection, Description des, Token name, Directives dirs) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
		this.dirs = dirs;
	}

	this(EnumValueDefinitionEnum ruleSelection, Description des, Token name) {
		this.ruleSelection = ruleSelection;
		this.des = des;
		this.name = name;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TypeExtensionDefinitionEnum {
	O,
}

class TypeExtensionDefinition : Node {
@safe :

	TypeExtensionDefinitionEnum ruleSelection;
	ObjectTypeDefinition otd;

	this(TypeExtensionDefinitionEnum ruleSelection, ObjectTypeDefinition otd) {
		this.ruleSelection = ruleSelection;
		this.otd = otd;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DirectiveDefinitionEnum {
	AD,
	D,
}

class DirectiveDefinition : Node {
@safe :

	DirectiveDefinitionEnum ruleSelection;
	DirectiveLocations dl;
	ArgumentsDefinition ad;
	Token name;

	this(DirectiveDefinitionEnum ruleSelection, Token name, ArgumentsDefinition ad, DirectiveLocations dl) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.ad = ad;
		this.dl = dl;
	}

	this(DirectiveDefinitionEnum ruleSelection, Token name, DirectiveLocations dl) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dl = dl;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DirectiveLocationsEnum {
	N,
	NPF,
	NF,
}

class DirectiveLocations : Node {
@safe :

	DirectiveLocationsEnum ruleSelection;
	DirectiveLocations follow;
	Token name;

	this(DirectiveLocationsEnum ruleSelection, Token name) {
		this.ruleSelection = ruleSelection;
		this.name = name;
	}

	this(DirectiveLocationsEnum ruleSelection, Token name, DirectiveLocations follow) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum InputObjectTypeDefinitionEnum {
	NDI,
	NI,
}

class InputObjectTypeDefinition : Node {
@safe :

	InputObjectTypeDefinitionEnum ruleSelection;
	InputValueDefinitions ivds;
	Directives dirs;
	Token name;

	this(InputObjectTypeDefinitionEnum ruleSelection, Token name, Directives dirs, InputValueDefinitions ivds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.dirs = dirs;
		this.ivds = ivds;
	}

	this(InputObjectTypeDefinitionEnum ruleSelection, Token name, InputValueDefinitions ivds) {
		this.ruleSelection = ruleSelection;
		this.name = name;
		this.ivds = ivds;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum DescriptionEnum {
	S,
}

class Description : Node {
@safe :

	DescriptionEnum ruleSelection;
	Token tok;

	this(DescriptionEnum ruleSelection, Token tok) {
		this.ruleSelection = ruleSelection;
		this.tok = tok;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

