module visitor;

import ast;
import tokenmodule;

class Visitor {

	void accept(Document obj) {
		final switch(obj.ruleSelection) {
			case DocumentEnum.Defi:
				obj.defs.visit(this);
				break;
		}
	}

	void accept(const(Document) obj) {
		final switch(obj.ruleSelection) {
			case DocumentEnum.Defi:
				obj.defs.visit(this);
				break;
		}
	}

	void accept(Definitions obj) {
		final switch(obj.ruleSelection) {
			case DefinitionsEnum.Def:
				obj.def.visit(this);
				break;
			case DefinitionsEnum.Defs:
				obj.def.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(Definitions) obj) {
		final switch(obj.ruleSelection) {
			case DefinitionsEnum.Def:
				obj.def.visit(this);
				break;
			case DefinitionsEnum.Defs:
				obj.def.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(Definition obj) {
		final switch(obj.ruleSelection) {
			case DefinitionEnum.O:
				obj.op.visit(this);
				break;
			case DefinitionEnum.F:
				obj.frag.visit(this);
				break;
			case DefinitionEnum.T:
				obj.type.visit(this);
				break;
		}
	}

	void accept(const(Definition) obj) {
		final switch(obj.ruleSelection) {
			case DefinitionEnum.O:
				obj.op.visit(this);
				break;
			case DefinitionEnum.F:
				obj.frag.visit(this);
				break;
			case DefinitionEnum.T:
				obj.type.visit(this);
				break;
		}
	}

	void accept(OperationDefinition obj) {
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_VD:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_V:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_D:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.ss.visit(this);
				break;
		}
	}

	void accept(const(OperationDefinition) obj) {
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_VD:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_V:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_D:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.ss.visit(this);
				break;
		}
	}

	void accept(SelectionSet obj) {
		final switch(obj.ruleSelection) {
			case SelectionSetEnum.SS:
				obj.sel.visit(this);
				break;
		}
	}

	void accept(const(SelectionSet) obj) {
		final switch(obj.ruleSelection) {
			case SelectionSetEnum.SS:
				obj.sel.visit(this);
				break;
		}
	}

	void accept(OperationType obj) {
		final switch(obj.ruleSelection) {
			case OperationTypeEnum.Query:
				obj.tok.visit(this);
				break;
			case OperationTypeEnum.Mutation:
				obj.tok.visit(this);
				break;
			case OperationTypeEnum.Sub:
				obj.tok.visit(this);
				break;
		}
	}

	void accept(const(OperationType) obj) {
		final switch(obj.ruleSelection) {
			case OperationTypeEnum.Query:
				obj.tok.visit(this);
				break;
			case OperationTypeEnum.Mutation:
				obj.tok.visit(this);
				break;
			case OperationTypeEnum.Sub:
				obj.tok.visit(this);
				break;
		}
	}

	void accept(Selections obj) {
		final switch(obj.ruleSelection) {
			case SelectionsEnum.Sel:
				obj.sel.visit(this);
				break;
			case SelectionsEnum.Sels:
				obj.sel.visit(this);
				obj.follow.visit(this);
				break;
			case SelectionsEnum.Selsc:
				obj.sel.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(Selections) obj) {
		final switch(obj.ruleSelection) {
			case SelectionsEnum.Sel:
				obj.sel.visit(this);
				break;
			case SelectionsEnum.Sels:
				obj.sel.visit(this);
				obj.follow.visit(this);
				break;
			case SelectionsEnum.Selsc:
				obj.sel.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(Selection obj) {
		final switch(obj.ruleSelection) {
			case SelectionEnum.Field:
				obj.field.visit(this);
				break;
			case SelectionEnum.Spread:
				obj.frag.visit(this);
				break;
			case SelectionEnum.IFrag:
				obj.ifrag.visit(this);
				break;
		}
	}

	void accept(const(Selection) obj) {
		final switch(obj.ruleSelection) {
			case SelectionEnum.Field:
				obj.field.visit(this);
				break;
			case SelectionEnum.Spread:
				obj.frag.visit(this);
				break;
			case SelectionEnum.IFrag:
				obj.ifrag.visit(this);
				break;
		}
	}

	void accept(FragmentSpread obj) {
		final switch(obj.ruleSelection) {
			case FragmentSpreadEnum.FD:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case FragmentSpreadEnum.F:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(FragmentSpread) obj) {
		final switch(obj.ruleSelection) {
			case FragmentSpreadEnum.FD:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case FragmentSpreadEnum.F:
				obj.name.visit(this);
				break;
		}
	}

	void accept(InlineFragment obj) {
		final switch(obj.ruleSelection) {
			case InlineFragmentEnum.TDS:
				obj.tc.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.TS:
				obj.tc.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.DS:
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.S:
				obj.ss.visit(this);
				break;
		}
	}

	void accept(const(InlineFragment) obj) {
		final switch(obj.ruleSelection) {
			case InlineFragmentEnum.TDS:
				obj.tc.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.TS:
				obj.tc.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.DS:
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.S:
				obj.ss.visit(this);
				break;
		}
	}

	void accept(Field obj) {
		final switch(obj.ruleSelection) {
			case FieldEnum.FADS:
				obj.name.visit(this);
				obj.args.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FAS:
				obj.name.visit(this);
				obj.args.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FAD:
				obj.name.visit(this);
				obj.args.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FDS:
				obj.name.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FS:
				obj.name.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FD:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FA:
				obj.name.visit(this);
				obj.args.visit(this);
				break;
			case FieldEnum.F:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(Field) obj) {
		final switch(obj.ruleSelection) {
			case FieldEnum.FADS:
				obj.name.visit(this);
				obj.args.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FAS:
				obj.name.visit(this);
				obj.args.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FAD:
				obj.name.visit(this);
				obj.args.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FDS:
				obj.name.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FS:
				obj.name.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FD:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FA:
				obj.name.visit(this);
				obj.args.visit(this);
				break;
			case FieldEnum.F:
				obj.name.visit(this);
				break;
		}
	}

	void accept(FieldName obj) {
		final switch(obj.ruleSelection) {
			case FieldNameEnum.A:
				obj.name.visit(this);
				obj.aka.visit(this);
				break;
			case FieldNameEnum.N:
				obj.name.visit(this);
				break;
			case FieldNameEnum.T:
				obj.type.visit(this);
				break;
			case FieldNameEnum.S:
				obj.schema.visit(this);
				break;
		}
	}

	void accept(const(FieldName) obj) {
		final switch(obj.ruleSelection) {
			case FieldNameEnum.A:
				obj.name.visit(this);
				obj.aka.visit(this);
				break;
			case FieldNameEnum.N:
				obj.name.visit(this);
				break;
			case FieldNameEnum.T:
				obj.type.visit(this);
				break;
			case FieldNameEnum.S:
				obj.schema.visit(this);
				break;
		}
	}

	void accept(Arguments obj) {
		final switch(obj.ruleSelection) {
			case ArgumentsEnum.List:
				obj.arg.visit(this);
				break;
			case ArgumentsEnum.Empty:
				break;
		}
	}

	void accept(const(Arguments) obj) {
		final switch(obj.ruleSelection) {
			case ArgumentsEnum.List:
				obj.arg.visit(this);
				break;
			case ArgumentsEnum.Empty:
				break;
		}
	}

	void accept(ArgumentList obj) {
		final switch(obj.ruleSelection) {
			case ArgumentListEnum.A:
				obj.arg.visit(this);
				break;
			case ArgumentListEnum.ACS:
				obj.arg.visit(this);
				obj.follow.visit(this);
				break;
			case ArgumentListEnum.AS:
				obj.arg.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(ArgumentList) obj) {
		final switch(obj.ruleSelection) {
			case ArgumentListEnum.A:
				obj.arg.visit(this);
				break;
			case ArgumentListEnum.ACS:
				obj.arg.visit(this);
				obj.follow.visit(this);
				break;
			case ArgumentListEnum.AS:
				obj.arg.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(Argument obj) {
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				obj.vv.visit(this);
				break;
		}
	}

	void accept(const(Argument) obj) {
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				obj.vv.visit(this);
				break;
		}
	}

	void accept(FragmentDefinition obj) {
		final switch(obj.ruleSelection) {
			case FragmentDefinitionEnum.FTDS:
				obj.name.visit(this);
				obj.tc.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FragmentDefinitionEnum.FTS:
				obj.name.visit(this);
				obj.tc.visit(this);
				obj.ss.visit(this);
				break;
		}
	}

	void accept(const(FragmentDefinition) obj) {
		final switch(obj.ruleSelection) {
			case FragmentDefinitionEnum.FTDS:
				obj.name.visit(this);
				obj.tc.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FragmentDefinitionEnum.FTS:
				obj.name.visit(this);
				obj.tc.visit(this);
				obj.ss.visit(this);
				break;
		}
	}

	void accept(Directives obj) {
		final switch(obj.ruleSelection) {
			case DirectivesEnum.Dir:
				obj.dir.visit(this);
				break;
			case DirectivesEnum.Dirs:
				obj.dir.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(Directives) obj) {
		final switch(obj.ruleSelection) {
			case DirectivesEnum.Dir:
				obj.dir.visit(this);
				break;
			case DirectivesEnum.Dirs:
				obj.dir.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(Directive obj) {
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				obj.arg.visit(this);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(Directive) obj) {
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				obj.arg.visit(this);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
	}

	void accept(VariableDefinitions obj) {
		final switch(obj.ruleSelection) {
			case VariableDefinitionsEnum.Empty:
				break;
			case VariableDefinitionsEnum.Vars:
				obj.vars.visit(this);
				break;
		}
	}

	void accept(const(VariableDefinitions) obj) {
		final switch(obj.ruleSelection) {
			case VariableDefinitionsEnum.Empty:
				break;
			case VariableDefinitionsEnum.Vars:
				obj.vars.visit(this);
				break;
		}
	}

	void accept(VariableDefinitionList obj) {
		final switch(obj.ruleSelection) {
			case VariableDefinitionListEnum.V:
				obj.var.visit(this);
				break;
			case VariableDefinitionListEnum.VCF:
				obj.var.visit(this);
				obj.follow.visit(this);
				break;
			case VariableDefinitionListEnum.VF:
				obj.var.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(VariableDefinitionList) obj) {
		final switch(obj.ruleSelection) {
			case VariableDefinitionListEnum.V:
				obj.var.visit(this);
				break;
			case VariableDefinitionListEnum.VCF:
				obj.var.visit(this);
				obj.follow.visit(this);
				break;
			case VariableDefinitionListEnum.VF:
				obj.var.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(VariableDefinition obj) {
		final switch(obj.ruleSelection) {
			case VariableDefinitionEnum.VarD:
				obj.type.visit(this);
				obj.dvalue.visit(this);
				break;
			case VariableDefinitionEnum.Var:
				obj.type.visit(this);
				break;
		}
	}

	void accept(const(VariableDefinition) obj) {
		final switch(obj.ruleSelection) {
			case VariableDefinitionEnum.VarD:
				obj.type.visit(this);
				obj.dvalue.visit(this);
				break;
			case VariableDefinitionEnum.Var:
				obj.type.visit(this);
				break;
		}
	}

	void accept(Variable obj) {
		final switch(obj.ruleSelection) {
			case VariableEnum.Var:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(Variable) obj) {
		final switch(obj.ruleSelection) {
			case VariableEnum.Var:
				obj.name.visit(this);
				break;
		}
	}

	void accept(DefaultValue obj) {
		final switch(obj.ruleSelection) {
			case DefaultValueEnum.DV:
				obj.value.visit(this);
				break;
		}
	}

	void accept(const(DefaultValue) obj) {
		final switch(obj.ruleSelection) {
			case DefaultValueEnum.DV:
				obj.value.visit(this);
				break;
		}
	}

	void accept(ValueOrVariable obj) {
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				obj.val.visit(this);
				break;
			case ValueOrVariableEnum.Var:
				obj.var.visit(this);
				break;
		}
	}

	void accept(const(ValueOrVariable) obj) {
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				obj.val.visit(this);
				break;
			case ValueOrVariableEnum.Var:
				obj.var.visit(this);
				break;
		}
	}

	void accept(Value obj) {
		final switch(obj.ruleSelection) {
			case ValueEnum.STR:
				obj.tok.visit(this);
				break;
			case ValueEnum.INT:
				obj.tok.visit(this);
				break;
			case ValueEnum.FLOAT:
				obj.tok.visit(this);
				break;
			case ValueEnum.T:
				obj.tok.visit(this);
				break;
			case ValueEnum.F:
				obj.tok.visit(this);
				break;
			case ValueEnum.ARR:
				obj.arr.visit(this);
				break;
			case ValueEnum.O:
				obj.obj.visit(this);
				break;
		}
	}

	void accept(const(Value) obj) {
		final switch(obj.ruleSelection) {
			case ValueEnum.STR:
				obj.tok.visit(this);
				break;
			case ValueEnum.INT:
				obj.tok.visit(this);
				break;
			case ValueEnum.FLOAT:
				obj.tok.visit(this);
				break;
			case ValueEnum.T:
				obj.tok.visit(this);
				break;
			case ValueEnum.F:
				obj.tok.visit(this);
				break;
			case ValueEnum.ARR:
				obj.arr.visit(this);
				break;
			case ValueEnum.O:
				obj.obj.visit(this);
				break;
		}
	}

	void accept(Type obj) {
		final switch(obj.ruleSelection) {
			case TypeEnum.TN:
				obj.tname.visit(this);
				break;
			case TypeEnum.LN:
				obj.list.visit(this);
				break;
			case TypeEnum.T:
				obj.tname.visit(this);
				break;
			case TypeEnum.L:
				obj.list.visit(this);
				break;
		}
	}

	void accept(const(Type) obj) {
		final switch(obj.ruleSelection) {
			case TypeEnum.TN:
				obj.tname.visit(this);
				break;
			case TypeEnum.LN:
				obj.list.visit(this);
				break;
			case TypeEnum.T:
				obj.tname.visit(this);
				break;
			case TypeEnum.L:
				obj.list.visit(this);
				break;
		}
	}

	void accept(ListType obj) {
		final switch(obj.ruleSelection) {
			case ListTypeEnum.T:
				obj.type.visit(this);
				break;
		}
	}

	void accept(const(ListType) obj) {
		final switch(obj.ruleSelection) {
			case ListTypeEnum.T:
				obj.type.visit(this);
				break;
		}
	}

	void accept(Values obj) {
		final switch(obj.ruleSelection) {
			case ValuesEnum.Val:
				obj.val.visit(this);
				break;
			case ValuesEnum.Vals:
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(Values) obj) {
		final switch(obj.ruleSelection) {
			case ValuesEnum.Val:
				obj.val.visit(this);
				break;
			case ValuesEnum.Vals:
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(Array obj) {
		final switch(obj.ruleSelection) {
			case ArrayEnum.Empty:
				break;
			case ArrayEnum.Value:
				obj.vals.visit(this);
				break;
		}
	}

	void accept(const(Array) obj) {
		final switch(obj.ruleSelection) {
			case ArrayEnum.Empty:
				break;
			case ArrayEnum.Value:
				obj.vals.visit(this);
				break;
		}
	}

	void accept(ObjectValues obj) {
		final switch(obj.ruleSelection) {
			case ObjectValuesEnum.V:
				obj.name.visit(this);
				obj.val.visit(this);
				break;
			case ObjectValuesEnum.Vsc:
				obj.name.visit(this);
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
			case ObjectValuesEnum.Vs:
				obj.name.visit(this);
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(ObjectValues) obj) {
		final switch(obj.ruleSelection) {
			case ObjectValuesEnum.V:
				obj.name.visit(this);
				obj.val.visit(this);
				break;
			case ObjectValuesEnum.Vsc:
				obj.name.visit(this);
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
			case ObjectValuesEnum.Vs:
				obj.name.visit(this);
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(ObjectValue obj) {
		final switch(obj.ruleSelection) {
			case ObjectValueEnum.V:
				obj.name.visit(this);
				obj.val.visit(this);
				break;
		}
	}

	void accept(const(ObjectValue) obj) {
		final switch(obj.ruleSelection) {
			case ObjectValueEnum.V:
				obj.name.visit(this);
				obj.val.visit(this);
				break;
		}
	}

	void accept(ObjectType obj) {
		final switch(obj.ruleSelection) {
			case ObjectTypeEnum.Var:
				obj.vals.visit(this);
				break;
		}
	}

	void accept(const(ObjectType) obj) {
		final switch(obj.ruleSelection) {
			case ObjectTypeEnum.Var:
				obj.vals.visit(this);
				break;
		}
	}

	void accept(TypeSystemDefinition obj) {
		final switch(obj.ruleSelection) {
			case TypeSystemDefinitionEnum.S:
				obj.sch.visit(this);
				break;
			case TypeSystemDefinitionEnum.T:
				obj.td.visit(this);
				break;
			case TypeSystemDefinitionEnum.TE:
				obj.ted.visit(this);
				break;
			case TypeSystemDefinitionEnum.D:
				obj.dd.visit(this);
				break;
		}
	}

	void accept(const(TypeSystemDefinition) obj) {
		final switch(obj.ruleSelection) {
			case TypeSystemDefinitionEnum.S:
				obj.sch.visit(this);
				break;
			case TypeSystemDefinitionEnum.T:
				obj.td.visit(this);
				break;
			case TypeSystemDefinitionEnum.TE:
				obj.ted.visit(this);
				break;
			case TypeSystemDefinitionEnum.D:
				obj.dd.visit(this);
				break;
		}
	}

	void accept(TypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case TypeDefinitionEnum.S:
				obj.std.visit(this);
				break;
			case TypeDefinitionEnum.O:
				obj.otd.visit(this);
				break;
			case TypeDefinitionEnum.I:
				obj.itd.visit(this);
				break;
			case TypeDefinitionEnum.U:
				obj.utd.visit(this);
				break;
			case TypeDefinitionEnum.E:
				obj.etd.visit(this);
				break;
			case TypeDefinitionEnum.IO:
				obj.iod.visit(this);
				break;
		}
	}

	void accept(const(TypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case TypeDefinitionEnum.S:
				obj.std.visit(this);
				break;
			case TypeDefinitionEnum.O:
				obj.otd.visit(this);
				break;
			case TypeDefinitionEnum.I:
				obj.itd.visit(this);
				break;
			case TypeDefinitionEnum.U:
				obj.utd.visit(this);
				break;
			case TypeDefinitionEnum.E:
				obj.etd.visit(this);
				break;
			case TypeDefinitionEnum.IO:
				obj.iod.visit(this);
				break;
		}
	}

	void accept(SchemaDefinition obj) {
		final switch(obj.ruleSelection) {
			case SchemaDefinitionEnum.DO:
				obj.dir.visit(this);
				obj.otds.visit(this);
				break;
			case SchemaDefinitionEnum.O:
				obj.otds.visit(this);
				break;
		}
	}

	void accept(const(SchemaDefinition) obj) {
		final switch(obj.ruleSelection) {
			case SchemaDefinitionEnum.DO:
				obj.dir.visit(this);
				obj.otds.visit(this);
				break;
			case SchemaDefinitionEnum.O:
				obj.otds.visit(this);
				break;
		}
	}

	void accept(OperationTypeDefinitions obj) {
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionsEnum.O:
				obj.otd.visit(this);
				break;
			case OperationTypeDefinitionsEnum.OCS:
				obj.otd.visit(this);
				obj.follow.visit(this);
				break;
			case OperationTypeDefinitionsEnum.OS:
				obj.otd.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(OperationTypeDefinitions) obj) {
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionsEnum.O:
				obj.otd.visit(this);
				break;
			case OperationTypeDefinitionsEnum.OCS:
				obj.otd.visit(this);
				obj.follow.visit(this);
				break;
			case OperationTypeDefinitionsEnum.OS:
				obj.otd.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(OperationTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionEnum.O:
				obj.ot.visit(this);
				obj.nt.visit(this);
				break;
		}
	}

	void accept(const(OperationTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionEnum.O:
				obj.ot.visit(this);
				obj.nt.visit(this);
				break;
		}
	}

	void accept(ScalarTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case ScalarTypeDefinitionEnum.D:
				obj.name.visit(this);
				obj.dir.visit(this);
				break;
			case ScalarTypeDefinitionEnum.S:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(ScalarTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case ScalarTypeDefinitionEnum.D:
				obj.name.visit(this);
				obj.dir.visit(this);
				break;
			case ScalarTypeDefinitionEnum.S:
				obj.name.visit(this);
				break;
		}
	}

	void accept(ObjectTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case ObjectTypeDefinitionEnum.ID:
				obj.name.visit(this);
				obj.ii.visit(this);
				obj.dir.visit(this);
				obj.fds.visit(this);
				break;
			case ObjectTypeDefinitionEnum.I:
				obj.name.visit(this);
				obj.ii.visit(this);
				obj.fds.visit(this);
				break;
			case ObjectTypeDefinitionEnum.D:
				obj.name.visit(this);
				obj.dir.visit(this);
				obj.fds.visit(this);
				break;
			case ObjectTypeDefinitionEnum.F:
				obj.name.visit(this);
				obj.fds.visit(this);
				break;
		}
	}

	void accept(const(ObjectTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case ObjectTypeDefinitionEnum.ID:
				obj.name.visit(this);
				obj.ii.visit(this);
				obj.dir.visit(this);
				obj.fds.visit(this);
				break;
			case ObjectTypeDefinitionEnum.I:
				obj.name.visit(this);
				obj.ii.visit(this);
				obj.fds.visit(this);
				break;
			case ObjectTypeDefinitionEnum.D:
				obj.name.visit(this);
				obj.dir.visit(this);
				obj.fds.visit(this);
				break;
			case ObjectTypeDefinitionEnum.F:
				obj.name.visit(this);
				obj.fds.visit(this);
				break;
		}
	}

	void accept(FieldDefinitions obj) {
		final switch(obj.ruleSelection) {
			case FieldDefinitionsEnum.F:
				obj.fd.visit(this);
				break;
			case FieldDefinitionsEnum.FC:
				obj.fd.visit(this);
				obj.follow.visit(this);
				break;
			case FieldDefinitionsEnum.FNC:
				obj.fd.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(FieldDefinitions) obj) {
		final switch(obj.ruleSelection) {
			case FieldDefinitionsEnum.F:
				obj.fd.visit(this);
				break;
			case FieldDefinitionsEnum.FC:
				obj.fd.visit(this);
				obj.follow.visit(this);
				break;
			case FieldDefinitionsEnum.FNC:
				obj.fd.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(FieldDefinition obj) {
		final switch(obj.ruleSelection) {
			case FieldDefinitionEnum.AD:
				obj.name.visit(this);
				obj.arg.visit(this);
				obj.typ.visit(this);
				obj.dir.visit(this);
				break;
			case FieldDefinitionEnum.A:
				obj.name.visit(this);
				obj.arg.visit(this);
				obj.typ.visit(this);
				break;
			case FieldDefinitionEnum.D:
				obj.name.visit(this);
				obj.typ.visit(this);
				obj.dir.visit(this);
				break;
			case FieldDefinitionEnum.T:
				obj.name.visit(this);
				obj.typ.visit(this);
				break;
		}
	}

	void accept(const(FieldDefinition) obj) {
		final switch(obj.ruleSelection) {
			case FieldDefinitionEnum.AD:
				obj.name.visit(this);
				obj.arg.visit(this);
				obj.typ.visit(this);
				obj.dir.visit(this);
				break;
			case FieldDefinitionEnum.A:
				obj.name.visit(this);
				obj.arg.visit(this);
				obj.typ.visit(this);
				break;
			case FieldDefinitionEnum.D:
				obj.name.visit(this);
				obj.typ.visit(this);
				obj.dir.visit(this);
				break;
			case FieldDefinitionEnum.T:
				obj.name.visit(this);
				obj.typ.visit(this);
				break;
		}
	}

	void accept(ImplementsInterfaces obj) {
		final switch(obj.ruleSelection) {
			case ImplementsInterfacesEnum.N:
				obj.nts.visit(this);
				break;
		}
	}

	void accept(const(ImplementsInterfaces) obj) {
		final switch(obj.ruleSelection) {
			case ImplementsInterfacesEnum.N:
				obj.nts.visit(this);
				break;
		}
	}

	void accept(NamedTypes obj) {
		final switch(obj.ruleSelection) {
			case NamedTypesEnum.N:
				obj.name.visit(this);
				break;
			case NamedTypesEnum.NCS:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
			case NamedTypesEnum.NS:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(NamedTypes) obj) {
		final switch(obj.ruleSelection) {
			case NamedTypesEnum.N:
				obj.name.visit(this);
				break;
			case NamedTypesEnum.NCS:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
			case NamedTypesEnum.NS:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(ArgumentsDefinition obj) {
		final switch(obj.ruleSelection) {
			case ArgumentsDefinitionEnum.A:
				break;
		}
	}

	void accept(const(ArgumentsDefinition) obj) {
		final switch(obj.ruleSelection) {
			case ArgumentsDefinitionEnum.A:
				break;
		}
	}

	void accept(InputValueDefinitions obj) {
		final switch(obj.ruleSelection) {
			case InputValueDefinitionsEnum.I:
				obj.iv.visit(this);
				break;
			case InputValueDefinitionsEnum.ICF:
				obj.iv.visit(this);
				obj.follow.visit(this);
				break;
			case InputValueDefinitionsEnum.IF:
				obj.iv.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(InputValueDefinitions) obj) {
		final switch(obj.ruleSelection) {
			case InputValueDefinitionsEnum.I:
				obj.iv.visit(this);
				break;
			case InputValueDefinitionsEnum.ICF:
				obj.iv.visit(this);
				obj.follow.visit(this);
				break;
			case InputValueDefinitionsEnum.IF:
				obj.iv.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(InputValueDefinition obj) {
		final switch(obj.ruleSelection) {
			case InputValueDefinitionEnum.TVD:
				obj.name.visit(this);
				obj.type.visit(this);
				obj.df.visit(this);
				obj.dirs.visit(this);
				break;
			case InputValueDefinitionEnum.TD:
				obj.name.visit(this);
				obj.type.visit(this);
				obj.dirs.visit(this);
				break;
			case InputValueDefinitionEnum.TV:
				obj.name.visit(this);
				obj.type.visit(this);
				obj.df.visit(this);
				break;
			case InputValueDefinitionEnum.T:
				obj.name.visit(this);
				obj.type.visit(this);
				break;
		}
	}

	void accept(const(InputValueDefinition) obj) {
		final switch(obj.ruleSelection) {
			case InputValueDefinitionEnum.TVD:
				obj.name.visit(this);
				obj.type.visit(this);
				obj.df.visit(this);
				obj.dirs.visit(this);
				break;
			case InputValueDefinitionEnum.TD:
				obj.name.visit(this);
				obj.type.visit(this);
				obj.dirs.visit(this);
				break;
			case InputValueDefinitionEnum.TV:
				obj.name.visit(this);
				obj.type.visit(this);
				obj.df.visit(this);
				break;
			case InputValueDefinitionEnum.T:
				obj.name.visit(this);
				obj.type.visit(this);
				break;
		}
	}

	void accept(InterfaceTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case InterfaceTypeDefinitionEnum.NDF:
				obj.name.visit(this);
				obj.dirs.visit(this);
				obj.fds.visit(this);
				break;
			case InterfaceTypeDefinitionEnum.NF:
				obj.name.visit(this);
				obj.fds.visit(this);
				break;
		}
	}

	void accept(const(InterfaceTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case InterfaceTypeDefinitionEnum.NDF:
				obj.name.visit(this);
				obj.dirs.visit(this);
				obj.fds.visit(this);
				break;
			case InterfaceTypeDefinitionEnum.NF:
				obj.name.visit(this);
				obj.fds.visit(this);
				break;
		}
	}

	void accept(UnionTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case UnionTypeDefinitionEnum.NDU:
				obj.name.visit(this);
				obj.dirs.visit(this);
				obj.um.visit(this);
				break;
			case UnionTypeDefinitionEnum.NU:
				obj.name.visit(this);
				obj.um.visit(this);
				break;
		}
	}

	void accept(const(UnionTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case UnionTypeDefinitionEnum.NDU:
				obj.name.visit(this);
				obj.dirs.visit(this);
				obj.um.visit(this);
				break;
			case UnionTypeDefinitionEnum.NU:
				obj.name.visit(this);
				obj.um.visit(this);
				break;
		}
	}

	void accept(UnionMembers obj) {
		final switch(obj.ruleSelection) {
			case UnionMembersEnum.S:
				obj.name.visit(this);
				break;
			case UnionMembersEnum.SPF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
			case UnionMembersEnum.SF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(UnionMembers) obj) {
		final switch(obj.ruleSelection) {
			case UnionMembersEnum.S:
				obj.name.visit(this);
				break;
			case UnionMembersEnum.SPF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
			case UnionMembersEnum.SF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(EnumTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case EnumTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				obj.dir.visit(this);
				obj.evds.visit(this);
				break;
			case EnumTypeDefinitionEnum.NE:
				obj.name.visit(this);
				obj.evds.visit(this);
				break;
		}
	}

	void accept(const(EnumTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case EnumTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				obj.dir.visit(this);
				obj.evds.visit(this);
				break;
			case EnumTypeDefinitionEnum.NE:
				obj.name.visit(this);
				obj.evds.visit(this);
				break;
		}
	}

	void accept(EnumValueDefinitions obj) {
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionsEnum.D:
				obj.evd.visit(this);
				break;
			case EnumValueDefinitionsEnum.DCE:
				obj.evd.visit(this);
				obj.follow.visit(this);
				break;
			case EnumValueDefinitionsEnum.DE:
				obj.evd.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(EnumValueDefinitions) obj) {
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionsEnum.D:
				obj.evd.visit(this);
				break;
			case EnumValueDefinitionsEnum.DCE:
				obj.evd.visit(this);
				obj.follow.visit(this);
				break;
			case EnumValueDefinitionsEnum.DE:
				obj.evd.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(EnumValueDefinition obj) {
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionEnum.ED:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case EnumValueDefinitionEnum.E:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(EnumValueDefinition) obj) {
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionEnum.ED:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case EnumValueDefinitionEnum.E:
				obj.name.visit(this);
				break;
		}
	}

	void accept(InputTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case InputTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				obj.dir.visit(this);
				obj.ivds.visit(this);
				break;
			case InputTypeDefinitionEnum.NE:
				obj.name.visit(this);
				obj.ivds.visit(this);
				break;
		}
	}

	void accept(const(InputTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case InputTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				obj.dir.visit(this);
				obj.ivds.visit(this);
				break;
			case InputTypeDefinitionEnum.NE:
				obj.name.visit(this);
				obj.ivds.visit(this);
				break;
		}
	}

	void accept(TypeExtensionDefinition obj) {
		final switch(obj.ruleSelection) {
			case TypeExtensionDefinitionEnum.O:
				obj.otd.visit(this);
				break;
		}
	}

	void accept(const(TypeExtensionDefinition) obj) {
		final switch(obj.ruleSelection) {
			case TypeExtensionDefinitionEnum.O:
				obj.otd.visit(this);
				break;
		}
	}

	void accept(DirectiveDefinition obj) {
		final switch(obj.ruleSelection) {
			case DirectiveDefinitionEnum.AD:
				obj.name.visit(this);
				obj.ad.visit(this);
				obj.dl.visit(this);
				break;
			case DirectiveDefinitionEnum.D:
				obj.name.visit(this);
				obj.dl.visit(this);
				break;
		}
	}

	void accept(const(DirectiveDefinition) obj) {
		final switch(obj.ruleSelection) {
			case DirectiveDefinitionEnum.AD:
				obj.name.visit(this);
				obj.ad.visit(this);
				obj.dl.visit(this);
				break;
			case DirectiveDefinitionEnum.D:
				obj.name.visit(this);
				obj.dl.visit(this);
				break;
		}
	}

	void accept(DirectiveLocations obj) {
		final switch(obj.ruleSelection) {
			case DirectiveLocationsEnum.N:
				obj.name.visit(this);
				break;
			case DirectiveLocationsEnum.NPF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
			case DirectiveLocationsEnum.NF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(const(DirectiveLocations) obj) {
		final switch(obj.ruleSelection) {
			case DirectiveLocationsEnum.N:
				obj.name.visit(this);
				break;
			case DirectiveLocationsEnum.NPF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
			case DirectiveLocationsEnum.NF:
				obj.name.visit(this);
				obj.follow.visit(this);
				break;
		}
	}

	void accept(InputObjectTypeDefinition obj) {
		final switch(obj.ruleSelection) {
			case InputObjectTypeDefinitionEnum.NDI:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case InputObjectTypeDefinitionEnum.NI:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(InputObjectTypeDefinition) obj) {
		final switch(obj.ruleSelection) {
			case InputObjectTypeDefinitionEnum.NDI:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case InputObjectTypeDefinitionEnum.NI:
				obj.name.visit(this);
				break;
		}
	}
}
