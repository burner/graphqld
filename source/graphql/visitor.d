module graphql.visitor;

import graphql.ast;
import graphql.parser;
import graphql.tokenmodule;

class Visitor {
@safe :

	Parser* parser;

	this(Parser* parser) {
		this.parser = parser;
	}


	void enter(ref Document obj) {}
	void exit(ref Document obj) {}

	void accept(ref Document obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DocumentEnum.Defi:
				this.accept(this.parser.definitionss[obj.defsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Definitions obj) {}
	void exit(ref Definitions obj) {}

	void accept(ref Definitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefinitionsEnum.Def:
				this.accept(this.parser.definitions[obj.defIdx]);
				break;
			case DefinitionsEnum.Defs:
				this.accept(this.parser.definitions[obj.defIdx]);
				this.accept(this.parser.definitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Definition obj) {}
	void exit(ref Definition obj) {}

	void accept(ref Definition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefinitionEnum.O:
				this.accept(this.parser.operationDefinitions[obj.opIdx]);
				break;
			case DefinitionEnum.F:
				this.accept(this.parser.fragmentDefinitions[obj.fragIdx]);
				break;
			case DefinitionEnum.T:
				this.accept(this.parser.typeSystemDefinitions[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref OperationDefinition obj) {}
	void exit(ref OperationDefinition obj) {}

	void accept(ref OperationDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N_VD:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N_V:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N_D:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_VD:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_V:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_D:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref SelectionSet obj) {}
	void exit(ref SelectionSet obj) {}

	void accept(ref SelectionSet obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionSetEnum.SS:
				this.accept(this.parser.selectionss[obj.selIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref OperationType obj) {}
	void exit(ref OperationType obj) {}

	void accept(ref OperationType obj) {
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

	void enter(ref Selections obj) {}
	void exit(ref Selections obj) {}

	void accept(ref Selections obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionsEnum.Sel:
				this.accept(this.parser.selections[obj.selIdx]);
				break;
			case SelectionsEnum.Sels:
				this.accept(this.parser.selections[obj.selIdx]);
				this.accept(this.parser.selectionss[obj.followIdx]);
				break;
			case SelectionsEnum.Selsc:
				this.accept(this.parser.selections[obj.selIdx]);
				this.accept(this.parser.selectionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Selection obj) {}
	void exit(ref Selection obj) {}

	void accept(ref Selection obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionEnum.Field:
				this.accept(this.parser.fields[obj.fieldIdx]);
				break;
			case SelectionEnum.Spread:
				this.accept(this.parser.fragmentSpreads[obj.fragIdx]);
				break;
			case SelectionEnum.IFrag:
				this.accept(this.parser.inlineFragments[obj.ifragIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref FragmentSpread obj) {}
	void exit(ref FragmentSpread obj) {}

	void accept(ref FragmentSpread obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FragmentSpreadEnum.FD:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case FragmentSpreadEnum.F:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref InlineFragment obj) {}
	void exit(ref InlineFragment obj) {}

	void accept(ref InlineFragment obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InlineFragmentEnum.TDS:
				obj.tc.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case InlineFragmentEnum.TS:
				obj.tc.visit(this);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case InlineFragmentEnum.DS:
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case InlineFragmentEnum.S:
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Field obj) {}
	void exit(ref Field obj) {}

	void accept(ref Field obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldEnum.FADS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FAS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FAD:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case FieldEnum.FDS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FD:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case FieldEnum.FA:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				break;
			case FieldEnum.F:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref FieldName obj) {}
	void exit(ref FieldName obj) {}

	void accept(ref FieldName obj) {
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

	void enter(ref Arguments obj) {}
	void exit(ref Arguments obj) {}

	void accept(ref Arguments obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsEnum.List:
				this.accept(this.parser.argumentLists[obj.argIdx]);
				break;
			case ArgumentsEnum.Empty:
				break;
		}
		exit(obj);
	}

	void enter(ref ArgumentList obj) {}
	void exit(ref ArgumentList obj) {}

	void accept(ref ArgumentList obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentListEnum.A:
				this.accept(this.parser.arguments[obj.argIdx]);
				break;
			case ArgumentListEnum.ACS:
				this.accept(this.parser.arguments[obj.argIdx]);
				this.accept(this.parser.argumentLists[obj.followIdx]);
				break;
			case ArgumentListEnum.AS:
				this.accept(this.parser.arguments[obj.argIdx]);
				this.accept(this.parser.argumentLists[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Argument obj) {}
	void exit(ref Argument obj) {}

	void accept(ref Argument obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.vvIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref FragmentDefinition obj) {}
	void exit(ref FragmentDefinition obj) {}

	void accept(ref FragmentDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FragmentDefinitionEnum.FTDS:
				obj.name.visit(this);
				obj.tc.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FragmentDefinitionEnum.FTS:
				obj.name.visit(this);
				obj.tc.visit(this);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Directives obj) {}
	void exit(ref Directives obj) {}

	void accept(ref Directives obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectivesEnum.Dir:
				this.accept(this.parser.directives[obj.dirIdx]);
				break;
			case DirectivesEnum.Dirs:
				this.accept(this.parser.directives[obj.dirIdx]);
				this.accept(this.parser.directivess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Directive obj) {}
	void exit(ref Directive obj) {}

	void accept(ref Directive obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				this.accept(this.parser.argumentss[obj.argIdx]);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref VariableDefinitions obj) {}
	void exit(ref VariableDefinitions obj) {}

	void accept(ref VariableDefinitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionsEnum.Empty:
				break;
			case VariableDefinitionsEnum.Vars:
				this.accept(this.parser.variableDefinitionLists[obj.varsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref VariableDefinitionList obj) {}
	void exit(ref VariableDefinitionList obj) {}

	void accept(ref VariableDefinitionList obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionListEnum.V:
				this.accept(this.parser.variableDefinitions[obj.varIdx]);
				break;
			case VariableDefinitionListEnum.VCF:
				this.accept(this.parser.variableDefinitions[obj.varIdx]);
				this.accept(this.parser.variableDefinitionLists[obj.followIdx]);
				break;
			case VariableDefinitionListEnum.VF:
				this.accept(this.parser.variableDefinitions[obj.varIdx]);
				this.accept(this.parser.variableDefinitionLists[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref VariableDefinition obj) {}
	void exit(ref VariableDefinition obj) {}

	void accept(ref VariableDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionEnum.VarD:
				this.accept(this.parser.variables[obj.varIdx]);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dvalueIdx]);
				break;
			case VariableDefinitionEnum.Var:
				this.accept(this.parser.variables[obj.varIdx]);
				this.accept(this.parser.types[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Variable obj) {}
	void exit(ref Variable obj) {}

	void accept(ref Variable obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableEnum.Var:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref DefaultValue obj) {}
	void exit(ref DefaultValue obj) {}

	void accept(ref DefaultValue obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefaultValueEnum.DV:
				this.accept(this.parser.values[obj.valueIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref ValueOrVariable obj) {}
	void exit(ref ValueOrVariable obj) {}

	void accept(ref ValueOrVariable obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				this.accept(this.parser.values[obj.valIdx]);
				break;
			case ValueOrVariableEnum.Var:
				this.accept(this.parser.variables[obj.varIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Value obj) {}
	void exit(ref Value obj) {}

	void accept(ref Value obj) {
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
				this.accept(this.parser.arrays[obj.arrIdx]);
				break;
			case ValueEnum.O:
				this.accept(this.parser.objectTypes[obj.objIdx]);
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

	void enter(ref Type obj) {}
	void exit(ref Type obj) {}

	void accept(ref Type obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeEnum.TN:
				obj.tname.visit(this);
				break;
			case TypeEnum.LN:
				this.accept(this.parser.listTypes[obj.listIdx]);
				break;
			case TypeEnum.T:
				obj.tname.visit(this);
				break;
			case TypeEnum.L:
				this.accept(this.parser.listTypes[obj.listIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref ListType obj) {}
	void exit(ref ListType obj) {}

	void accept(ref ListType obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ListTypeEnum.T:
				this.accept(this.parser.types[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Values obj) {}
	void exit(ref Values obj) {}

	void accept(ref Values obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValuesEnum.Val:
				this.accept(this.parser.values[obj.valIdx]);
				break;
			case ValuesEnum.Vals:
				this.accept(this.parser.values[obj.valIdx]);
				this.accept(this.parser.valuess[obj.followIdx]);
				break;
			case ValuesEnum.ValsNoComma:
				this.accept(this.parser.values[obj.valIdx]);
				this.accept(this.parser.valuess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref Array obj) {}
	void exit(ref Array obj) {}

	void accept(ref Array obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArrayEnum.Empty:
				break;
			case ArrayEnum.Value:
				this.accept(this.parser.valuess[obj.valsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref ObjectValues obj) {}
	void exit(ref ObjectValues obj) {}

	void accept(ref ObjectValues obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectValuesEnum.V:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.valIdx]);
				break;
			case ObjectValuesEnum.Vsc:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.valIdx]);
				this.accept(this.parser.objectValuess[obj.followIdx]);
				break;
			case ObjectValuesEnum.Vs:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.valIdx]);
				this.accept(this.parser.objectValuess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref ObjectType obj) {}
	void exit(ref ObjectType obj) {}

	void accept(ref ObjectType obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectTypeEnum.Var:
				this.accept(this.parser.objectValuess[obj.valsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref TypeSystemDefinition obj) {}
	void exit(ref TypeSystemDefinition obj) {}

	void accept(ref TypeSystemDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeSystemDefinitionEnum.S:
				this.accept(this.parser.schemaDefinitions[obj.schIdx]);
				break;
			case TypeSystemDefinitionEnum.T:
				this.accept(this.parser.typeDefinitions[obj.tdIdx]);
				break;
			case TypeSystemDefinitionEnum.TE:
				this.accept(this.parser.typeExtensionDefinitions[obj.tedIdx]);
				break;
			case TypeSystemDefinitionEnum.D:
				this.accept(this.parser.directiveDefinitions[obj.ddIdx]);
				break;
			case TypeSystemDefinitionEnum.DS:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.schemaDefinitions[obj.schIdx]);
				break;
			case TypeSystemDefinitionEnum.DT:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.typeDefinitions[obj.tdIdx]);
				break;
			case TypeSystemDefinitionEnum.DTE:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.typeExtensionDefinitions[obj.tedIdx]);
				break;
			case TypeSystemDefinitionEnum.DD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.directiveDefinitions[obj.ddIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref TypeDefinition obj) {}
	void exit(ref TypeDefinition obj) {}

	void accept(ref TypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeDefinitionEnum.S:
				this.accept(this.parser.scalarTypeDefinitions[obj.stdIdx]);
				break;
			case TypeDefinitionEnum.O:
				this.accept(this.parser.objectTypeDefinitions[obj.otdIdx]);
				break;
			case TypeDefinitionEnum.I:
				this.accept(this.parser.interfaceTypeDefinitions[obj.itdIdx]);
				break;
			case TypeDefinitionEnum.U:
				this.accept(this.parser.unionTypeDefinitions[obj.utdIdx]);
				break;
			case TypeDefinitionEnum.E:
				this.accept(this.parser.enumTypeDefinitions[obj.etdIdx]);
				break;
			case TypeDefinitionEnum.IO:
				this.accept(this.parser.inputObjectTypeDefinitions[obj.iodIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref SchemaDefinition obj) {}
	void exit(ref SchemaDefinition obj) {}

	void accept(ref SchemaDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SchemaDefinitionEnum.DO:
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.operationTypeDefinitionss[obj.otdsIdx]);
				break;
			case SchemaDefinitionEnum.O:
				this.accept(this.parser.operationTypeDefinitionss[obj.otdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref OperationTypeDefinitions obj) {}
	void exit(ref OperationTypeDefinitions obj) {}

	void accept(ref OperationTypeDefinitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionsEnum.O:
				this.accept(this.parser.operationTypeDefinitions[obj.otdIdx]);
				break;
			case OperationTypeDefinitionsEnum.OCS:
				this.accept(this.parser.operationTypeDefinitions[obj.otdIdx]);
				this.accept(this.parser.operationTypeDefinitionss[obj.followIdx]);
				break;
			case OperationTypeDefinitionsEnum.OS:
				this.accept(this.parser.operationTypeDefinitions[obj.otdIdx]);
				this.accept(this.parser.operationTypeDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref OperationTypeDefinition obj) {}
	void exit(ref OperationTypeDefinition obj) {}

	void accept(ref OperationTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionEnum.O:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.nt.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref ScalarTypeDefinition obj) {}
	void exit(ref ScalarTypeDefinition obj) {}

	void accept(ref ScalarTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ScalarTypeDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case ScalarTypeDefinitionEnum.S:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref ObjectTypeDefinition obj) {}
	void exit(ref ObjectTypeDefinition obj) {}

	void accept(ref ObjectTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectTypeDefinitionEnum.ID:
				obj.name.visit(this);
				this.accept(this.parser.implementsInterfacess[obj.iiIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case ObjectTypeDefinitionEnum.I:
				obj.name.visit(this);
				this.accept(this.parser.implementsInterfacess[obj.iiIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case ObjectTypeDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case ObjectTypeDefinitionEnum.F:
				obj.name.visit(this);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref FieldDefinitions obj) {}
	void exit(ref FieldDefinitions obj) {}

	void accept(ref FieldDefinitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldDefinitionsEnum.F:
				this.accept(this.parser.fieldDefinitions[obj.fdIdx]);
				break;
			case FieldDefinitionsEnum.FC:
				this.accept(this.parser.fieldDefinitions[obj.fdIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.followIdx]);
				break;
			case FieldDefinitionsEnum.FNC:
				this.accept(this.parser.fieldDefinitions[obj.fdIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref FieldDefinition obj) {}
	void exit(ref FieldDefinition obj) {}

	void accept(ref FieldDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldDefinitionEnum.AD:
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.A:
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				break;
			case FieldDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.T:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				break;
			case FieldDefinitionEnum.DAD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.DA:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				break;
			case FieldDefinitionEnum.DD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.DT:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref ImplementsInterfaces obj) {}
	void exit(ref ImplementsInterfaces obj) {}

	void accept(ref ImplementsInterfaces obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ImplementsInterfacesEnum.N:
				this.accept(this.parser.namedTypess[obj.ntsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref NamedTypes obj) {}
	void exit(ref NamedTypes obj) {}

	void accept(ref NamedTypes obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case NamedTypesEnum.N:
				obj.name.visit(this);
				break;
			case NamedTypesEnum.NCS:
				obj.name.visit(this);
				this.accept(this.parser.namedTypess[obj.followIdx]);
				break;
			case NamedTypesEnum.NS:
				obj.name.visit(this);
				this.accept(this.parser.namedTypess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref ArgumentsDefinition obj) {}
	void exit(ref ArgumentsDefinition obj) {}

	void accept(ref ArgumentsDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsDefinitionEnum.A:
				break;
			case ArgumentsDefinitionEnum.NA:
				break;
		}
		exit(obj);
	}

	void enter(ref InputValueDefinitions obj) {}
	void exit(ref InputValueDefinitions obj) {}

	void accept(ref InputValueDefinitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputValueDefinitionsEnum.I:
				this.accept(this.parser.inputValueDefinitions[obj.ivIdx]);
				break;
			case InputValueDefinitionsEnum.ICF:
				this.accept(this.parser.inputValueDefinitions[obj.ivIdx]);
				this.accept(this.parser.inputValueDefinitionss[obj.followIdx]);
				break;
			case InputValueDefinitionsEnum.IF:
				this.accept(this.parser.inputValueDefinitions[obj.ivIdx]);
				this.accept(this.parser.inputValueDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref InputValueDefinition obj) {}
	void exit(ref InputValueDefinition obj) {}

	void accept(ref InputValueDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputValueDefinitionEnum.TVD:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.TD:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.TV:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				break;
			case InputValueDefinitionEnum.T:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				break;
			case InputValueDefinitionEnum.DTVD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.DTD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.DTV:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				break;
			case InputValueDefinitionEnum.DT:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref InterfaceTypeDefinition obj) {}
	void exit(ref InterfaceTypeDefinition obj) {}

	void accept(ref InterfaceTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InterfaceTypeDefinitionEnum.NDF:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case InterfaceTypeDefinitionEnum.NF:
				obj.name.visit(this);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref UnionTypeDefinition obj) {}
	void exit(ref UnionTypeDefinition obj) {}

	void accept(ref UnionTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case UnionTypeDefinitionEnum.NDU:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.unionMemberss[obj.umIdx]);
				break;
			case UnionTypeDefinitionEnum.NU:
				obj.name.visit(this);
				this.accept(this.parser.unionMemberss[obj.umIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref UnionMembers obj) {}
	void exit(ref UnionMembers obj) {}

	void accept(ref UnionMembers obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case UnionMembersEnum.S:
				obj.name.visit(this);
				break;
			case UnionMembersEnum.SPF:
				obj.name.visit(this);
				this.accept(this.parser.unionMemberss[obj.followIdx]);
				break;
			case UnionMembersEnum.SF:
				obj.name.visit(this);
				this.accept(this.parser.unionMemberss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref EnumTypeDefinition obj) {}
	void exit(ref EnumTypeDefinition obj) {}

	void accept(ref EnumTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.enumValueDefinitionss[obj.evdsIdx]);
				break;
			case EnumTypeDefinitionEnum.NE:
				obj.name.visit(this);
				this.accept(this.parser.enumValueDefinitionss[obj.evdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref EnumValueDefinitions obj) {}
	void exit(ref EnumValueDefinitions obj) {}

	void accept(ref EnumValueDefinitions obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionsEnum.D:
				this.accept(this.parser.enumValueDefinitions[obj.evdIdx]);
				break;
			case EnumValueDefinitionsEnum.DCE:
				this.accept(this.parser.enumValueDefinitions[obj.evdIdx]);
				this.accept(this.parser.enumValueDefinitionss[obj.followIdx]);
				break;
			case EnumValueDefinitionsEnum.DE:
				this.accept(this.parser.enumValueDefinitions[obj.evdIdx]);
				this.accept(this.parser.enumValueDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref EnumValueDefinition obj) {}
	void exit(ref EnumValueDefinition obj) {}

	void accept(ref EnumValueDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionEnum.ED:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case EnumValueDefinitionEnum.E:
				obj.name.visit(this);
				break;
			case EnumValueDefinitionEnum.DED:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case EnumValueDefinitionEnum.DE:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref InputTypeDefinition obj) {}
	void exit(ref InputTypeDefinition obj) {}

	void accept(ref InputTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.inputValueDefinitionss[obj.ivdsIdx]);
				break;
			case InputTypeDefinitionEnum.NE:
				obj.name.visit(this);
				this.accept(this.parser.inputValueDefinitionss[obj.ivdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref TypeExtensionDefinition obj) {}
	void exit(ref TypeExtensionDefinition obj) {}

	void accept(ref TypeExtensionDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeExtensionDefinitionEnum.O:
				this.accept(this.parser.objectTypeDefinitions[obj.otdIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref DirectiveDefinition obj) {}
	void exit(ref DirectiveDefinition obj) {}

	void accept(ref DirectiveDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveDefinitionEnum.AD:
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.adIdx]);
				this.accept(this.parser.directiveLocationss[obj.dlIdx]);
				break;
			case DirectiveDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.directiveLocationss[obj.dlIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref DirectiveLocations obj) {}
	void exit(ref DirectiveLocations obj) {}

	void accept(ref DirectiveLocations obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveLocationsEnum.N:
				obj.name.visit(this);
				break;
			case DirectiveLocationsEnum.NPF:
				obj.name.visit(this);
				this.accept(this.parser.directiveLocationss[obj.followIdx]);
				break;
			case DirectiveLocationsEnum.NF:
				obj.name.visit(this);
				this.accept(this.parser.directiveLocationss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref InputObjectTypeDefinition obj) {}
	void exit(ref InputObjectTypeDefinition obj) {}

	void accept(ref InputObjectTypeDefinition obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputObjectTypeDefinitionEnum.NDI:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputObjectTypeDefinitionEnum.NI:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref Description obj) {}
	void exit(ref Description obj) {}

	void accept(ref Description obj) {
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

	Parser* parser;

	this(Parser* parser) {
		this.parser = parser;
	}


	void enter(ref const(Document) obj) {}
	void exit(ref const(Document) obj) {}

	void accept(ref const(Document) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DocumentEnum.Defi:
				this.accept(this.parser.definitionss[obj.defsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Definitions) obj) {}
	void exit(ref const(Definitions) obj) {}

	void accept(ref const(Definitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefinitionsEnum.Def:
				this.accept(this.parser.definitions[obj.defIdx]);
				break;
			case DefinitionsEnum.Defs:
				this.accept(this.parser.definitions[obj.defIdx]);
				this.accept(this.parser.definitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Definition) obj) {}
	void exit(ref const(Definition) obj) {}

	void accept(ref const(Definition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefinitionEnum.O:
				this.accept(this.parser.operationDefinitions[obj.opIdx]);
				break;
			case DefinitionEnum.F:
				this.accept(this.parser.fragmentDefinitions[obj.fragIdx]);
				break;
			case DefinitionEnum.T:
				this.accept(this.parser.typeSystemDefinitions[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(OperationDefinition) obj) {}
	void exit(ref const(OperationDefinition) obj) {}

	void accept(ref const(OperationDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N_VD:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N_V:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N_D:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_N:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.name.visit(this);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_VD:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_V:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.variableDefinitionss[obj.vdIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT_D:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.directivess[obj.dIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case OperationDefinitionEnum.OT:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(SelectionSet) obj) {}
	void exit(ref const(SelectionSet) obj) {}

	void accept(ref const(SelectionSet) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionSetEnum.SS:
				this.accept(this.parser.selectionss[obj.selIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(OperationType) obj) {}
	void exit(ref const(OperationType) obj) {}

	void accept(ref const(OperationType) obj) {
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

	void enter(ref const(Selections) obj) {}
	void exit(ref const(Selections) obj) {}

	void accept(ref const(Selections) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionsEnum.Sel:
				this.accept(this.parser.selections[obj.selIdx]);
				break;
			case SelectionsEnum.Sels:
				this.accept(this.parser.selections[obj.selIdx]);
				this.accept(this.parser.selectionss[obj.followIdx]);
				break;
			case SelectionsEnum.Selsc:
				this.accept(this.parser.selections[obj.selIdx]);
				this.accept(this.parser.selectionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Selection) obj) {}
	void exit(ref const(Selection) obj) {}

	void accept(ref const(Selection) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SelectionEnum.Field:
				this.accept(this.parser.fields[obj.fieldIdx]);
				break;
			case SelectionEnum.Spread:
				this.accept(this.parser.fragmentSpreads[obj.fragIdx]);
				break;
			case SelectionEnum.IFrag:
				this.accept(this.parser.inlineFragments[obj.ifragIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(FragmentSpread) obj) {}
	void exit(ref const(FragmentSpread) obj) {}

	void accept(ref const(FragmentSpread) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FragmentSpreadEnum.FD:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case FragmentSpreadEnum.F:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(InlineFragment) obj) {}
	void exit(ref const(InlineFragment) obj) {}

	void accept(ref const(InlineFragment) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InlineFragmentEnum.TDS:
				obj.tc.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case InlineFragmentEnum.TS:
				obj.tc.visit(this);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case InlineFragmentEnum.DS:
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case InlineFragmentEnum.S:
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Field) obj) {}
	void exit(ref const(Field) obj) {}

	void accept(ref const(Field) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldEnum.FADS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FAS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FAD:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case FieldEnum.FDS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FS:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FieldEnum.FD:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case FieldEnum.FA:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				this.accept(this.parser.argumentss[obj.argsIdx]);
				break;
			case FieldEnum.F:
				this.accept(this.parser.fieldNames[obj.nameIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(FieldName) obj) {}
	void exit(ref const(FieldName) obj) {}

	void accept(ref const(FieldName) obj) {
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

	void enter(ref const(Arguments) obj) {}
	void exit(ref const(Arguments) obj) {}

	void accept(ref const(Arguments) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsEnum.List:
				this.accept(this.parser.argumentLists[obj.argIdx]);
				break;
			case ArgumentsEnum.Empty:
				break;
		}
		exit(obj);
	}

	void enter(ref const(ArgumentList) obj) {}
	void exit(ref const(ArgumentList) obj) {}

	void accept(ref const(ArgumentList) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentListEnum.A:
				this.accept(this.parser.arguments[obj.argIdx]);
				break;
			case ArgumentListEnum.ACS:
				this.accept(this.parser.arguments[obj.argIdx]);
				this.accept(this.parser.argumentLists[obj.followIdx]);
				break;
			case ArgumentListEnum.AS:
				this.accept(this.parser.arguments[obj.argIdx]);
				this.accept(this.parser.argumentLists[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Argument) obj) {}
	void exit(ref const(Argument) obj) {}

	void accept(ref const(Argument) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentEnum.Name:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.vvIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(FragmentDefinition) obj) {}
	void exit(ref const(FragmentDefinition) obj) {}

	void accept(ref const(FragmentDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FragmentDefinitionEnum.FTDS:
				obj.name.visit(this);
				obj.tc.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
			case FragmentDefinitionEnum.FTS:
				obj.name.visit(this);
				obj.tc.visit(this);
				this.accept(this.parser.selectionSets[obj.ssIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Directives) obj) {}
	void exit(ref const(Directives) obj) {}

	void accept(ref const(Directives) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectivesEnum.Dir:
				this.accept(this.parser.directives[obj.dirIdx]);
				break;
			case DirectivesEnum.Dirs:
				this.accept(this.parser.directives[obj.dirIdx]);
				this.accept(this.parser.directivess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Directive) obj) {}
	void exit(ref const(Directive) obj) {}

	void accept(ref const(Directive) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveEnum.NArg:
				obj.name.visit(this);
				this.accept(this.parser.argumentss[obj.argIdx]);
				break;
			case DirectiveEnum.N:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(VariableDefinitions) obj) {}
	void exit(ref const(VariableDefinitions) obj) {}

	void accept(ref const(VariableDefinitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionsEnum.Empty:
				break;
			case VariableDefinitionsEnum.Vars:
				this.accept(this.parser.variableDefinitionLists[obj.varsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(VariableDefinitionList) obj) {}
	void exit(ref const(VariableDefinitionList) obj) {}

	void accept(ref const(VariableDefinitionList) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionListEnum.V:
				this.accept(this.parser.variableDefinitions[obj.varIdx]);
				break;
			case VariableDefinitionListEnum.VCF:
				this.accept(this.parser.variableDefinitions[obj.varIdx]);
				this.accept(this.parser.variableDefinitionLists[obj.followIdx]);
				break;
			case VariableDefinitionListEnum.VF:
				this.accept(this.parser.variableDefinitions[obj.varIdx]);
				this.accept(this.parser.variableDefinitionLists[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(VariableDefinition) obj) {}
	void exit(ref const(VariableDefinition) obj) {}

	void accept(ref const(VariableDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableDefinitionEnum.VarD:
				this.accept(this.parser.variables[obj.varIdx]);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dvalueIdx]);
				break;
			case VariableDefinitionEnum.Var:
				this.accept(this.parser.variables[obj.varIdx]);
				this.accept(this.parser.types[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Variable) obj) {}
	void exit(ref const(Variable) obj) {}

	void accept(ref const(Variable) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case VariableEnum.Var:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(DefaultValue) obj) {}
	void exit(ref const(DefaultValue) obj) {}

	void accept(ref const(DefaultValue) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DefaultValueEnum.DV:
				this.accept(this.parser.values[obj.valueIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ValueOrVariable) obj) {}
	void exit(ref const(ValueOrVariable) obj) {}

	void accept(ref const(ValueOrVariable) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				this.accept(this.parser.values[obj.valIdx]);
				break;
			case ValueOrVariableEnum.Var:
				this.accept(this.parser.variables[obj.varIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Value) obj) {}
	void exit(ref const(Value) obj) {}

	void accept(ref const(Value) obj) {
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
				this.accept(this.parser.arrays[obj.arrIdx]);
				break;
			case ValueEnum.O:
				this.accept(this.parser.objectTypes[obj.objIdx]);
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

	void enter(ref const(Type) obj) {}
	void exit(ref const(Type) obj) {}

	void accept(ref const(Type) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeEnum.TN:
				obj.tname.visit(this);
				break;
			case TypeEnum.LN:
				this.accept(this.parser.listTypes[obj.listIdx]);
				break;
			case TypeEnum.T:
				obj.tname.visit(this);
				break;
			case TypeEnum.L:
				this.accept(this.parser.listTypes[obj.listIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ListType) obj) {}
	void exit(ref const(ListType) obj) {}

	void accept(ref const(ListType) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ListTypeEnum.T:
				this.accept(this.parser.types[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Values) obj) {}
	void exit(ref const(Values) obj) {}

	void accept(ref const(Values) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValuesEnum.Val:
				this.accept(this.parser.values[obj.valIdx]);
				break;
			case ValuesEnum.Vals:
				this.accept(this.parser.values[obj.valIdx]);
				this.accept(this.parser.valuess[obj.followIdx]);
				break;
			case ValuesEnum.ValsNoComma:
				this.accept(this.parser.values[obj.valIdx]);
				this.accept(this.parser.valuess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Array) obj) {}
	void exit(ref const(Array) obj) {}

	void accept(ref const(Array) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArrayEnum.Empty:
				break;
			case ArrayEnum.Value:
				this.accept(this.parser.valuess[obj.valsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ObjectValues) obj) {}
	void exit(ref const(ObjectValues) obj) {}

	void accept(ref const(ObjectValues) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectValuesEnum.V:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.valIdx]);
				break;
			case ObjectValuesEnum.Vsc:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.valIdx]);
				this.accept(this.parser.objectValuess[obj.followIdx]);
				break;
			case ObjectValuesEnum.Vs:
				obj.name.visit(this);
				this.accept(this.parser.valueOrVariables[obj.valIdx]);
				this.accept(this.parser.objectValuess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ObjectType) obj) {}
	void exit(ref const(ObjectType) obj) {}

	void accept(ref const(ObjectType) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectTypeEnum.Var:
				this.accept(this.parser.objectValuess[obj.valsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(TypeSystemDefinition) obj) {}
	void exit(ref const(TypeSystemDefinition) obj) {}

	void accept(ref const(TypeSystemDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeSystemDefinitionEnum.S:
				this.accept(this.parser.schemaDefinitions[obj.schIdx]);
				break;
			case TypeSystemDefinitionEnum.T:
				this.accept(this.parser.typeDefinitions[obj.tdIdx]);
				break;
			case TypeSystemDefinitionEnum.TE:
				this.accept(this.parser.typeExtensionDefinitions[obj.tedIdx]);
				break;
			case TypeSystemDefinitionEnum.D:
				this.accept(this.parser.directiveDefinitions[obj.ddIdx]);
				break;
			case TypeSystemDefinitionEnum.DS:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.schemaDefinitions[obj.schIdx]);
				break;
			case TypeSystemDefinitionEnum.DT:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.typeDefinitions[obj.tdIdx]);
				break;
			case TypeSystemDefinitionEnum.DTE:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.typeExtensionDefinitions[obj.tedIdx]);
				break;
			case TypeSystemDefinitionEnum.DD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				this.accept(this.parser.directiveDefinitions[obj.ddIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(TypeDefinition) obj) {}
	void exit(ref const(TypeDefinition) obj) {}

	void accept(ref const(TypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeDefinitionEnum.S:
				this.accept(this.parser.scalarTypeDefinitions[obj.stdIdx]);
				break;
			case TypeDefinitionEnum.O:
				this.accept(this.parser.objectTypeDefinitions[obj.otdIdx]);
				break;
			case TypeDefinitionEnum.I:
				this.accept(this.parser.interfaceTypeDefinitions[obj.itdIdx]);
				break;
			case TypeDefinitionEnum.U:
				this.accept(this.parser.unionTypeDefinitions[obj.utdIdx]);
				break;
			case TypeDefinitionEnum.E:
				this.accept(this.parser.enumTypeDefinitions[obj.etdIdx]);
				break;
			case TypeDefinitionEnum.IO:
				this.accept(this.parser.inputObjectTypeDefinitions[obj.iodIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(SchemaDefinition) obj) {}
	void exit(ref const(SchemaDefinition) obj) {}

	void accept(ref const(SchemaDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case SchemaDefinitionEnum.DO:
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.operationTypeDefinitionss[obj.otdsIdx]);
				break;
			case SchemaDefinitionEnum.O:
				this.accept(this.parser.operationTypeDefinitionss[obj.otdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(OperationTypeDefinitions) obj) {}
	void exit(ref const(OperationTypeDefinitions) obj) {}

	void accept(ref const(OperationTypeDefinitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionsEnum.O:
				this.accept(this.parser.operationTypeDefinitions[obj.otdIdx]);
				break;
			case OperationTypeDefinitionsEnum.OCS:
				this.accept(this.parser.operationTypeDefinitions[obj.otdIdx]);
				this.accept(this.parser.operationTypeDefinitionss[obj.followIdx]);
				break;
			case OperationTypeDefinitionsEnum.OS:
				this.accept(this.parser.operationTypeDefinitions[obj.otdIdx]);
				this.accept(this.parser.operationTypeDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(OperationTypeDefinition) obj) {}
	void exit(ref const(OperationTypeDefinition) obj) {}

	void accept(ref const(OperationTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OperationTypeDefinitionEnum.O:
				this.accept(this.parser.operationTypes[obj.otIdx]);
				obj.nt.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ScalarTypeDefinition) obj) {}
	void exit(ref const(ScalarTypeDefinition) obj) {}

	void accept(ref const(ScalarTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ScalarTypeDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case ScalarTypeDefinitionEnum.S:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ObjectTypeDefinition) obj) {}
	void exit(ref const(ObjectTypeDefinition) obj) {}

	void accept(ref const(ObjectTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectTypeDefinitionEnum.ID:
				obj.name.visit(this);
				this.accept(this.parser.implementsInterfacess[obj.iiIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case ObjectTypeDefinitionEnum.I:
				obj.name.visit(this);
				this.accept(this.parser.implementsInterfacess[obj.iiIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case ObjectTypeDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case ObjectTypeDefinitionEnum.F:
				obj.name.visit(this);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(FieldDefinitions) obj) {}
	void exit(ref const(FieldDefinitions) obj) {}

	void accept(ref const(FieldDefinitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldDefinitionsEnum.F:
				this.accept(this.parser.fieldDefinitions[obj.fdIdx]);
				break;
			case FieldDefinitionsEnum.FC:
				this.accept(this.parser.fieldDefinitions[obj.fdIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.followIdx]);
				break;
			case FieldDefinitionsEnum.FNC:
				this.accept(this.parser.fieldDefinitions[obj.fdIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(FieldDefinition) obj) {}
	void exit(ref const(FieldDefinition) obj) {}

	void accept(ref const(FieldDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case FieldDefinitionEnum.AD:
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.A:
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				break;
			case FieldDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.T:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				break;
			case FieldDefinitionEnum.DAD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.DA:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.argIdx]);
				this.accept(this.parser.types[obj.typIdx]);
				break;
			case FieldDefinitionEnum.DD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				this.accept(this.parser.directivess[obj.dirIdx]);
				break;
			case FieldDefinitionEnum.DT:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ImplementsInterfaces) obj) {}
	void exit(ref const(ImplementsInterfaces) obj) {}

	void accept(ref const(ImplementsInterfaces) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ImplementsInterfacesEnum.N:
				this.accept(this.parser.namedTypess[obj.ntsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(NamedTypes) obj) {}
	void exit(ref const(NamedTypes) obj) {}

	void accept(ref const(NamedTypes) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case NamedTypesEnum.N:
				obj.name.visit(this);
				break;
			case NamedTypesEnum.NCS:
				obj.name.visit(this);
				this.accept(this.parser.namedTypess[obj.followIdx]);
				break;
			case NamedTypesEnum.NS:
				obj.name.visit(this);
				this.accept(this.parser.namedTypess[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(ArgumentsDefinition) obj) {}
	void exit(ref const(ArgumentsDefinition) obj) {}

	void accept(ref const(ArgumentsDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ArgumentsDefinitionEnum.A:
				break;
			case ArgumentsDefinitionEnum.NA:
				break;
		}
		exit(obj);
	}

	void enter(ref const(InputValueDefinitions) obj) {}
	void exit(ref const(InputValueDefinitions) obj) {}

	void accept(ref const(InputValueDefinitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputValueDefinitionsEnum.I:
				this.accept(this.parser.inputValueDefinitions[obj.ivIdx]);
				break;
			case InputValueDefinitionsEnum.ICF:
				this.accept(this.parser.inputValueDefinitions[obj.ivIdx]);
				this.accept(this.parser.inputValueDefinitionss[obj.followIdx]);
				break;
			case InputValueDefinitionsEnum.IF:
				this.accept(this.parser.inputValueDefinitions[obj.ivIdx]);
				this.accept(this.parser.inputValueDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(InputValueDefinition) obj) {}
	void exit(ref const(InputValueDefinition) obj) {}

	void accept(ref const(InputValueDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputValueDefinitionEnum.TVD:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.TD:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.TV:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				break;
			case InputValueDefinitionEnum.T:
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				break;
			case InputValueDefinitionEnum.DTVD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.DTD:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputValueDefinitionEnum.DTV:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				this.accept(this.parser.defaultValues[obj.dfIdx]);
				break;
			case InputValueDefinitionEnum.DT:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.types[obj.typeIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(InterfaceTypeDefinition) obj) {}
	void exit(ref const(InterfaceTypeDefinition) obj) {}

	void accept(ref const(InterfaceTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InterfaceTypeDefinitionEnum.NDF:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
			case InterfaceTypeDefinitionEnum.NF:
				obj.name.visit(this);
				this.accept(this.parser.fieldDefinitionss[obj.fdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(UnionTypeDefinition) obj) {}
	void exit(ref const(UnionTypeDefinition) obj) {}

	void accept(ref const(UnionTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case UnionTypeDefinitionEnum.NDU:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				this.accept(this.parser.unionMemberss[obj.umIdx]);
				break;
			case UnionTypeDefinitionEnum.NU:
				obj.name.visit(this);
				this.accept(this.parser.unionMemberss[obj.umIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(UnionMembers) obj) {}
	void exit(ref const(UnionMembers) obj) {}

	void accept(ref const(UnionMembers) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case UnionMembersEnum.S:
				obj.name.visit(this);
				break;
			case UnionMembersEnum.SPF:
				obj.name.visit(this);
				this.accept(this.parser.unionMemberss[obj.followIdx]);
				break;
			case UnionMembersEnum.SF:
				obj.name.visit(this);
				this.accept(this.parser.unionMemberss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(EnumTypeDefinition) obj) {}
	void exit(ref const(EnumTypeDefinition) obj) {}

	void accept(ref const(EnumTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.enumValueDefinitionss[obj.evdsIdx]);
				break;
			case EnumTypeDefinitionEnum.NE:
				obj.name.visit(this);
				this.accept(this.parser.enumValueDefinitionss[obj.evdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(EnumValueDefinitions) obj) {}
	void exit(ref const(EnumValueDefinitions) obj) {}

	void accept(ref const(EnumValueDefinitions) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionsEnum.D:
				this.accept(this.parser.enumValueDefinitions[obj.evdIdx]);
				break;
			case EnumValueDefinitionsEnum.DCE:
				this.accept(this.parser.enumValueDefinitions[obj.evdIdx]);
				this.accept(this.parser.enumValueDefinitionss[obj.followIdx]);
				break;
			case EnumValueDefinitionsEnum.DE:
				this.accept(this.parser.enumValueDefinitions[obj.evdIdx]);
				this.accept(this.parser.enumValueDefinitionss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(EnumValueDefinition) obj) {}
	void exit(ref const(EnumValueDefinition) obj) {}

	void accept(ref const(EnumValueDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case EnumValueDefinitionEnum.ED:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case EnumValueDefinitionEnum.E:
				obj.name.visit(this);
				break;
			case EnumValueDefinitionEnum.DED:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case EnumValueDefinitionEnum.DE:
				this.accept(this.parser.descriptions[obj.desIdx]);
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(InputTypeDefinition) obj) {}
	void exit(ref const(InputTypeDefinition) obj) {}

	void accept(ref const(InputTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputTypeDefinitionEnum.NDE:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirIdx]);
				this.accept(this.parser.inputValueDefinitionss[obj.ivdsIdx]);
				break;
			case InputTypeDefinitionEnum.NE:
				obj.name.visit(this);
				this.accept(this.parser.inputValueDefinitionss[obj.ivdsIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(TypeExtensionDefinition) obj) {}
	void exit(ref const(TypeExtensionDefinition) obj) {}

	void accept(ref const(TypeExtensionDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TypeExtensionDefinitionEnum.O:
				this.accept(this.parser.objectTypeDefinitions[obj.otdIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(DirectiveDefinition) obj) {}
	void exit(ref const(DirectiveDefinition) obj) {}

	void accept(ref const(DirectiveDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveDefinitionEnum.AD:
				obj.name.visit(this);
				this.accept(this.parser.argumentsDefinitions[obj.adIdx]);
				this.accept(this.parser.directiveLocationss[obj.dlIdx]);
				break;
			case DirectiveDefinitionEnum.D:
				obj.name.visit(this);
				this.accept(this.parser.directiveLocationss[obj.dlIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(DirectiveLocations) obj) {}
	void exit(ref const(DirectiveLocations) obj) {}

	void accept(ref const(DirectiveLocations) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DirectiveLocationsEnum.N:
				obj.name.visit(this);
				break;
			case DirectiveLocationsEnum.NPF:
				obj.name.visit(this);
				this.accept(this.parser.directiveLocationss[obj.followIdx]);
				break;
			case DirectiveLocationsEnum.NF:
				obj.name.visit(this);
				this.accept(this.parser.directiveLocationss[obj.followIdx]);
				break;
		}
		exit(obj);
	}

	void enter(ref const(InputObjectTypeDefinition) obj) {}
	void exit(ref const(InputObjectTypeDefinition) obj) {}

	void accept(ref const(InputObjectTypeDefinition) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case InputObjectTypeDefinitionEnum.NDI:
				obj.name.visit(this);
				this.accept(this.parser.directivess[obj.dirsIdx]);
				break;
			case InputObjectTypeDefinitionEnum.NI:
				obj.name.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(ref const(Description) obj) {}
	void exit(ref const(Description) obj) {}

	void accept(ref const(Description) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case DescriptionEnum.S:
				obj.tok.visit(this);
				break;
		}
		exit(obj);
	}
}

