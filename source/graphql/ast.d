module graphql.ast;

import graphql.tokenmodule;

import graphql.visitor;

@safe :

enum DocumentEnum : ubyte {
	Defi,
}

struct Document {
@safe :

	uint defsIdx;

	DocumentEnum ruleSelection;

	static Document ConstructDefi(uint defs) {
		Document ret;
		ret.ruleSelection = DocumentEnum.Defi;
		ret.defsIdx = defs;
		return ret;
	}

}

enum DefinitionsEnum : ubyte {
	Def,
	Defs,
}

struct Definitions {
@safe :

	uint defIdx;
	uint followIdx;

	DefinitionsEnum ruleSelection;

	static Definitions ConstructDef(uint def) {
		Definitions ret;
		ret.ruleSelection = DefinitionsEnum.Def;
		ret.defIdx = def;
		return ret;
	}

	static Definitions ConstructDefs(uint def, uint follow) {
		Definitions ret;
		ret.ruleSelection = DefinitionsEnum.Defs;
		ret.defIdx = def;
		ret.followIdx = follow;
		return ret;
	}

}

enum DefinitionEnum : ubyte {
	O,
	F,
	T,
}

struct Definition {
@safe :

	uint fragIdx;
	uint typeIdx;
	uint opIdx;

	DefinitionEnum ruleSelection;

	static Definition ConstructO(uint op) {
		Definition ret;
		ret.ruleSelection = DefinitionEnum.O;
		ret.opIdx = op;
		return ret;
	}

	static Definition ConstructF(uint frag) {
		Definition ret;
		ret.ruleSelection = DefinitionEnum.F;
		ret.fragIdx = frag;
		return ret;
	}

	static Definition ConstructT(uint type) {
		Definition ret;
		ret.ruleSelection = DefinitionEnum.T;
		ret.typeIdx = type;
		return ret;
	}

}

enum OperationDefinitionEnum : ubyte {
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

struct OperationDefinition {
@safe :

	uint vdIdx;
	uint otIdx;
	uint dIdx;
	uint ssIdx;
	Token name;

	OperationDefinitionEnum ruleSelection;

	static OperationDefinition ConstructSelSet(uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.SelSet;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_N_VD(uint ot, Token name, uint vd, uint d, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_N_VD;
		ret.otIdx = ot;
		ret.name = name;
		ret.vdIdx = vd;
		ret.dIdx = d;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_N_V(uint ot, Token name, uint vd, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_N_V;
		ret.otIdx = ot;
		ret.name = name;
		ret.vdIdx = vd;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_N_D(uint ot, Token name, uint d, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_N_D;
		ret.otIdx = ot;
		ret.name = name;
		ret.dIdx = d;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_N(uint ot, Token name, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_N;
		ret.otIdx = ot;
		ret.name = name;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_VD(uint ot, uint vd, uint d, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_VD;
		ret.otIdx = ot;
		ret.vdIdx = vd;
		ret.dIdx = d;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_V(uint ot, uint vd, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_V;
		ret.otIdx = ot;
		ret.vdIdx = vd;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT_D(uint ot, uint d, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT_D;
		ret.otIdx = ot;
		ret.dIdx = d;
		ret.ssIdx = ss;
		return ret;
	}

	static OperationDefinition ConstructOT(uint ot, uint ss) {
		OperationDefinition ret;
		ret.ruleSelection = OperationDefinitionEnum.OT;
		ret.otIdx = ot;
		ret.ssIdx = ss;
		return ret;
	}

}

enum SelectionSetEnum : ubyte {
	SS,
}

struct SelectionSet {
@safe :

	uint selIdx;

	SelectionSetEnum ruleSelection;

	static SelectionSet ConstructSS(uint sel) {
		SelectionSet ret;
		ret.ruleSelection = SelectionSetEnum.SS;
		ret.selIdx = sel;
		return ret;
	}

}

enum OperationTypeEnum : ubyte {
	Query,
	Mutation,
	Sub,
}

struct OperationType {
@safe :

	Token tok;

	OperationTypeEnum ruleSelection;

	static OperationType ConstructQuery(Token tok) {
		OperationType ret;
		ret.ruleSelection = OperationTypeEnum.Query;
		ret.tok = tok;
		return ret;
	}

	static OperationType ConstructMutation(Token tok) {
		OperationType ret;
		ret.ruleSelection = OperationTypeEnum.Mutation;
		ret.tok = tok;
		return ret;
	}

	static OperationType ConstructSub(Token tok) {
		OperationType ret;
		ret.ruleSelection = OperationTypeEnum.Sub;
		ret.tok = tok;
		return ret;
	}

}

enum SelectionsEnum : ubyte {
	Sel,
	Sels,
	Selsc,
}

struct Selections {
@safe :

	uint selIdx;
	uint followIdx;

	SelectionsEnum ruleSelection;

	static Selections ConstructSel(uint sel) {
		Selections ret;
		ret.ruleSelection = SelectionsEnum.Sel;
		ret.selIdx = sel;
		return ret;
	}

	static Selections ConstructSels(uint sel, uint follow) {
		Selections ret;
		ret.ruleSelection = SelectionsEnum.Sels;
		ret.selIdx = sel;
		ret.followIdx = follow;
		return ret;
	}

	static Selections ConstructSelsc(uint sel, uint follow) {
		Selections ret;
		ret.ruleSelection = SelectionsEnum.Selsc;
		ret.selIdx = sel;
		ret.followIdx = follow;
		return ret;
	}

}

enum SelectionEnum : ubyte {
	Field,
	Spread,
	IFrag,
}

struct Selection {
@safe :

	uint fragIdx;
	uint fieldIdx;
	uint ifragIdx;

	SelectionEnum ruleSelection;

	static Selection ConstructField(uint field) {
		Selection ret;
		ret.ruleSelection = SelectionEnum.Field;
		ret.fieldIdx = field;
		return ret;
	}

	static Selection ConstructSpread(uint frag) {
		Selection ret;
		ret.ruleSelection = SelectionEnum.Spread;
		ret.fragIdx = frag;
		return ret;
	}

	static Selection ConstructIFrag(uint ifrag) {
		Selection ret;
		ret.ruleSelection = SelectionEnum.IFrag;
		ret.ifragIdx = ifrag;
		return ret;
	}

}

enum FragmentSpreadEnum : ubyte {
	FD,
	F,
}

struct FragmentSpread {
@safe :

	uint dirsIdx;
	Token name;

	FragmentSpreadEnum ruleSelection;

	static FragmentSpread ConstructFD(Token name, uint dirs) {
		FragmentSpread ret;
		ret.ruleSelection = FragmentSpreadEnum.FD;
		ret.name = name;
		ret.dirsIdx = dirs;
		return ret;
	}

	static FragmentSpread ConstructF(Token name) {
		FragmentSpread ret;
		ret.ruleSelection = FragmentSpreadEnum.F;
		ret.name = name;
		return ret;
	}

}

enum InlineFragmentEnum : ubyte {
	TDS,
	TS,
	DS,
	S,
}

struct InlineFragment {
@safe :

	Token tc;
	uint dirsIdx;
	uint ssIdx;

	InlineFragmentEnum ruleSelection;

	static InlineFragment ConstructTDS(Token tc, uint dirs, uint ss) {
		InlineFragment ret;
		ret.ruleSelection = InlineFragmentEnum.TDS;
		ret.tc = tc;
		ret.dirsIdx = dirs;
		ret.ssIdx = ss;
		return ret;
	}

	static InlineFragment ConstructTS(Token tc, uint ss) {
		InlineFragment ret;
		ret.ruleSelection = InlineFragmentEnum.TS;
		ret.tc = tc;
		ret.ssIdx = ss;
		return ret;
	}

	static InlineFragment ConstructDS(uint dirs, uint ss) {
		InlineFragment ret;
		ret.ruleSelection = InlineFragmentEnum.DS;
		ret.dirsIdx = dirs;
		ret.ssIdx = ss;
		return ret;
	}

	static InlineFragment ConstructS(uint ss) {
		InlineFragment ret;
		ret.ruleSelection = InlineFragmentEnum.S;
		ret.ssIdx = ss;
		return ret;
	}

}

enum FieldEnum : ubyte {
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
@safe :

	uint ssIdx;
	uint argsIdx;
	uint dirsIdx;
	uint nameIdx;

	FieldEnum ruleSelection;

	static Field ConstructFADS(uint name, uint args, uint dirs, uint ss) {
		Field ret;
		ret.ruleSelection = FieldEnum.FADS;
		ret.nameIdx = name;
		ret.argsIdx = args;
		ret.dirsIdx = dirs;
		ret.ssIdx = ss;
		return ret;
	}

	static Field ConstructFAS(uint name, uint args, uint ss) {
		Field ret;
		ret.ruleSelection = FieldEnum.FAS;
		ret.nameIdx = name;
		ret.argsIdx = args;
		ret.ssIdx = ss;
		return ret;
	}

	static Field ConstructFAD(uint name, uint args, uint dirs) {
		Field ret;
		ret.ruleSelection = FieldEnum.FAD;
		ret.nameIdx = name;
		ret.argsIdx = args;
		ret.dirsIdx = dirs;
		return ret;
	}

	static Field ConstructFDS(uint name, uint dirs, uint ss) {
		Field ret;
		ret.ruleSelection = FieldEnum.FDS;
		ret.nameIdx = name;
		ret.dirsIdx = dirs;
		ret.ssIdx = ss;
		return ret;
	}

	static Field ConstructFS(uint name, uint ss) {
		Field ret;
		ret.ruleSelection = FieldEnum.FS;
		ret.nameIdx = name;
		ret.ssIdx = ss;
		return ret;
	}

	static Field ConstructFD(uint name, uint dirs) {
		Field ret;
		ret.ruleSelection = FieldEnum.FD;
		ret.nameIdx = name;
		ret.dirsIdx = dirs;
		return ret;
	}

	static Field ConstructFA(uint name, uint args) {
		Field ret;
		ret.ruleSelection = FieldEnum.FA;
		ret.nameIdx = name;
		ret.argsIdx = args;
		return ret;
	}

	static Field ConstructF(uint name) {
		Field ret;
		ret.ruleSelection = FieldEnum.F;
		ret.nameIdx = name;
		return ret;
	}

}

enum FieldNameEnum : ubyte {
	A,
	N,
}

struct FieldName {
@safe :

	Token aka;
	Token name;

	FieldNameEnum ruleSelection;

	static FieldName ConstructA(Token name, Token aka) {
		FieldName ret;
		ret.ruleSelection = FieldNameEnum.A;
		ret.name = name;
		ret.aka = aka;
		return ret;
	}

	static FieldName ConstructN(Token name) {
		FieldName ret;
		ret.ruleSelection = FieldNameEnum.N;
		ret.name = name;
		return ret;
	}

}

enum ArgumentsEnum : ubyte {
	List,
	Empty,
}

struct Arguments {
@safe :

	uint argIdx;

	ArgumentsEnum ruleSelection;

	static Arguments ConstructList(uint arg) {
		Arguments ret;
		ret.ruleSelection = ArgumentsEnum.List;
		ret.argIdx = arg;
		return ret;
	}

	static Arguments ConstructEmpty() {
		Arguments ret;
		ret.ruleSelection = ArgumentsEnum.Empty;

		return ret;
	}

}

enum ArgumentListEnum : ubyte {
	A,
	ACS,
	AS,
}

struct ArgumentList {
@safe :

	uint argIdx;
	uint followIdx;

	ArgumentListEnum ruleSelection;

	static ArgumentList ConstructA(uint arg) {
		ArgumentList ret;
		ret.ruleSelection = ArgumentListEnum.A;
		ret.argIdx = arg;
		return ret;
	}

	static ArgumentList ConstructACS(uint arg, uint follow) {
		ArgumentList ret;
		ret.ruleSelection = ArgumentListEnum.ACS;
		ret.argIdx = arg;
		ret.followIdx = follow;
		return ret;
	}

	static ArgumentList ConstructAS(uint arg, uint follow) {
		ArgumentList ret;
		ret.ruleSelection = ArgumentListEnum.AS;
		ret.argIdx = arg;
		ret.followIdx = follow;
		return ret;
	}

}

enum ArgumentEnum : ubyte {
	Name,
}

struct Argument {
@safe :

	uint vvIdx;
	Token name;

	ArgumentEnum ruleSelection;

	static Argument ConstructName(Token name, uint vv) {
		Argument ret;
		ret.ruleSelection = ArgumentEnum.Name;
		ret.name = name;
		ret.vvIdx = vv;
		return ret;
	}

}

enum FragmentDefinitionEnum : ubyte {
	FTDS,
	FTS,
}

struct FragmentDefinition {
@safe :

	uint ssIdx;
	Token tc;
	uint dirsIdx;
	Token name;

	FragmentDefinitionEnum ruleSelection;

	static FragmentDefinition ConstructFTDS(Token name, Token tc, uint dirs, uint ss) {
		FragmentDefinition ret;
		ret.ruleSelection = FragmentDefinitionEnum.FTDS;
		ret.name = name;
		ret.tc = tc;
		ret.dirsIdx = dirs;
		ret.ssIdx = ss;
		return ret;
	}

	static FragmentDefinition ConstructFTS(Token name, Token tc, uint ss) {
		FragmentDefinition ret;
		ret.ruleSelection = FragmentDefinitionEnum.FTS;
		ret.name = name;
		ret.tc = tc;
		ret.ssIdx = ss;
		return ret;
	}

}

enum DirectivesEnum : ubyte {
	Dir,
	Dirs,
}

struct Directives {
@safe :

	uint dirIdx;
	uint followIdx;

	DirectivesEnum ruleSelection;

	static Directives ConstructDir(uint dir) {
		Directives ret;
		ret.ruleSelection = DirectivesEnum.Dir;
		ret.dirIdx = dir;
		return ret;
	}

	static Directives ConstructDirs(uint dir, uint follow) {
		Directives ret;
		ret.ruleSelection = DirectivesEnum.Dirs;
		ret.dirIdx = dir;
		ret.followIdx = follow;
		return ret;
	}

}

enum DirectiveEnum : ubyte {
	NArg,
	N,
}

struct Directive {
@safe :

	uint argIdx;
	Token name;

	DirectiveEnum ruleSelection;

	static Directive ConstructNArg(Token name, uint arg) {
		Directive ret;
		ret.ruleSelection = DirectiveEnum.NArg;
		ret.name = name;
		ret.argIdx = arg;
		return ret;
	}

	static Directive ConstructN(Token name) {
		Directive ret;
		ret.ruleSelection = DirectiveEnum.N;
		ret.name = name;
		return ret;
	}

}

enum VariableDefinitionsEnum : ubyte {
	Empty,
	Vars,
}

struct VariableDefinitions {
@safe :

	uint varsIdx;

	VariableDefinitionsEnum ruleSelection;

	static VariableDefinitions ConstructEmpty() {
		VariableDefinitions ret;
		ret.ruleSelection = VariableDefinitionsEnum.Empty;

		return ret;
	}

	static VariableDefinitions ConstructVars(uint vars) {
		VariableDefinitions ret;
		ret.ruleSelection = VariableDefinitionsEnum.Vars;
		ret.varsIdx = vars;
		return ret;
	}

}

enum VariableDefinitionListEnum : ubyte {
	V,
	VCF,
	VF,
}

struct VariableDefinitionList {
@safe :

	uint followIdx;
	uint varIdx;

	VariableDefinitionListEnum ruleSelection;

	static VariableDefinitionList ConstructV(uint var) {
		VariableDefinitionList ret;
		ret.ruleSelection = VariableDefinitionListEnum.V;
		ret.varIdx = var;
		return ret;
	}

	static VariableDefinitionList ConstructVCF(uint var, uint follow) {
		VariableDefinitionList ret;
		ret.ruleSelection = VariableDefinitionListEnum.VCF;
		ret.varIdx = var;
		ret.followIdx = follow;
		return ret;
	}

	static VariableDefinitionList ConstructVF(uint var, uint follow) {
		VariableDefinitionList ret;
		ret.ruleSelection = VariableDefinitionListEnum.VF;
		ret.varIdx = var;
		ret.followIdx = follow;
		return ret;
	}

}

enum VariableDefinitionEnum : ubyte {
	VarD,
	Var,
}

struct VariableDefinition {
@safe :

	uint typeIdx;
	uint dvalueIdx;
	uint varIdx;

	VariableDefinitionEnum ruleSelection;

	static VariableDefinition ConstructVarD(uint var, uint type, uint dvalue) {
		VariableDefinition ret;
		ret.ruleSelection = VariableDefinitionEnum.VarD;
		ret.varIdx = var;
		ret.typeIdx = type;
		ret.dvalueIdx = dvalue;
		return ret;
	}

	static VariableDefinition ConstructVar(uint var, uint type) {
		VariableDefinition ret;
		ret.ruleSelection = VariableDefinitionEnum.Var;
		ret.varIdx = var;
		ret.typeIdx = type;
		return ret;
	}

}

enum VariableEnum : ubyte {
	Var,
}

struct Variable {
@safe :

	Token name;

	VariableEnum ruleSelection;

	static Variable ConstructVar(Token name) {
		Variable ret;
		ret.ruleSelection = VariableEnum.Var;
		ret.name = name;
		return ret;
	}

}

enum DefaultValueEnum : ubyte {
	DV,
}

struct DefaultValue {
@safe :

	uint valueIdx;

	DefaultValueEnum ruleSelection;

	static DefaultValue ConstructDV(uint value) {
		DefaultValue ret;
		ret.ruleSelection = DefaultValueEnum.DV;
		ret.valueIdx = value;
		return ret;
	}

}

enum ValueOrVariableEnum : ubyte {
	Val,
	Var,
}

struct ValueOrVariable {
@safe :

	uint valIdx;
	uint varIdx;

	ValueOrVariableEnum ruleSelection;

	static ValueOrVariable ConstructVal(uint val) {
		ValueOrVariable ret;
		ret.ruleSelection = ValueOrVariableEnum.Val;
		ret.valIdx = val;
		return ret;
	}

	static ValueOrVariable ConstructVar(uint var) {
		ValueOrVariable ret;
		ret.ruleSelection = ValueOrVariableEnum.Var;
		ret.varIdx = var;
		return ret;
	}

}

enum ValueEnum : ubyte {
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

struct Value {
@safe :

	Token tok;
	uint arrIdx;
	uint objIdx;

	ValueEnum ruleSelection;

	static Value ConstructSTR(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.STR;
		ret.tok = tok;
		return ret;
	}

	static Value ConstructINT(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.INT;
		ret.tok = tok;
		return ret;
	}

	static Value ConstructFLOAT(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.FLOAT;
		ret.tok = tok;
		return ret;
	}

	static Value ConstructT(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.T;
		ret.tok = tok;
		return ret;
	}

	static Value ConstructF(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.F;
		ret.tok = tok;
		return ret;
	}

	static Value ConstructARR(uint arr) {
		Value ret;
		ret.ruleSelection = ValueEnum.ARR;
		ret.arrIdx = arr;
		return ret;
	}

	static Value ConstructO(uint obj) {
		Value ret;
		ret.ruleSelection = ValueEnum.O;
		ret.objIdx = obj;
		return ret;
	}

	static Value ConstructE(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.E;
		ret.tok = tok;
		return ret;
	}

	static Value ConstructN(Token tok) {
		Value ret;
		ret.ruleSelection = ValueEnum.N;
		ret.tok = tok;
		return ret;
	}

}

enum TypeEnum : ubyte {
	TN,
	LN,
	T,
	L,
}

struct Type {
@safe :

	uint listIdx;
	Token tname;

	TypeEnum ruleSelection;

	static Type ConstructTN(Token tname) {
		Type ret;
		ret.ruleSelection = TypeEnum.TN;
		ret.tname = tname;
		return ret;
	}

	static Type ConstructLN(uint list) {
		Type ret;
		ret.ruleSelection = TypeEnum.LN;
		ret.listIdx = list;
		return ret;
	}

	static Type ConstructT(Token tname) {
		Type ret;
		ret.ruleSelection = TypeEnum.T;
		ret.tname = tname;
		return ret;
	}

	static Type ConstructL(uint list) {
		Type ret;
		ret.ruleSelection = TypeEnum.L;
		ret.listIdx = list;
		return ret;
	}

}

enum ListTypeEnum : ubyte {
	T,
}

struct ListType {
@safe :

	uint typeIdx;

	ListTypeEnum ruleSelection;

	static ListType ConstructT(uint type) {
		ListType ret;
		ret.ruleSelection = ListTypeEnum.T;
		ret.typeIdx = type;
		return ret;
	}

}

enum ValuesEnum : ubyte {
	Val,
	Vals,
	ValsNoComma,
}

struct Values {
@safe :

	uint valIdx;
	uint followIdx;

	ValuesEnum ruleSelection;

	static Values ConstructVal(uint val) {
		Values ret;
		ret.ruleSelection = ValuesEnum.Val;
		ret.valIdx = val;
		return ret;
	}

	static Values ConstructVals(uint val, uint follow) {
		Values ret;
		ret.ruleSelection = ValuesEnum.Vals;
		ret.valIdx = val;
		ret.followIdx = follow;
		return ret;
	}

	static Values ConstructValsNoComma(uint val, uint follow) {
		Values ret;
		ret.ruleSelection = ValuesEnum.ValsNoComma;
		ret.valIdx = val;
		ret.followIdx = follow;
		return ret;
	}

}

enum ArrayEnum : ubyte {
	Empty,
	Value,
}

struct Array {
@safe :

	uint valsIdx;

	ArrayEnum ruleSelection;

	static Array ConstructEmpty() {
		Array ret;
		ret.ruleSelection = ArrayEnum.Empty;

		return ret;
	}

	static Array ConstructValue(uint vals) {
		Array ret;
		ret.ruleSelection = ArrayEnum.Value;
		ret.valsIdx = vals;
		return ret;
	}

}

enum ObjectValuesEnum : ubyte {
	V,
	Vsc,
	Vs,
}

struct ObjectValues {
@safe :

	uint valIdx;
	uint followIdx;
	Token name;

	ObjectValuesEnum ruleSelection;

	static ObjectValues ConstructV(Token name, uint val) {
		ObjectValues ret;
		ret.ruleSelection = ObjectValuesEnum.V;
		ret.name = name;
		ret.valIdx = val;
		return ret;
	}

	static ObjectValues ConstructVsc(Token name, uint val, uint follow) {
		ObjectValues ret;
		ret.ruleSelection = ObjectValuesEnum.Vsc;
		ret.name = name;
		ret.valIdx = val;
		ret.followIdx = follow;
		return ret;
	}

	static ObjectValues ConstructVs(Token name, uint val, uint follow) {
		ObjectValues ret;
		ret.ruleSelection = ObjectValuesEnum.Vs;
		ret.name = name;
		ret.valIdx = val;
		ret.followIdx = follow;
		return ret;
	}

}

enum ObjectTypeEnum : ubyte {
	Var,
}

struct ObjectType {
@safe :

	uint valsIdx;

	ObjectTypeEnum ruleSelection;

	static ObjectType ConstructVar(uint vals) {
		ObjectType ret;
		ret.ruleSelection = ObjectTypeEnum.Var;
		ret.valsIdx = vals;
		return ret;
	}

}

enum TypeSystemDefinitionEnum : ubyte {
	S,
	T,
	TE,
	D,
	DS,
	DT,
	DTE,
	DD,
}

struct TypeSystemDefinition {
@safe :

	uint desIdx;
	uint ddIdx;
	uint tedIdx;
	uint schIdx;
	uint tdIdx;

	TypeSystemDefinitionEnum ruleSelection;

	static TypeSystemDefinition ConstructS(uint sch) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.S;
		ret.schIdx = sch;
		return ret;
	}

	static TypeSystemDefinition ConstructT(uint td) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.T;
		ret.tdIdx = td;
		return ret;
	}

	static TypeSystemDefinition ConstructTE(uint ted) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.TE;
		ret.tedIdx = ted;
		return ret;
	}

	static TypeSystemDefinition ConstructD(uint dd) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.D;
		ret.ddIdx = dd;
		return ret;
	}

	static TypeSystemDefinition ConstructDS(uint des, uint sch) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.DS;
		ret.desIdx = des;
		ret.schIdx = sch;
		return ret;
	}

	static TypeSystemDefinition ConstructDT(uint des, uint td) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.DT;
		ret.desIdx = des;
		ret.tdIdx = td;
		return ret;
	}

	static TypeSystemDefinition ConstructDTE(uint des, uint ted) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.DTE;
		ret.desIdx = des;
		ret.tedIdx = ted;
		return ret;
	}

	static TypeSystemDefinition ConstructDD(uint des, uint dd) {
		TypeSystemDefinition ret;
		ret.ruleSelection = TypeSystemDefinitionEnum.DD;
		ret.desIdx = des;
		ret.ddIdx = dd;
		return ret;
	}

}

enum TypeDefinitionEnum : ubyte {
	S,
	O,
	I,
	U,
	E,
	IO,
}

struct TypeDefinition {
@safe :

	uint otdIdx;
	uint stdIdx;
	uint utdIdx;
	uint itdIdx;
	uint etdIdx;
	uint iodIdx;

	TypeDefinitionEnum ruleSelection;

	static TypeDefinition ConstructS(uint std) {
		TypeDefinition ret;
		ret.ruleSelection = TypeDefinitionEnum.S;
		ret.stdIdx = std;
		return ret;
	}

	static TypeDefinition ConstructO(uint otd) {
		TypeDefinition ret;
		ret.ruleSelection = TypeDefinitionEnum.O;
		ret.otdIdx = otd;
		return ret;
	}

	static TypeDefinition ConstructI(uint itd) {
		TypeDefinition ret;
		ret.ruleSelection = TypeDefinitionEnum.I;
		ret.itdIdx = itd;
		return ret;
	}

	static TypeDefinition ConstructU(uint utd) {
		TypeDefinition ret;
		ret.ruleSelection = TypeDefinitionEnum.U;
		ret.utdIdx = utd;
		return ret;
	}

	static TypeDefinition ConstructE(uint etd) {
		TypeDefinition ret;
		ret.ruleSelection = TypeDefinitionEnum.E;
		ret.etdIdx = etd;
		return ret;
	}

	static TypeDefinition ConstructIO(uint iod) {
		TypeDefinition ret;
		ret.ruleSelection = TypeDefinitionEnum.IO;
		ret.iodIdx = iod;
		return ret;
	}

}

enum SchemaDefinitionEnum : ubyte {
	DO,
	O,
}

struct SchemaDefinition {
@safe :

	uint dirIdx;
	uint otdsIdx;

	SchemaDefinitionEnum ruleSelection;

	static SchemaDefinition ConstructDO(uint dir, uint otds) {
		SchemaDefinition ret;
		ret.ruleSelection = SchemaDefinitionEnum.DO;
		ret.dirIdx = dir;
		ret.otdsIdx = otds;
		return ret;
	}

	static SchemaDefinition ConstructO(uint otds) {
		SchemaDefinition ret;
		ret.ruleSelection = SchemaDefinitionEnum.O;
		ret.otdsIdx = otds;
		return ret;
	}

}

enum OperationTypeDefinitionsEnum : ubyte {
	O,
	OCS,
	OS,
}

struct OperationTypeDefinitions {
@safe :

	uint otdIdx;
	uint followIdx;

	OperationTypeDefinitionsEnum ruleSelection;

	static OperationTypeDefinitions ConstructO(uint otd) {
		OperationTypeDefinitions ret;
		ret.ruleSelection = OperationTypeDefinitionsEnum.O;
		ret.otdIdx = otd;
		return ret;
	}

	static OperationTypeDefinitions ConstructOCS(uint otd, uint follow) {
		OperationTypeDefinitions ret;
		ret.ruleSelection = OperationTypeDefinitionsEnum.OCS;
		ret.otdIdx = otd;
		ret.followIdx = follow;
		return ret;
	}

	static OperationTypeDefinitions ConstructOS(uint otd, uint follow) {
		OperationTypeDefinitions ret;
		ret.ruleSelection = OperationTypeDefinitionsEnum.OS;
		ret.otdIdx = otd;
		ret.followIdx = follow;
		return ret;
	}

}

enum OperationTypeDefinitionEnum : ubyte {
	O,
}

struct OperationTypeDefinition {
@safe :

	uint otIdx;
	Token nt;

	OperationTypeDefinitionEnum ruleSelection;

	static OperationTypeDefinition ConstructO(uint ot, Token nt) {
		OperationTypeDefinition ret;
		ret.ruleSelection = OperationTypeDefinitionEnum.O;
		ret.otIdx = ot;
		ret.nt = nt;
		return ret;
	}

}

enum ScalarTypeDefinitionEnum : ubyte {
	D,
	S,
}

struct ScalarTypeDefinition {
@safe :

	uint dirIdx;
	Token name;

	ScalarTypeDefinitionEnum ruleSelection;

	static ScalarTypeDefinition ConstructD(Token name, uint dir) {
		ScalarTypeDefinition ret;
		ret.ruleSelection = ScalarTypeDefinitionEnum.D;
		ret.name = name;
		ret.dirIdx = dir;
		return ret;
	}

	static ScalarTypeDefinition ConstructS(Token name) {
		ScalarTypeDefinition ret;
		ret.ruleSelection = ScalarTypeDefinitionEnum.S;
		ret.name = name;
		return ret;
	}

}

enum ObjectTypeDefinitionEnum : ubyte {
	ID,
	I,
	D,
	F,
}

struct ObjectTypeDefinition {
@safe :

	uint dirIdx;
	uint iiIdx;
	uint fdsIdx;
	Token name;

	ObjectTypeDefinitionEnum ruleSelection;

	static ObjectTypeDefinition ConstructID(Token name, uint ii, uint dir, uint fds) {
		ObjectTypeDefinition ret;
		ret.ruleSelection = ObjectTypeDefinitionEnum.ID;
		ret.name = name;
		ret.iiIdx = ii;
		ret.dirIdx = dir;
		ret.fdsIdx = fds;
		return ret;
	}

	static ObjectTypeDefinition ConstructI(Token name, uint ii, uint fds) {
		ObjectTypeDefinition ret;
		ret.ruleSelection = ObjectTypeDefinitionEnum.I;
		ret.name = name;
		ret.iiIdx = ii;
		ret.fdsIdx = fds;
		return ret;
	}

	static ObjectTypeDefinition ConstructD(Token name, uint dir, uint fds) {
		ObjectTypeDefinition ret;
		ret.ruleSelection = ObjectTypeDefinitionEnum.D;
		ret.name = name;
		ret.dirIdx = dir;
		ret.fdsIdx = fds;
		return ret;
	}

	static ObjectTypeDefinition ConstructF(Token name, uint fds) {
		ObjectTypeDefinition ret;
		ret.ruleSelection = ObjectTypeDefinitionEnum.F;
		ret.name = name;
		ret.fdsIdx = fds;
		return ret;
	}

}

enum FieldDefinitionsEnum : ubyte {
	F,
	FC,
	FNC,
}

struct FieldDefinitions {
@safe :

	uint followIdx;
	uint fdIdx;

	FieldDefinitionsEnum ruleSelection;

	static FieldDefinitions ConstructF(uint fd) {
		FieldDefinitions ret;
		ret.ruleSelection = FieldDefinitionsEnum.F;
		ret.fdIdx = fd;
		return ret;
	}

	static FieldDefinitions ConstructFC(uint fd, uint follow) {
		FieldDefinitions ret;
		ret.ruleSelection = FieldDefinitionsEnum.FC;
		ret.fdIdx = fd;
		ret.followIdx = follow;
		return ret;
	}

	static FieldDefinitions ConstructFNC(uint fd, uint follow) {
		FieldDefinitions ret;
		ret.ruleSelection = FieldDefinitionsEnum.FNC;
		ret.fdIdx = fd;
		ret.followIdx = follow;
		return ret;
	}

}

enum FieldDefinitionEnum : ubyte {
	AD,
	A,
	D,
	T,
	DAD,
	DA,
	DD,
	DT,
}

struct FieldDefinition {
@safe :

	uint desIdx;
	uint argIdx;
	uint typIdx;
	uint dirIdx;
	Token name;

	FieldDefinitionEnum ruleSelection;

	static FieldDefinition ConstructAD(Token name, uint arg, uint typ, uint dir) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.AD;
		ret.name = name;
		ret.argIdx = arg;
		ret.typIdx = typ;
		ret.dirIdx = dir;
		return ret;
	}

	static FieldDefinition ConstructA(Token name, uint arg, uint typ) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.A;
		ret.name = name;
		ret.argIdx = arg;
		ret.typIdx = typ;
		return ret;
	}

	static FieldDefinition ConstructD(Token name, uint typ, uint dir) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.D;
		ret.name = name;
		ret.typIdx = typ;
		ret.dirIdx = dir;
		return ret;
	}

	static FieldDefinition ConstructT(Token name, uint typ) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.T;
		ret.name = name;
		ret.typIdx = typ;
		return ret;
	}

	static FieldDefinition ConstructDAD(uint des, Token name, uint arg, uint typ, uint dir) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.DAD;
		ret.desIdx = des;
		ret.name = name;
		ret.argIdx = arg;
		ret.typIdx = typ;
		ret.dirIdx = dir;
		return ret;
	}

	static FieldDefinition ConstructDA(uint des, Token name, uint arg, uint typ) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.DA;
		ret.desIdx = des;
		ret.name = name;
		ret.argIdx = arg;
		ret.typIdx = typ;
		return ret;
	}

	static FieldDefinition ConstructDD(uint des, Token name, uint typ, uint dir) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.DD;
		ret.desIdx = des;
		ret.name = name;
		ret.typIdx = typ;
		ret.dirIdx = dir;
		return ret;
	}

	static FieldDefinition ConstructDT(uint des, Token name, uint typ) {
		FieldDefinition ret;
		ret.ruleSelection = FieldDefinitionEnum.DT;
		ret.desIdx = des;
		ret.name = name;
		ret.typIdx = typ;
		return ret;
	}

}

enum ImplementsInterfacesEnum : ubyte {
	N,
}

struct ImplementsInterfaces {
@safe :

	uint ntsIdx;

	ImplementsInterfacesEnum ruleSelection;

	static ImplementsInterfaces ConstructN(uint nts) {
		ImplementsInterfaces ret;
		ret.ruleSelection = ImplementsInterfacesEnum.N;
		ret.ntsIdx = nts;
		return ret;
	}

}

enum NamedTypesEnum : ubyte {
	N,
	NCS,
	NS,
}

struct NamedTypes {
@safe :

	uint followIdx;
	Token name;

	NamedTypesEnum ruleSelection;

	static NamedTypes ConstructN(Token name) {
		NamedTypes ret;
		ret.ruleSelection = NamedTypesEnum.N;
		ret.name = name;
		return ret;
	}

	static NamedTypes ConstructNCS(Token name, uint follow) {
		NamedTypes ret;
		ret.ruleSelection = NamedTypesEnum.NCS;
		ret.name = name;
		ret.followIdx = follow;
		return ret;
	}

	static NamedTypes ConstructNS(Token name, uint follow) {
		NamedTypes ret;
		ret.ruleSelection = NamedTypesEnum.NS;
		ret.name = name;
		ret.followIdx = follow;
		return ret;
	}

}

enum ArgumentsDefinitionEnum : ubyte {
	A,
	NA,
}

struct ArgumentsDefinition {
@safe :


	ArgumentsDefinitionEnum ruleSelection;

	static ArgumentsDefinition ConstructA() {
		ArgumentsDefinition ret;
		ret.ruleSelection = ArgumentsDefinitionEnum.A;

		return ret;
	}

	static ArgumentsDefinition ConstructNA() {
		ArgumentsDefinition ret;
		ret.ruleSelection = ArgumentsDefinitionEnum.NA;

		return ret;
	}

}

enum InputValueDefinitionsEnum : ubyte {
	I,
	ICF,
	IF,
}

struct InputValueDefinitions {
@safe :

	uint followIdx;
	uint ivIdx;

	InputValueDefinitionsEnum ruleSelection;

	static InputValueDefinitions ConstructI(uint iv) {
		InputValueDefinitions ret;
		ret.ruleSelection = InputValueDefinitionsEnum.I;
		ret.ivIdx = iv;
		return ret;
	}

	static InputValueDefinitions ConstructICF(uint iv, uint follow) {
		InputValueDefinitions ret;
		ret.ruleSelection = InputValueDefinitionsEnum.ICF;
		ret.ivIdx = iv;
		ret.followIdx = follow;
		return ret;
	}

	static InputValueDefinitions ConstructIF(uint iv, uint follow) {
		InputValueDefinitions ret;
		ret.ruleSelection = InputValueDefinitionsEnum.IF;
		ret.ivIdx = iv;
		ret.followIdx = follow;
		return ret;
	}

}

enum InputValueDefinitionEnum : ubyte {
	TVD,
	TD,
	TV,
	T,
	DTVD,
	DTD,
	DTV,
	DT,
}

struct InputValueDefinition {
@safe :

	uint typeIdx;
	uint desIdx;
	uint dfIdx;
	uint dirsIdx;
	Token name;

	InputValueDefinitionEnum ruleSelection;

	static InputValueDefinition ConstructTVD(Token name, uint type, uint df, uint dirs) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.TVD;
		ret.name = name;
		ret.typeIdx = type;
		ret.dfIdx = df;
		ret.dirsIdx = dirs;
		return ret;
	}

	static InputValueDefinition ConstructTD(Token name, uint type, uint dirs) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.TD;
		ret.name = name;
		ret.typeIdx = type;
		ret.dirsIdx = dirs;
		return ret;
	}

	static InputValueDefinition ConstructTV(Token name, uint type, uint df) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.TV;
		ret.name = name;
		ret.typeIdx = type;
		ret.dfIdx = df;
		return ret;
	}

	static InputValueDefinition ConstructT(Token name, uint type) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.T;
		ret.name = name;
		ret.typeIdx = type;
		return ret;
	}

	static InputValueDefinition ConstructDTVD(uint des, Token name, uint type, uint df, uint dirs) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.DTVD;
		ret.desIdx = des;
		ret.name = name;
		ret.typeIdx = type;
		ret.dfIdx = df;
		ret.dirsIdx = dirs;
		return ret;
	}

	static InputValueDefinition ConstructDTD(uint des, Token name, uint type, uint dirs) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.DTD;
		ret.desIdx = des;
		ret.name = name;
		ret.typeIdx = type;
		ret.dirsIdx = dirs;
		return ret;
	}

	static InputValueDefinition ConstructDTV(uint des, Token name, uint type, uint df) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.DTV;
		ret.desIdx = des;
		ret.name = name;
		ret.typeIdx = type;
		ret.dfIdx = df;
		return ret;
	}

	static InputValueDefinition ConstructDT(uint des, Token name, uint type) {
		InputValueDefinition ret;
		ret.ruleSelection = InputValueDefinitionEnum.DT;
		ret.desIdx = des;
		ret.name = name;
		ret.typeIdx = type;
		return ret;
	}

}

enum InterfaceTypeDefinitionEnum : ubyte {
	NDF,
	NF,
}

struct InterfaceTypeDefinition {
@safe :

	uint fdsIdx;
	uint dirsIdx;
	Token name;

	InterfaceTypeDefinitionEnum ruleSelection;

	static InterfaceTypeDefinition ConstructNDF(Token name, uint dirs, uint fds) {
		InterfaceTypeDefinition ret;
		ret.ruleSelection = InterfaceTypeDefinitionEnum.NDF;
		ret.name = name;
		ret.dirsIdx = dirs;
		ret.fdsIdx = fds;
		return ret;
	}

	static InterfaceTypeDefinition ConstructNF(Token name, uint fds) {
		InterfaceTypeDefinition ret;
		ret.ruleSelection = InterfaceTypeDefinitionEnum.NF;
		ret.name = name;
		ret.fdsIdx = fds;
		return ret;
	}

}

enum UnionTypeDefinitionEnum : ubyte {
	NDU,
	NU,
}

struct UnionTypeDefinition {
@safe :

	uint umIdx;
	uint dirsIdx;
	Token name;

	UnionTypeDefinitionEnum ruleSelection;

	static UnionTypeDefinition ConstructNDU(Token name, uint dirs, uint um) {
		UnionTypeDefinition ret;
		ret.ruleSelection = UnionTypeDefinitionEnum.NDU;
		ret.name = name;
		ret.dirsIdx = dirs;
		ret.umIdx = um;
		return ret;
	}

	static UnionTypeDefinition ConstructNU(Token name, uint um) {
		UnionTypeDefinition ret;
		ret.ruleSelection = UnionTypeDefinitionEnum.NU;
		ret.name = name;
		ret.umIdx = um;
		return ret;
	}

}

enum UnionMembersEnum : ubyte {
	S,
	SPF,
	SF,
}

struct UnionMembers {
@safe :

	uint followIdx;
	Token name;

	UnionMembersEnum ruleSelection;

	static UnionMembers ConstructS(Token name) {
		UnionMembers ret;
		ret.ruleSelection = UnionMembersEnum.S;
		ret.name = name;
		return ret;
	}

	static UnionMembers ConstructSPF(Token name, uint follow) {
		UnionMembers ret;
		ret.ruleSelection = UnionMembersEnum.SPF;
		ret.name = name;
		ret.followIdx = follow;
		return ret;
	}

	static UnionMembers ConstructSF(Token name, uint follow) {
		UnionMembers ret;
		ret.ruleSelection = UnionMembersEnum.SF;
		ret.name = name;
		ret.followIdx = follow;
		return ret;
	}

}

enum EnumTypeDefinitionEnum : ubyte {
	NDE,
	NE,
}

struct EnumTypeDefinition {
@safe :

	uint evdsIdx;
	uint dirIdx;
	Token name;

	EnumTypeDefinitionEnum ruleSelection;

	static EnumTypeDefinition ConstructNDE(Token name, uint dir, uint evds) {
		EnumTypeDefinition ret;
		ret.ruleSelection = EnumTypeDefinitionEnum.NDE;
		ret.name = name;
		ret.dirIdx = dir;
		ret.evdsIdx = evds;
		return ret;
	}

	static EnumTypeDefinition ConstructNE(Token name, uint evds) {
		EnumTypeDefinition ret;
		ret.ruleSelection = EnumTypeDefinitionEnum.NE;
		ret.name = name;
		ret.evdsIdx = evds;
		return ret;
	}

}

enum EnumValueDefinitionsEnum : ubyte {
	D,
	DCE,
	DE,
}

struct EnumValueDefinitions {
@safe :

	uint evdIdx;
	uint followIdx;

	EnumValueDefinitionsEnum ruleSelection;

	static EnumValueDefinitions ConstructD(uint evd) {
		EnumValueDefinitions ret;
		ret.ruleSelection = EnumValueDefinitionsEnum.D;
		ret.evdIdx = evd;
		return ret;
	}

	static EnumValueDefinitions ConstructDCE(uint evd, uint follow) {
		EnumValueDefinitions ret;
		ret.ruleSelection = EnumValueDefinitionsEnum.DCE;
		ret.evdIdx = evd;
		ret.followIdx = follow;
		return ret;
	}

	static EnumValueDefinitions ConstructDE(uint evd, uint follow) {
		EnumValueDefinitions ret;
		ret.ruleSelection = EnumValueDefinitionsEnum.DE;
		ret.evdIdx = evd;
		ret.followIdx = follow;
		return ret;
	}

}

enum EnumValueDefinitionEnum : ubyte {
	ED,
	E,
	DED,
	DE,
}

struct EnumValueDefinition {
@safe :

	uint desIdx;
	uint dirsIdx;
	Token name;

	EnumValueDefinitionEnum ruleSelection;

	static EnumValueDefinition ConstructED(Token name, uint dirs) {
		EnumValueDefinition ret;
		ret.ruleSelection = EnumValueDefinitionEnum.ED;
		ret.name = name;
		ret.dirsIdx = dirs;
		return ret;
	}

	static EnumValueDefinition ConstructE(Token name) {
		EnumValueDefinition ret;
		ret.ruleSelection = EnumValueDefinitionEnum.E;
		ret.name = name;
		return ret;
	}

	static EnumValueDefinition ConstructDED(uint des, Token name, uint dirs) {
		EnumValueDefinition ret;
		ret.ruleSelection = EnumValueDefinitionEnum.DED;
		ret.desIdx = des;
		ret.name = name;
		ret.dirsIdx = dirs;
		return ret;
	}

	static EnumValueDefinition ConstructDE(uint des, Token name) {
		EnumValueDefinition ret;
		ret.ruleSelection = EnumValueDefinitionEnum.DE;
		ret.desIdx = des;
		ret.name = name;
		return ret;
	}

}

enum InputTypeDefinitionEnum : ubyte {
	NDE,
	NE,
}

struct InputTypeDefinition {
@safe :

	uint ivdsIdx;
	uint dirIdx;
	Token name;

	InputTypeDefinitionEnum ruleSelection;

	static InputTypeDefinition ConstructNDE(Token name, uint dir, uint ivds) {
		InputTypeDefinition ret;
		ret.ruleSelection = InputTypeDefinitionEnum.NDE;
		ret.name = name;
		ret.dirIdx = dir;
		ret.ivdsIdx = ivds;
		return ret;
	}

	static InputTypeDefinition ConstructNE(Token name, uint ivds) {
		InputTypeDefinition ret;
		ret.ruleSelection = InputTypeDefinitionEnum.NE;
		ret.name = name;
		ret.ivdsIdx = ivds;
		return ret;
	}

}

enum TypeExtensionDefinitionEnum : ubyte {
	O,
}

struct TypeExtensionDefinition {
@safe :

	uint otdIdx;

	TypeExtensionDefinitionEnum ruleSelection;

	static TypeExtensionDefinition ConstructO(uint otd) {
		TypeExtensionDefinition ret;
		ret.ruleSelection = TypeExtensionDefinitionEnum.O;
		ret.otdIdx = otd;
		return ret;
	}

}

enum DirectiveDefinitionEnum : ubyte {
	AD,
	D,
}

struct DirectiveDefinition {
@safe :

	uint dlIdx;
	uint adIdx;
	Token name;

	DirectiveDefinitionEnum ruleSelection;

	static DirectiveDefinition ConstructAD(Token name, uint ad, uint dl) {
		DirectiveDefinition ret;
		ret.ruleSelection = DirectiveDefinitionEnum.AD;
		ret.name = name;
		ret.adIdx = ad;
		ret.dlIdx = dl;
		return ret;
	}

	static DirectiveDefinition ConstructD(Token name, uint dl) {
		DirectiveDefinition ret;
		ret.ruleSelection = DirectiveDefinitionEnum.D;
		ret.name = name;
		ret.dlIdx = dl;
		return ret;
	}

}

enum DirectiveLocationsEnum : ubyte {
	N,
	NPF,
	NF,
}

struct DirectiveLocations {
@safe :

	uint followIdx;
	Token name;

	DirectiveLocationsEnum ruleSelection;

	static DirectiveLocations ConstructN(Token name) {
		DirectiveLocations ret;
		ret.ruleSelection = DirectiveLocationsEnum.N;
		ret.name = name;
		return ret;
	}

	static DirectiveLocations ConstructNPF(Token name, uint follow) {
		DirectiveLocations ret;
		ret.ruleSelection = DirectiveLocationsEnum.NPF;
		ret.name = name;
		ret.followIdx = follow;
		return ret;
	}

	static DirectiveLocations ConstructNF(Token name, uint follow) {
		DirectiveLocations ret;
		ret.ruleSelection = DirectiveLocationsEnum.NF;
		ret.name = name;
		ret.followIdx = follow;
		return ret;
	}

}

enum InputObjectTypeDefinitionEnum : ubyte {
	NDI,
	NI,
}

struct InputObjectTypeDefinition {
@safe :

	uint dirsIdx;
	Token name;

	InputObjectTypeDefinitionEnum ruleSelection;

	static InputObjectTypeDefinition ConstructNDI(Token name, uint dirs) {
		InputObjectTypeDefinition ret;
		ret.ruleSelection = InputObjectTypeDefinitionEnum.NDI;
		ret.name = name;
		ret.dirsIdx = dirs;
		return ret;
	}

	static InputObjectTypeDefinition ConstructNI(Token name) {
		InputObjectTypeDefinition ret;
		ret.ruleSelection = InputObjectTypeDefinitionEnum.NI;
		ret.name = name;
		return ret;
	}

}

enum DescriptionEnum : ubyte {
	S,
}

struct Description {
@safe :

	Token tok;

	DescriptionEnum ruleSelection;

	static Description ConstructS(Token tok) {
		Description ret;
		ret.ruleSelection = DescriptionEnum.S;
		ret.tok = tok;
		return ret;
	}

}

