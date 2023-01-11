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


		//writefln("%s %s %s", __LINE__, name, field.toString());
		string followType = field[Constants.typenameOrig].get!string();
		string old = followType;
		StringTypeStrip stripped = followType.stringTypeStrip();
		this.addTypeToStackImpl(name, stripped.str, old);
	}

	void addTypeToStackImpl(string name, string followType, string old) {
		if(auto tp = followType in typeMap) {
			this.schemaStack ~= TypePlusName(tp.clone, name);
		} else {
			throw new UnknownTypeName(
					  format("No type with name '%s' '%s' is known",
							 followType, old), __FILE__, __LINE__);
		}
	}

	this(const(Document) doc, GQLDSchema!(Schema) schema) {
		import graphql.schema.introspectiontypes : IntrospectionTypes;
		this.doc = doc;
		this.schema = schema;
		static void buildTypeMap(T)(ref Json[string] map) {
			static if(is(T == stripArrayAndNullable!T)) {
				map[typeToTypeName!T] =
				   	removeNonNullAndList(typeToJson!(T, Schema)());
			}
		}
		execForAllTypes!(Schema, buildTypeMap)(typeMap);
		foreach(T; IntrospectionTypes) {
			buildTypeMap!T(typeMap);
		}
		this.schemaStack ~= TypePlusName(
				removeNonNullAndList(typeToJson!(Schema,Schema)()),
				Schema.stringof
			);
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
		if(auto tp = typeName in typeMap) {
			this.schemaStack ~= TypePlusName(tp.clone, typeName);
		} else {
			throw new UnknownTypeName(
					  format("No type with name '%s' is known", typeName),
					  __FILE__, __LINE__);
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
				?	"mutationType"
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
		import std.array : empty;
		string n = fn.aka.value.empty ? fn.name.value : fn.aka.value;
		this.addToTypeStack(n);
	}

	override void enter(const(InlineFragment) inF) {
		this.addTypeToStackImpl(inF.tc.value, inF.tc.value, "");
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
		import std.algorithm.searching : find, startsWith, endsWith;
		const argName = arg.name.value;
		if(this.directiveStack.empty) {
			const parent = this.schemaStack[$ - 2];
			const curName = this.schemaStack.back.name;
			auto fields = parent.type[Constants.fields];
			if(fields.type != Json.Type.Array) {
				return;
			}
			auto curNameFieldRange = fields.byValue
				.find!(f => f[Constants.name].to!string() == curName);
			if(curNameFieldRange.empty) {
				return;
			}

			auto curNameField = curNameFieldRange.front;

			const Json curArgs = curNameField[Constants.args];
			auto argElem = curArgs.byValue.find!(a => a[Constants.name] == argName);

			enforce!ArgumentDoesNotExist(!argElem.empty, format(
					"Argument with name '%s' does not exist for field '%s' of type "
					~ " '%s'", argName, curName, parent.type[Constants.name]));

			if(arg.vv.ruleSelection == ValueOrVariableEnum.Var) {
				const varName = arg.vv.var.name.value;
				auto varType = varName in this.variables;
				enforce(varName !is null);

				string typeStr = astTypeToString(*varType);
				const nonArray = ["", "!", "In", "In!"];
				bool nonArrayR;
				nonArrayOuter: foreach(g; nonArray) {
					string gstr = argElem.front[Constants.typenameOrig]
						.to!string();
					string gtmp = gstr.endsWith(g)
						? gstr[0 .. $ - g.length]
						: gstr;
					foreach(h; nonArray) {
						const htmp = typeStr.endsWith(h)
							? typeStr[0 .. $ - h.length]
							: typeStr;
						if(htmp == gtmp) {
							nonArrayR = true;
							break nonArrayOuter;
						}
					}
				}

				const array = ["]", "]!", "!]", "!]!", "In]!", "In!]", "In!]!"];
				bool arrayR;
				arrayOuter: foreach(g; array) {
					string gstr = argElem.front[Constants.typenameOrig]
						.to!string();
					if(!gstr.startsWith("[")) {
						break;
					}
					const gtmp = gstr.endsWith(g)
						? gstr[0 .. $ - g.length]
						: gstr;
					foreach(h; array) {
						if(!typeStr.startsWith("[")) {
							break arrayOuter;
						}
						const htmp = typeStr.endsWith(h)
							? typeStr[0 .. $ - h.length]
							: typeStr;
						if(htmp == gtmp) {
							arrayR = true;
							break arrayOuter;
						}
					}
				}

				const c1 = argElem.front[Constants.typenameOrig] == typeStr;
				enforce!VariableInputTypeMismatch(c1 || nonArrayR || arrayR
						, format("Variable type '%s' does not match argument type '%s'"
						, argElem.front[Constants.typenameOrig], typeStr
						));
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
