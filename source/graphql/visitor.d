module graphql.visitor;

import graphql.ast;
import graphql.tokenmodule;

class Visitor : ConstVisitor {
@safe :

	alias accept = ConstVisitor.accept;

	alias enter = ConstVisitor.enter;

	alias exit = ConstVisitor.exit;


	void enter(Document obj) {}
	void exit(Document obj) {}

	void accept(Document obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DocumentEnum.Defi:
				obj.defs.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Definitions obj) {}
	void exit(Definitions obj) {}

	void accept(Definitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefinitionsEnum.Def:
				obj.def.visit(this);
				break;
			case DefinitionsEnum.Defs:
				obj.def.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Definition obj) {}
	void exit(Definition obj) {}

	void accept(Definition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(OperationDefinition obj) {}
	void exit(OperationDefinition obj) {}

	void accept(OperationDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_VD:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_V:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_D:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_VD:
				obj.ot.visit(this);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_V:
				obj.ot.visit(this);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_D:
				obj.ot.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT:
				obj.ot.visit(this);
				obj.ss.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(SelectionSet obj) {}
	void exit(SelectionSet obj) {}

	void accept(SelectionSet obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionSetEnum.SS:
				obj.sel.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(OperationType obj) {}
	void exit(OperationType obj) {}

	void accept(OperationType obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(Selections obj) {}
	void exit(Selections obj) {}

	void accept(Selections obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(Selection obj) {}
	void exit(Selection obj) {}

	void accept(Selection obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(FragmentSpread obj) {}
	void exit(FragmentSpread obj) {}

	void accept(FragmentSpread obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FragmentSpreadEnum.FD:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case FragmentSpreadEnum.F:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(InlineFragment obj) {}
	void exit(InlineFragment obj) {}

	void accept(InlineFragment obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(Field obj) {}
	void exit(Field obj) {}

	void accept(Field obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(FieldName obj) {}
	void exit(FieldName obj) {}

	void accept(FieldName obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldNameEnum.A:
				obj.name.visit(this);
				obj.aka.visit(this);
				break;
			case FieldNameEnum.N:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Arguments obj) {}
	void exit(Arguments obj) {}

	void accept(Arguments obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsEnum.List:
				obj.arg.visit(this);
				break;
			case ArgumentsEnum.Empty:
				break;
		}
		exit(obj);
	}

	void enter(ArgumentList obj) {}
	void exit(ArgumentList obj) {}

	void accept(ArgumentList obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(Argument obj) {}
	void exit(Argument obj) {}

	void accept(Argument obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				obj.vv.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(FragmentDefinition obj) {}
	void exit(FragmentDefinition obj) {}

	void accept(FragmentDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(Directives obj) {}
	void exit(Directives obj) {}

	void accept(Directives obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectivesEnum.Dir:
				obj.dir.visit(this);
				break;
			case DirectivesEnum.Dirs:
				obj.dir.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Directive obj) {}
	void exit(Directive obj) {}

	void accept(Directive obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				obj.arg.visit(this);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(VariableDefinitions obj) {}
	void exit(VariableDefinitions obj) {}

	void accept(VariableDefinitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionsEnum.Empty:
				break;
			case VariableDefinitionsEnum.Vars:
				obj.vars.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(VariableDefinitionList obj) {}
	void exit(VariableDefinitionList obj) {}

	void accept(VariableDefinitionList obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(VariableDefinition obj) {}
	void exit(VariableDefinition obj) {}

	void accept(VariableDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionEnum.VarD:
				obj.var.visit(this);
				obj.type.visit(this);
				obj.dvalue.visit(this);
				break;
			case VariableDefinitionEnum.Var:
				obj.var.visit(this);
				obj.type.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Variable obj) {}
	void exit(Variable obj) {}

	void accept(Variable obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableEnum.Var:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(DefaultValue obj) {}
	void exit(DefaultValue obj) {}

	void accept(DefaultValue obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefaultValueEnum.DV:
				obj.value.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ValueOrVariable obj) {}
	void exit(ValueOrVariable obj) {}

	void accept(ValueOrVariable obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				obj.val.visit(this);
				break;
			case ValueOrVariableEnum.Var:
				obj.var.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Value obj) {}
	void exit(Value obj) {}

	void accept(Value obj) {
		enter(obj);
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
			case ValueEnum.E:
				obj.tok.visit(this);
				break;
			case ValueEnum.N:
				obj.tok.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Type obj) {}
	void exit(Type obj) {}

	void accept(Type obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(ListType obj) {}
	void exit(ListType obj) {}

	void accept(ListType obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ListTypeEnum.T:
				obj.type.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Values obj) {}
	void exit(Values obj) {}

	void accept(Values obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValuesEnum.Val:
				obj.val.visit(this);
				break;
			case ValuesEnum.Vals:
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Array obj) {}
	void exit(Array obj) {}

	void accept(Array obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArrayEnum.Empty:
				break;
			case ArrayEnum.Value:
				obj.vals.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ObjectValues obj) {}
	void exit(ObjectValues obj) {}

	void accept(ObjectValues obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(ObjectType obj) {}
	void exit(ObjectType obj) {}

	void accept(ObjectType obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectTypeEnum.Var:
				obj.vals.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(TypeSystemDefinition obj) {}
	void exit(TypeSystemDefinition obj) {}

	void accept(TypeSystemDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(TypeDefinition obj) {}
	void exit(TypeDefinition obj) {}

	void accept(TypeDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(SchemaDefinition obj) {}
	void exit(SchemaDefinition obj) {}

	void accept(SchemaDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SchemaDefinitionEnum.DO:
				obj.dir.visit(this);
				obj.otds.visit(this);
				break;
			case SchemaDefinitionEnum.O:
				obj.otds.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(OperationTypeDefinitions obj) {}
	void exit(OperationTypeDefinitions obj) {}

	void accept(OperationTypeDefinitions obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(OperationTypeDefinition obj) {}
	void exit(OperationTypeDefinition obj) {}

	void accept(OperationTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionEnum.O:
				obj.ot.visit(this);
				obj.nt.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ScalarTypeDefinition obj) {}
	void exit(ScalarTypeDefinition obj) {}

	void accept(ScalarTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ScalarTypeDefinitionEnum.D:
				obj.name.visit(this);
				obj.dir.visit(this);
				break;
			case ScalarTypeDefinitionEnum.S:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ObjectTypeDefinition obj) {}
	void exit(ObjectTypeDefinition obj) {}

	void accept(ObjectTypeDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(FieldDefinitions obj) {}
	void exit(FieldDefinitions obj) {}

	void accept(FieldDefinitions obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(FieldDefinition obj) {}
	void exit(FieldDefinition obj) {}

	void accept(FieldDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(ImplementsInterfaces obj) {}
	void exit(ImplementsInterfaces obj) {}

	void accept(ImplementsInterfaces obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ImplementsInterfacesEnum.N:
				obj.nts.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(NamedTypes obj) {}
	void exit(NamedTypes obj) {}

	void accept(NamedTypes obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(ArgumentsDefinition obj) {}
	void exit(ArgumentsDefinition obj) {}

	void accept(ArgumentsDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsDefinitionEnum.A:
				break;
		}
		exit(obj);
	}

	void enter(InputValueDefinitions obj) {}
	void exit(InputValueDefinitions obj) {}

	void accept(InputValueDefinitions obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(InputValueDefinition obj) {}
	void exit(InputValueDefinition obj) {}

	void accept(InputValueDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(InterfaceTypeDefinition obj) {}
	void exit(InterfaceTypeDefinition obj) {}

	void accept(InterfaceTypeDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(UnionTypeDefinition obj) {}
	void exit(UnionTypeDefinition obj) {}

	void accept(UnionTypeDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(UnionMembers obj) {}
	void exit(UnionMembers obj) {}

	void accept(UnionMembers obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(EnumTypeDefinition obj) {}
	void exit(EnumTypeDefinition obj) {}

	void accept(EnumTypeDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(EnumValueDefinitions obj) {}
	void exit(EnumValueDefinitions obj) {}

	void accept(EnumValueDefinitions obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(EnumValueDefinition obj) {}
	void exit(EnumValueDefinition obj) {}

	void accept(EnumValueDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionEnum.ED:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case EnumValueDefinitionEnum.E:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(InputTypeDefinition obj) {}
	void exit(InputTypeDefinition obj) {}

	void accept(InputTypeDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(TypeExtensionDefinition obj) {}
	void exit(TypeExtensionDefinition obj) {}

	void accept(TypeExtensionDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeExtensionDefinitionEnum.O:
				obj.otd.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(DirectiveDefinition obj) {}
	void exit(DirectiveDefinition obj) {}

	void accept(DirectiveDefinition obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(DirectiveLocations obj) {}
	void exit(DirectiveLocations obj) {}

	void accept(DirectiveLocations obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(InputObjectTypeDefinition obj) {}
	void exit(InputObjectTypeDefinition obj) {}

	void accept(InputObjectTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputObjectTypeDefinitionEnum.NDI:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case InputObjectTypeDefinitionEnum.NI:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Description obj) {}
	void exit(Description obj) {}

	void accept(Description obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DescriptionEnum.S:
				obj.tok.visit(this);
				break;
		}
		exit(obj);
	}
}

class ConstVisitor {
@safe :


	void enter(const(Document) obj) {}
	void exit(const(Document) obj) {}

	void accept(const(Document) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DocumentEnum.Defi:
				obj.defs.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Definitions) obj) {}
	void exit(const(Definitions) obj) {}

	void accept(const(Definitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefinitionsEnum.Def:
				obj.def.visit(this);
				break;
			case DefinitionsEnum.Defs:
				obj.def.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Definition) obj) {}
	void exit(const(Definition) obj) {}

	void accept(const(Definition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(OperationDefinition) obj) {}
	void exit(const(OperationDefinition) obj) {}

	void accept(const(OperationDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_VD:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_V:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_D:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N:
				obj.ot.visit(this);
				obj.name.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_VD:
				obj.ot.visit(this);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_V:
				obj.ot.visit(this);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_D:
				obj.ot.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT:
				obj.ot.visit(this);
				obj.ss.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(SelectionSet) obj) {}
	void exit(const(SelectionSet) obj) {}

	void accept(const(SelectionSet) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionSetEnum.SS:
				obj.sel.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(OperationType) obj) {}
	void exit(const(OperationType) obj) {}

	void accept(const(OperationType) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(Selections) obj) {}
	void exit(const(Selections) obj) {}

	void accept(const(Selections) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(Selection) obj) {}
	void exit(const(Selection) obj) {}

	void accept(const(Selection) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(FragmentSpread) obj) {}
	void exit(const(FragmentSpread) obj) {}

	void accept(const(FragmentSpread) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FragmentSpreadEnum.FD:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case FragmentSpreadEnum.F:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(InlineFragment) obj) {}
	void exit(const(InlineFragment) obj) {}

	void accept(const(InlineFragment) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(Field) obj) {}
	void exit(const(Field) obj) {}

	void accept(const(Field) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(FieldName) obj) {}
	void exit(const(FieldName) obj) {}

	void accept(const(FieldName) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldNameEnum.A:
				obj.name.visit(this);
				obj.aka.visit(this);
				break;
			case FieldNameEnum.N:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Arguments) obj) {}
	void exit(const(Arguments) obj) {}

	void accept(const(Arguments) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsEnum.List:
				obj.arg.visit(this);
				break;
			case ArgumentsEnum.Empty:
				break;
		}
		exit(obj);
	}

	void enter(const(ArgumentList) obj) {}
	void exit(const(ArgumentList) obj) {}

	void accept(const(ArgumentList) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(Argument) obj) {}
	void exit(const(Argument) obj) {}

	void accept(const(Argument) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				obj.vv.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(FragmentDefinition) obj) {}
	void exit(const(FragmentDefinition) obj) {}

	void accept(const(FragmentDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(Directives) obj) {}
	void exit(const(Directives) obj) {}

	void accept(const(Directives) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectivesEnum.Dir:
				obj.dir.visit(this);
				break;
			case DirectivesEnum.Dirs:
				obj.dir.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Directive) obj) {}
	void exit(const(Directive) obj) {}

	void accept(const(Directive) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				obj.arg.visit(this);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(VariableDefinitions) obj) {}
	void exit(const(VariableDefinitions) obj) {}

	void accept(const(VariableDefinitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionsEnum.Empty:
				break;
			case VariableDefinitionsEnum.Vars:
				obj.vars.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(VariableDefinitionList) obj) {}
	void exit(const(VariableDefinitionList) obj) {}

	void accept(const(VariableDefinitionList) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(VariableDefinition) obj) {}
	void exit(const(VariableDefinition) obj) {}

	void accept(const(VariableDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionEnum.VarD:
				obj.var.visit(this);
				obj.type.visit(this);
				obj.dvalue.visit(this);
				break;
			case VariableDefinitionEnum.Var:
				obj.var.visit(this);
				obj.type.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Variable) obj) {}
	void exit(const(Variable) obj) {}

	void accept(const(Variable) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableEnum.Var:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(DefaultValue) obj) {}
	void exit(const(DefaultValue) obj) {}

	void accept(const(DefaultValue) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefaultValueEnum.DV:
				obj.value.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(ValueOrVariable) obj) {}
	void exit(const(ValueOrVariable) obj) {}

	void accept(const(ValueOrVariable) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				obj.val.visit(this);
				break;
			case ValueOrVariableEnum.Var:
				obj.var.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Value) obj) {}
	void exit(const(Value) obj) {}

	void accept(const(Value) obj) {
		enter(obj);
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
			case ValueEnum.E:
				obj.tok.visit(this);
				break;
			case ValueEnum.N:
				obj.tok.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Type) obj) {}
	void exit(const(Type) obj) {}

	void accept(const(Type) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(ListType) obj) {}
	void exit(const(ListType) obj) {}

	void accept(const(ListType) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ListTypeEnum.T:
				obj.type.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Values) obj) {}
	void exit(const(Values) obj) {}

	void accept(const(Values) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValuesEnum.Val:
				obj.val.visit(this);
				break;
			case ValuesEnum.Vals:
				obj.val.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Array) obj) {}
	void exit(const(Array) obj) {}

	void accept(const(Array) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArrayEnum.Empty:
				break;
			case ArrayEnum.Value:
				obj.vals.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(ObjectValues) obj) {}
	void exit(const(ObjectValues) obj) {}

	void accept(const(ObjectValues) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(ObjectType) obj) {}
	void exit(const(ObjectType) obj) {}

	void accept(const(ObjectType) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectTypeEnum.Var:
				obj.vals.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(TypeSystemDefinition) obj) {}
	void exit(const(TypeSystemDefinition) obj) {}

	void accept(const(TypeSystemDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(TypeDefinition) obj) {}
	void exit(const(TypeDefinition) obj) {}

	void accept(const(TypeDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(SchemaDefinition) obj) {}
	void exit(const(SchemaDefinition) obj) {}

	void accept(const(SchemaDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SchemaDefinitionEnum.DO:
				obj.dir.visit(this);
				obj.otds.visit(this);
				break;
			case SchemaDefinitionEnum.O:
				obj.otds.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(OperationTypeDefinitions) obj) {}
	void exit(const(OperationTypeDefinitions) obj) {}

	void accept(const(OperationTypeDefinitions) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(OperationTypeDefinition) obj) {}
	void exit(const(OperationTypeDefinition) obj) {}

	void accept(const(OperationTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionEnum.O:
				obj.ot.visit(this);
				obj.nt.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(ScalarTypeDefinition) obj) {}
	void exit(const(ScalarTypeDefinition) obj) {}

	void accept(const(ScalarTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ScalarTypeDefinitionEnum.D:
				obj.name.visit(this);
				obj.dir.visit(this);
				break;
			case ScalarTypeDefinitionEnum.S:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(ObjectTypeDefinition) obj) {}
	void exit(const(ObjectTypeDefinition) obj) {}

	void accept(const(ObjectTypeDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(FieldDefinitions) obj) {}
	void exit(const(FieldDefinitions) obj) {}

	void accept(const(FieldDefinitions) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(FieldDefinition) obj) {}
	void exit(const(FieldDefinition) obj) {}

	void accept(const(FieldDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(ImplementsInterfaces) obj) {}
	void exit(const(ImplementsInterfaces) obj) {}

	void accept(const(ImplementsInterfaces) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ImplementsInterfacesEnum.N:
				obj.nts.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(NamedTypes) obj) {}
	void exit(const(NamedTypes) obj) {}

	void accept(const(NamedTypes) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(ArgumentsDefinition) obj) {}
	void exit(const(ArgumentsDefinition) obj) {}

	void accept(const(ArgumentsDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsDefinitionEnum.A:
				break;
		}
		exit(obj);
	}

	void enter(const(InputValueDefinitions) obj) {}
	void exit(const(InputValueDefinitions) obj) {}

	void accept(const(InputValueDefinitions) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(InputValueDefinition) obj) {}
	void exit(const(InputValueDefinition) obj) {}

	void accept(const(InputValueDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(InterfaceTypeDefinition) obj) {}
	void exit(const(InterfaceTypeDefinition) obj) {}

	void accept(const(InterfaceTypeDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(UnionTypeDefinition) obj) {}
	void exit(const(UnionTypeDefinition) obj) {}

	void accept(const(UnionTypeDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(UnionMembers) obj) {}
	void exit(const(UnionMembers) obj) {}

	void accept(const(UnionMembers) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(EnumTypeDefinition) obj) {}
	void exit(const(EnumTypeDefinition) obj) {}

	void accept(const(EnumTypeDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(EnumValueDefinitions) obj) {}
	void exit(const(EnumValueDefinitions) obj) {}

	void accept(const(EnumValueDefinitions) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(EnumValueDefinition) obj) {}
	void exit(const(EnumValueDefinition) obj) {}

	void accept(const(EnumValueDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionEnum.ED:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case EnumValueDefinitionEnum.E:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(InputTypeDefinition) obj) {}
	void exit(const(InputTypeDefinition) obj) {}

	void accept(const(InputTypeDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(TypeExtensionDefinition) obj) {}
	void exit(const(TypeExtensionDefinition) obj) {}

	void accept(const(TypeExtensionDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeExtensionDefinitionEnum.O:
				obj.otd.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(DirectiveDefinition) obj) {}
	void exit(const(DirectiveDefinition) obj) {}

	void accept(const(DirectiveDefinition) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(DirectiveLocations) obj) {}
	void exit(const(DirectiveLocations) obj) {}

	void accept(const(DirectiveLocations) obj) {
		enter(obj);
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
		exit(obj);
	}

	void enter(const(InputObjectTypeDefinition) obj) {}
	void exit(const(InputObjectTypeDefinition) obj) {}

	void accept(const(InputObjectTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputObjectTypeDefinitionEnum.NDI:
				obj.name.visit(this);
				obj.dirs.visit(this);
				break;
			case InputObjectTypeDefinitionEnum.NI:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Description) obj) {}
	void exit(const(Description) obj) {}

	void accept(const(Description) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DescriptionEnum.S:
				obj.tok.visit(this);
				break;
		}
		exit(obj);
	}
}

