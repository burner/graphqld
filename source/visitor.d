module visitor;

import std.typecons : RefCounted, refCounted;

import ast;
import tokenmodule;

struct Visitor {

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
			case DefinitionEnum.Op:
				obj.op.visit(this);
				break;
			case DefinitionEnum.Frag:
				obj.frag.visit(this);
				break;
		}
	}

	void accept(const(Definition) obj) {
		final switch(obj.ruleSelection) {
			case DefinitionEnum.Op:
				obj.op.visit(this);
				break;
			case DefinitionEnum.Frag:
				obj.frag.visit(this);
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
		}
	}

	void accept(Selection obj) {
		final switch(obj.ruleSelection) {
			case SelectionEnum.Field:
				obj.field.visit(this);
				break;
			case SelectionEnum.Frag:
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
			case SelectionEnum.Frag:
				obj.frag.visit(this);
				break;
			case SelectionEnum.IFrag:
				obj.ifrag.visit(this);
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
				obj.tok.visit(this);
				break;
			case FieldNameEnum.N:
				obj.tok.visit(this);
				break;
		}
	}

	void accept(const(FieldName) obj) {
		final switch(obj.ruleSelection) {
			case FieldNameEnum.A:
				obj.tok.visit(this);
				break;
			case FieldNameEnum.N:
				obj.tok.visit(this);
				break;
		}
	}

	void accept(Alias obj) {
		final switch(obj.ruleSelection) {
			case AliasEnum.A:
				obj.from.visit(this);
				obj.to.visit(this);
				break;
		}
	}

	void accept(const(Alias) obj) {
		final switch(obj.ruleSelection) {
			case AliasEnum.A:
				obj.from.visit(this);
				obj.to.visit(this);
				break;
		}
	}

	void accept(Argument obj) {
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				break;
		}
	}

	void accept(const(Argument) obj) {
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
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

	void accept(Directive obj) {
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NVV:
				obj.name.visit(this);
				obj.vv.visit(this);
				break;
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
			case DirectiveEnum.NVV:
				obj.name.visit(this);
				obj.vv.visit(this);
				break;
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				obj.arg.visit(this);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
	}

	void accept(TypeCondition obj) {
		final switch(obj.ruleSelection) {
			case TypeConditionEnum.TN:
				obj.tname.visit(this);
				break;
		}
	}

	void accept(const(TypeCondition) obj) {
		final switch(obj.ruleSelection) {
			case TypeConditionEnum.TN:
				obj.tname.visit(this);
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
		}
	}

	void accept(Type obj) {
		final switch(obj.ruleSelection) {
			case TypeEnum.TN:
				obj.tname.visit(this);
				break;
			case TypeEnum.T:
				obj.tname.visit(this);
				break;
		}
	}

	void accept(const(Type) obj) {
		final switch(obj.ruleSelection) {
			case TypeEnum.TN:
				obj.tname.visit(this);
				break;
			case TypeEnum.T:
				obj.tname.visit(this);
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
}
