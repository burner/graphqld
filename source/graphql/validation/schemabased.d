module graphql.validation.schemabased;

import std.array : array, back, empty, front, popBack;
import std.exception : enforce, assertThrown, assertNotThrown;
import std.format : format;
import std.stdio;

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
		import graphql.traits;
		writefln("\n\nFoo '%s'", name);

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

		Json field = this.schemaStack.back.type.getField(name);
		enforce!FieldDoesNotExist(
				field.type == Json.Type.object,
				format("Type '%s' does not have fields named '%s'",
					this.schemaStack.back.name, name)
			);

		string followType = field[Constants.typenameOrig].get!string();

		l: switch(followType) {
			static foreach(type; collectTypes!(Type)) {{
				case typeToTypeName!(type): {
					this.schemaStack ~= TypePlusName(
							removeNonNullAndList(typeToJson!(type,Type)()), name
						);
					writeln(this.schemaStack.back.type.toPrettyString());
					break l;
				}
			}}
			default:
				assert(false, format("%s %s", name, followType));
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

	override void enter(const(FragmentSpread) fragSpread) {
		const(FragmentDefinition) frag = findFragment(this.doc,
				fragSpread.name.value
			);
		frag.ss.visit(this);
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

unittest {
	string str = `
subscription sub {
	starships {
		id
		name
	}
}`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertNotThrown!SingleRootField(fv.accept(doc));
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

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!SingleRootField(fv.accept(doc));
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

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!SingleRootField(fv.accept(doc));
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

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!SingleRootField(fv.accept(doc));
}

unittest {
	string str = `
{
	starships {
		id
	}
}
`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertNotThrown(fv.accept(doc));
}

unittest {
	string str = `
{
	starships {
		fieldDoesNotExist
	}
}
`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!FieldDoesNotExist(fv.accept(doc));
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

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!FieldDoesNotExist(fv.accept(doc));
}

unittest {
	string str = `
query q {
	search {
		shipId
	}
}`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!FieldDoesNotExist(fv.accept(doc));
}

unittest {
	string str = `
query q {
	search {
		...ShipFrag
	}
}

fragment ShipFrag on Starship {
	shipId
}
`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertNotThrown(fv.accept(doc));
}
