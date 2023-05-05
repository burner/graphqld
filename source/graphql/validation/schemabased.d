module graphql.validation.schemabased;

import std.algorithm.iteration : map;
import std.algorithm.searching : canFind, find, startsWith, endsWith;
import std.array : array, back, empty, front, popBack;
import std.conv : to;
import std.meta : staticMap, NoDuplicates;
import std.exception : enforce, assertThrown, assertNotThrown;
import std.format : format;
import std.stdio;
import std.string : strip;

import vibe.data.json;

import fixedsizearray;

import graphql.ast;
import graphql.builder;
import graphql.constants;
import graphql.helper : allMember, lexAndParse;
import graphql.schema.helper;
import graphql.schema.introspectiontypes : IntrospectionTypes;
import graphql.schema.types;
import graphql.uda;
import graphql.validation.exception;
import graphql.visitor;
import graphql.graphql;

@safe:

string astTypeToString(const(Type) input) pure {
	final switch(input.ruleSelection) {
		case TypeEnum.TN:
			return format("%s!", input.tname.value);
		case TypeEnum.LN:
			return format("[%s]!", astTypeToString(input.list.type));
		case TypeEnum.T:
			return format("%s", input.tname.value);
		case TypeEnum.L:
			return format("[%s]", astTypeToString(input.list.type));
	}
}

bool stringCompareWithOutInPostfix(string a, string b) {
	string diff = a.length < b.length
		? b[a.length .. $]
		: a[b.length .. $];
	//writefln("a %s b %s, diff '%s'", a, b, diff);
	return diff.empty || diff == "In"
		|| (a.length > b.length && diff == "!");
}

bool astTypeCompareToGQLDType(const(Type) ast, GQLDType type) {
	type = type.unpackNullable();
	//writefln("%s %s %s", astTypeToString(ast), ast.ruleSelection, type.name);
	bool ret;
	if(GQLDNonNull nn = type.toNonNull()) {
		final switch(ast.ruleSelection) {
			case TypeEnum.TN: // NonNull
				ret = ast.tname.value == nn.elementType.name;
				break;
			case TypeEnum.LN: // NonNull(List)
				GQLDList l = nn.elementType.unpack().toList();
				ret = l is null
					? false
					: astTypeCompareToGQLDType(ast.list.type, l.elementType);
				break;
			case TypeEnum.T: // anker
				ret = false;
				break;
			case TypeEnum.L: // List
				ret = false;
				break;
		}
		return ret;
	} else if(GQLDList l = type.toList()) {
		final switch(ast.ruleSelection) {
			case TypeEnum.TN: // NonNull
				ret = false;
				break;
			case TypeEnum.LN: // NonNull(List)
				ret = astTypeCompareToGQLDType(ast.list.type, l.elementType);
				break;
			case TypeEnum.T: // anker
				ret = false;
				break;
			case TypeEnum.L: // List
				ret = astTypeCompareToGQLDType(ast.list.type, l.elementType);
				break;
		}
		return ret;
	}
	ret = ast.tname.value == type.name;
	return ret;
	/*final switch(ast.ruleSelection) {
		case TypeEnum.TN: // NonNull
			GQLDNonNull nn = type.toNonNull();
			return nn is null
				? false
				: stringCompareWithOutInPostfix(ast.tname.value, nn.elementType.name);
		case TypeEnum.LN: // NonNull(List)
			GQLDNonNull nn = type.toNonNull();
			if(nn is null) {
				return false;
			}
			GQLDList l = nn.elementType.unpack().toList();
			return l is null
				? false
				: astTypeCompareToGQLDType(ast.list.type, l.elementType);
		case TypeEnum.T: // anker
			bool ret = stringCompareWithOutInPostfix(ast.tname.value, type.name);
			return ret;
		case TypeEnum.L: // List
			GQLDList l = type.toList();
			return l !is null;
	}*/
}

enum IsSubscription {
	no,
	yes
}

struct TypePlusName {
	GQLDType type;
	string name;
	string fieldName;

	string toString() const {
		return format("%s %s", this.name, this.type);
	}
}

struct DirectiveEntry {
	string name;
}

class SchemaValidator(Schema) : Visitor {
	import graphql.schema.typeconversions;
	import graphql.traits;
	import graphql.helper : StringTypeStrip, stringTypeStrip;

	alias enter = Visitor.enter;
	alias exit = Visitor.exit;
	alias accept = Visitor.accept;

	const(Document) doc;
	GQLDSchema!(Schema) schema;

	private Json[string] typeMap;

	// Single root field
	IsSubscription isSubscription;
	int ssCnt;
	int selCnt;

	// Field Selections on Objects
	TypePlusName[] schemaStack;

	// Variables of operation
	Type[string] variables;

	DirectiveEntry[] directiveStack;

	this(const(Document) doc, GQLDSchema!(Schema) schema) {
		this.doc = doc;
		this.schema = schema;
		this.schemaStack ~= TypePlusName(
				this.schema.__schema
				, typeof(schema).stringof
				, "__schema"
			);
	}

	void addToTypeStack(string name) {
		//writefln("\naddToTypeStack %s %s", name, this.schemaStack.map!(i => i.type.name));
		GQLDMap backMap = toMap(this.schemaStack.back.type.unpack2());
		enforce!FieldDoesNotExist(backMap !is null,
				format("Type '%s' does not have fields",
					this.schemaStack.back.name));

		GQLDType t = this.schema.getReturnType(this.schemaStack.back.type, name);
		enforce!FieldDoesNotExist(t !is null
				, format("No returnType for field '%s.%s' %s all members [%(%s, %)]"
					, this.schemaStack.back.type.name
					, name
					, this.schemaStack.map!(i => i.type.name)
					, backMap is null ? [] : allMember(backMap).byKey().array)
			);
		GQLDType un = t.unpack2();
		enforce!FieldDoesNotExist(un !is null
				, format("Type '%s' does not have fields named '%s' but [%--(%s, %)]"
					, this.schemaStack.back.name, name
					, backMap.member.byKey())
			);
		this.schemaStack ~= TypePlusName(un, un.name, name);
	}

	override void enter(const(Directive) dir) {
		this.directiveStack ~= DirectiveEntry(dir.name.value);
	}

	override void exit(const(Directive) dir) {
		this.directiveStack.popBack();
	}

	override void enter(const(OperationType) ot) {
		this.isSubscription = ot.ruleSelection == OperationTypeEnum.Sub
			? IsSubscription.yes : IsSubscription.no;
	}

	override void enter(const(SelectionSet) ss) {
		++this.ssCnt;
	}

	override void exit(const(SelectionSet) ss) {
		--this.ssCnt;
	}

	override void enter(const(Selection) sel) {
		++this.selCnt;
		const bool notSingleRootField = this.isSubscription == IsSubscription.yes
				&& this.ssCnt == 1
				&& this.selCnt > 1;

		enforce!SingleRootField(!notSingleRootField);
	}

	override void enter(const(FragmentDefinition) fragDef) {
		string typeName = fragDef.tc.value;
		if(auto tp = typeName in this.schema.types) {
			this.schemaStack ~= TypePlusName(*tp, typeName, fragDef.name.value);
		} else {
			throw new UnknownTypeName(
					  format("No type with name '%s' is known", typeName),
					  __FILE__, __LINE__);
		}
	}

	override void enter(const(FragmentSpread) fragSpread) {
		enum uo = [TypeKind.OBJECT, TypeKind.UNION, TypeKind.INTERFACE];
		enforce!FragmentNotOnCompositeType(canFind(uo
					, this.schemaStack.back.type.typeKind),
				format("'%s' is not an %(%s, %) but '%s'. Stack %s"
					, this.schemaStack.back.type.toString(), uo
					, this.schemaStack.back.type.typeKind
					, this.schemaStack.map!(it => format("%s.%s", it.name, it.fieldName))
					)
			);
		const(FragmentDefinition) frag = findFragment(this.doc,
				fragSpread.name.value
			);
		frag.visit(this);
	}

	override void enter(const(OperationDefinition) op) {
		string name = op.ruleSelection == OperationDefinitionEnum.SelSet
				|| op.ot.ruleSelection == OperationTypeEnum.Query
			? "queryType"
			: op.ot.ruleSelection == OperationTypeEnum.Mutation
				? "mutationType"
				: op.ot.ruleSelection == OperationTypeEnum.Sub
					? "subscriptionType"
					: "";
		enforce(!name.empty);
		this.addToTypeStack(name);
	}

	override void accept(const(Field) f) {
		super.accept(f);
		enforce!LeafIsNotAScalar(f.ss !is null ||
				(this.schemaStack.back.type.typeKind == TypeKind.SCALAR
				|| this.schemaStack.back.type.typeKind == TypeKind.ENUM),
				format("Leaf field '%s' is not a SCALAR nor ENUM but '%s'. Stack %s. Back %s"
					, f.name.name.value
					, this.schemaStack.back.type.typeKind
					, this.schemaStack.map!(it => format("%s.%s", it.name, it.fieldName))
					, this.schemaStack.back.type
					)
				);
	}

	override void enter(const(FieldName) fn) {
		import std.array : empty;
		string n = fn.aka.value.empty ? fn.name.value : fn.aka.value;
		this.addToTypeStack(n);
	}

	override void enter(const(InlineFragment) inF) {
		if(auto tp = inF.tc.value in this.schema.types) {
			this.schemaStack ~= TypePlusName((*tp).unpack2(), inF.tc.value, "");
		} else {
			throw new UnknownTypeName(
					  format("No type with name '%s' is known",
							 inF.tc.value), __FILE__, __LINE__);
		}
	}

	override void exit(const(Selection) op) {
		this.schemaStack.popBack();
	}

	override void exit(const(OperationDefinition) op) {
		this.schemaStack.popBack();
	}

	override void enter(const(VariableDefinition) vd) {
		const vdName = vd.var.name.value;
		() @trusted {
			this.variables[vdName] = cast()vd.type;
		}();
	}

	override void enter(const(Argument) arg) {
		const argName = arg.name.value;
		if(this.directiveStack.empty) { // means normal field variable
			auto parent = this.schemaStack[$ - 2];
			//writefln("%s %s", argName, parent.type);
			GQLDMap parentMap = parent.type.toMap();
			enforce!ValidationException(parentMap !is null, format(
					"'%s' has no fields" , parent.type.name
				));

			GQLDType* fieldPtr = this.schemaStack.back.fieldName in
				parentMap.member;
			enforce!ValidationException(fieldPtr !is null, format(
					"'%s' has no field names '%s'" , parent.type.name
					, this.schemaStack.back.fieldName
				));

			GQLDOperation op = (*fieldPtr).unpack().toOperation();
			enforce!ValidationException(op !is null, format(
					"Field '%s.%s' is not callable. Type is '%s'"
					, parent.type.name
					, this.schemaStack.back.fieldName
					, (*fieldPtr).unpack()
				));

			GQLDType* theArg = argName in op.parameters;
			enforce!ArgumentDoesNotExist(theArg !is null, format(
					"No argument with name '%s' exists on '%s.%s'"
					~ " available are [%s]", argName
					, parent.type.name
					, this.schemaStack.back.fieldName
					, op.parameters.byKey()
			));
			if(arg.vv.ruleSelection == ValueOrVariableEnum.Var) {
				const varName = arg.vv.var.name.value;
				auto varType = varName in this.variables;
				enforce(varName !is null);

				bool compareOkay = astTypeCompareToGQLDType(*varType
					, *theArg);

				enforce!VariableInputTypeMismatch(compareOkay
						, format("Variable type '%s' does not match argument type '%s'"
						, astTypeToString(*varType), *theArg)
					);
			}

		} else {
			enforce!ArgumentDoesNotExist(argName == "if", format(
					"Argument of Directive '%s' is 'if' not '%s'",
					this.directiveStack.back.name, argName));

			if(arg.vv.ruleSelection == ValueOrVariableEnum.Var) {
				const varName = arg.vv.var.name.value;
				auto varType = varName in this.variables;
				enforce(varName !is null);

				string typeStr = astTypeToString(*varType);
				enforce!VariableInputTypeMismatch(
						typeStr == "Boolean!",
						format("Variable type '%s' does not match argument type 'Boolean!'"
						, typeStr));
			}
		}
	}
}

import graphql.testschema;

private void test(T)(string str) {
	auto graphqld = new GraphQLD!(Schema);
	auto doc = lexAndParse(str);
	auto fv = new SchemaValidator!Schema(doc, graphqld.schema);

	static if(is(T == void)) {
		assertNotThrown(fv.accept(doc));
	} else {
		assertThrown!T(fv.accept(doc));
	}
}

unittest {
	string str = `
{
	starships {
		id
	}
}
`;

	test!void(str);
}

unittest {
	string str = `
{
	starships {
		fieldDoesNotExist
	}
}
`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
{
	starships {
		id {
			name
		}
	}
}
`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
query q {
	search {
		shipId
	}
}`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
query q {
	search {
		...ShipFrag
	}
}

fragment ShipFrag on Starship {
	designation
}
`;

	test!void(str);
}

unittest {
	string str = `
query q {
	search {
		...ShipFrag
		...CharFrag
	}
}

fragment ShipFrag on Starship {
	designation
}

fragment CharFrag on Character {
	foobar
}
`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
mutation q {
	addCrewman {
		...CharFrag
	}
}

fragment CharFrag on Character {
	name
}
`;

	test!void(str);
}

unittest {
	string str = `
mutation q {
	addCrewman {
		...CharFrag
	}
}

fragment CharFrag on Character {
	foobar
}
`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
subscription q {
	starships {
		id
		designation
	}
}
`;

	test!void(str);
}

unittest {
	string str = `
subscription q {
	starships {
		id
		doesNotExist
	}
}
`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
query q {
	search {
		...ShipFrag
		...CharFrag
	}
}

fragment ShipFrag on Starship {
	designation
}

fragment CharFrag on Character {
	name
}
`;

	test!void(str);
}

unittest {
	string str = `
{
	starships {
		__typename
	}
}
`;

	test!void(str);
}

unittest {
	string str = `
{
	__schema {
		types {
			name
		}
	}
}
`;

	test!void(str);
}

unittest {
	string str = `
{
	__schema {
		types {
			enumValues {
				name
			}
		}
	}
}
`;

	test!void(str);
}

unittest {
	string str = `
{
	__schema {
		types {
			enumValues {
				doesNotExist
			}
		}
	}
}
`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
query q {
	search {
		...CharFrag
	}
}

fragment CharFrag on NonExistingType {
	name
}
`;

	test!UnknownTypeName(str);
}

unittest {
	string str = `
query q {
	search {
		...CharFrag
	}
}

fragment CharFrag on Character {
	name
}
`;

	test!void(str);
}

unittest {
	string str = `
query q {
	starships {
		id {
			...CharFrag
		}
	}
}

fragment CharFrag on Character {
	name {
		foo
	}
}
`;

	test!FragmentNotOnCompositeType(str);
}

unittest {
	string str = `
query q {
	starships {
		crew
	}
}
`;

	test!LeafIsNotAScalar(str);
}

unittest {
	string str = `
query q {
	starships {
		crew {
			name
		}
	}
}
`;

	test!void(str);
}

unittest {
	string str = `
{
	starships {
		crew {
			id
			ship
		}
	}
}
`;

	test!LeafIsNotAScalar(str);
}

unittest {
	string str = `
{
	starships {
		crew {
			id
			ships
		}
	}
}`;

	test!LeafIsNotAScalar(str);
}

unittest {
	string str = `
{
	starships
}`;

	test!LeafIsNotAScalar(str);
}

unittest {
	string str = `
query q($size: String) {
	starships(overSizeg: $size) {
		id
	}
}`;

	test!ArgumentDoesNotExist(str);
}

unittest {
	string str = `
query q($size: String) {
	starships(overSize: $size) {
		id
	}
}`;

	test!VariableInputTypeMismatch(str);
}

unittest {
	string str = `
query q($size: Float!) {
	starships(overSize: $size) {
		id
	}
}`;

	test!void(str);
}

unittest {
	string str = `
query q($ships: [Int!]!) {
	shipsselection(ids: $ships) {
		id
	}
}`;

	test!void(str);
}

unittest {
	string str = `
{
	starships {
		crew {
			... on Humanoid {
				dateOfBirth
			}
		}
	}
}`;

	test!void(str);
}

unittest {
	string str = `
{
	starships {
		crew {
			... on Humanoid {
				doesNotExist
			}
		}
	}
}`;

	test!FieldDoesNotExist(str);
}

unittest {
	string str = `
query q($cw: Boolean!) {
	starships {
		crew @include(if: $cw) {
			... on Humanoid {
				dateOfBirth
			}
		}
	}
}`;

	test!void(str);
}

unittest {
	string str = `
query q($cw: Int!) {
	starships {
		crew @include(if: $cw) {
			... on Humanoid {
				dateOfBirth
			}
		}
	}
}`;

	test!VariableInputTypeMismatch(str);
}

unittest {
	string str = `
query q($cw: Int!) {
	starships {
		crew @include(notIf: $cw) {
			... on Humanoid {
				dateOfBirth
			}
		}
	}
}`;

	test!ArgumentDoesNotExist(str);
}

unittest {
	string str = `
query {
	numberBetween(searchInput:
		{ first: 10
		, after: null
		}
	) {
		id
	}
}
`;
	test!void(str);
}

unittest {
	string str = `
query foo($after: String) {
	numberBetween(searchInput:
		{ first: 10
		, after: $after
		}
	) {
		id
	}
}
`;
	test!void(str);
}

unittest {
	string str = `
query q {
	androids {
		primaryFunction #inherited
		name #not inherited
	}
}
`;
	test!void(str);
}

unittest {
	string str = `
subscription sub {
	starships {
		id
		name
	}
}`;
	test!void(str);
}

unittest {
	string str = `
subscription sub {
	starships {
		id
		name
	}
	starships {
		size
	}
}`;

	test!SingleRootField(str);
}

unittest {
	string str = `
subscription sub {
	...multipleSubscriptions
}

fragment multipleSubscriptions on Subscription {
	starships {
		id
		name
	}
	starships {
	size
	}
}`;

	test!SingleRootField(str);
}

unittest {
	string str = `
subscription sub {
	starships {
		id
		name
	}
	__typename
}`;

	test!SingleRootField(str);
}

