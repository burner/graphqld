module graphql.validation.schemabased;

import std.algorithm.iteration : map;
import std.algorithm.searching : canFind;
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
import graphql.visitor;
import graphql.schema.types;
import graphql.schema.helper;
import graphql.validation.exception;
import graphql.helper : lexAndParse;

@safe:

enum IsSubscription {
	no,
	yes
}

struct TypePlusName {
	Json type;
	string name;

	string toString() const {
		return format("%s %s", this.name, this.type);
	}
}

class SchemaValidator(Type) : Visitor {
	import std.experimental.typecons : Final;
	import graphql.schema.typeconversions;
	import graphql.traits;
	import graphql.helper : stringTypeStrip;

	alias enter = Visitor.enter;
	alias exit = Visitor.exit;
	alias accept = Visitor.accept;

	const(Document) doc;
	GQLDSchema!(Type) schema;

	// Single root field
	IsSubscription isSubscription;
	int ssCnt;
	int selCnt;

	// Field Selections on Objects
	TypePlusName[] schemaStack;

	void addToTypeStack(string name) {
		//writefln("\n\nFoo '%s' %s", name, this.schemaStack.map!(a => a.name));

		enforce!FieldDoesNotExist(
				Constants.fields in this.schemaStack.back.type,
				format("Type '%s' does not have fields",
					this.schemaStack.back.name)
			);

		enforce!FieldDoesNotExist(
				this.schemaStack.back.type.type == Json.Type.object,
				format("Field '%s' of type '%s' is not a Json.Type.object",
					name, this.schemaStack.back.name)
			);

		immutable toFindIn = [Constants.__typename, Constants.__schema,
				  Constants.__type];
		Json field = canFind(toFindIn, name)
			? getIntrospectionField(name)
			: this.schemaStack.back.type.getField(name);
		enforce!FieldDoesNotExist(
				field.type == Json.Type.object,
				format("Type '%s' does not have fields named '%s'",
					this.schemaStack.back.name, name)
			);

		string followType = field[Constants.typenameOrig].get!string();
		string old = followType;
		followType = followType.stringTypeStrip();

		l: switch(followType) {
			alias AllTypes = collectTypesPlusIntrospection!(Type);
			alias Stripped = staticMap!(stripArrayAndNullable, AllTypes);
			alias NoDups = NoDuplicates!(Stripped);
			static foreach(type; NoDups) {{
				case typeToTypeName!(type): {
					this.schemaStack ~= TypePlusName(
							removeNonNullAndList(typeToJson!(type,Type)()),
							name
						);
					//writeln(this.schemaStack.back.type.toPrettyString());
					break l;
				}
			}}
			default:
				throw new UnknownTypeName(
						format("No type with name '%s' '%s' is known",
							followType, old), __FILE__, __LINE__);
		}
	}

	this(const(Document) doc, GQLDSchema!(Type) schema) {
		this.doc = doc;
		this.schema = schema;
		this.schemaStack ~= TypePlusName(
				removeNonNullAndList(typeToJson!(Type,Type)()), Type.stringof
			);
	}

	override void enter(const(OperationType) ot) {
		this.isSubscription = ot.ruleSelection == OperationTypeEnum.Sub
			? IsSubscription.yes : IsSubscription.no;
	}

	override void enter(const(SelectionSet) ss) {
		//writeln(this.schemaStack);
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
		//writefln("%s %s", typeName, fragDef.name.value);
		l: switch(typeName) {
			alias AllTypes = collectTypesPlusIntrospection!(Type);
			alias Stripped = staticMap!(stripArrayAndNullable, AllTypes);
			alias NoDups = NoDuplicates!(Stripped);
			static foreach(type; NoDups) {{
				case typeToTypeName!(type): {
					this.schemaStack ~= TypePlusName(
							removeNonNullAndList(typeToJson!(type,Type)()),
							typeName
						);
					//writeln(this.schemaStack.back.type.toPrettyString());
					break l;
				}
			}}
			default:
				throw new UnknownTypeName(
						format("No type with name '%s' is known",
							typeName), __FILE__, __LINE__);
		}
	}

	override void enter(const(FragmentSpread) fragSpread) {
		enum uo = ["OBJECT", "UNION", "INTERFACE"];
		enforce!FragmentNotOnCompositeType(
				"kind" in this.schemaStack.back.type
				&& canFind(uo, this.schemaStack.back.type["kind"].get!string()),
				format("'%s' is not an %(%s, %)",
					this.schemaStack.back.type.toPrettyString(), uo)
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
				?  "mutationType"
				: op.ot.ruleSelection == OperationTypeEnum.Sub
					? "subscriptionType"
					: "";
		enforce(!name.empty);
		this.addToTypeStack(name);
	}

	override void accept(const(Field) f) {
		super.accept(f);
		enforce!LeafIsNotAScalar(f.ss !is null ||
				(this.schemaStack.back.type["kind"].get!string() == "SCALAR"
				|| this.schemaStack.back.type["kind"].get!string() == "ENUM"),
				format("Leaf field '%s' is not a SCALAR but '%s'",
					this.schemaStack.back.name,
					this.schemaStack.back.type.toPrettyString())
				);
	}

	override void enter(const(FieldName) fn) {
		//enforce(fn.name.value
		this.addToTypeStack(fn.name.value);
	}

	override void exit(const(Selection) op) {
		this.schemaStack.popBack();
	}

	override void exit(const(OperationDefinition) op) {
		this.schemaStack.popBack();
	}
}

import graphql.testschema;

private void test(T)(string str) {
	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);
	auto fv = new SchemaValidator!Schema(doc, testSchema);

	static if(is(T == void)) {
		assertNotThrown(fv.accept(doc));
	} else {
		assertThrown!T(fv.accept(doc));
	}
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
