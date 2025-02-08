module graphql.treevisitor;

import std.traits : Unqual;
import graphql.ast;
import graphql.visitor;
import graphql.tokenmodule;

class TreeVisitor : ConstVisitor {
@safe :

	import std.stdio : write, writeln;

	alias accept = ConstVisitor.accept;

	int depth;

	this(int d) {
		this.depth = d;
	}

	void genIndent() {
		foreach(i; 0 .. this.depth) {
			write("    ");
		}
	}

	override void accept(const(Document) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Definitions) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Definition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(OperationDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(SelectionSet) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(OperationType) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Selections) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Selection) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(FragmentSpread) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(InlineFragment) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Field) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(FieldName) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Identifier) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Arguments) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ArgumentList) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Argument) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(FragmentDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Directives) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Directive) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(VariableDefinitions) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(VariableDefinitionList) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(VariableDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Variable) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(DefaultValue) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ValueOrVariable) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Value) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Type) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ListType) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Values) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Array) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ObjectValues) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ObjectType) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(TypeSystemDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(TypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(SchemaDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(OperationTypeDefinitions) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(OperationTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ScalarTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ObjectTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(FieldDefinitions) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(FieldDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ImplementsInterfaces) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(NamedTypes) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(ArgumentsDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(InputValueDefinitions) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(InputValueDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(InterfaceTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(UnionTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(UnionMembers) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(EnumTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(EnumValueDefinitions) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(EnumValueDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(InputTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(TypeExtensionDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(DirectiveDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(DirectiveLocations) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(InputObjectTypeDefinition) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Description) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}
}
