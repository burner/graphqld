module graphql.validation.schemabased;

import std.array : array, back, empty, front, popBack;
import std.exception : enforce, assertThrown, assertNotThrown;
import std.stdio;

import fixedsizearray;

import graphql.ast;
import graphql.builder;
import graphql.visitor;
import graphql.schema.types;
import graphql.validation.exception;
import graphql.helper : lexAndParse;

enum IsSubscription {
	no,
	yes
}

class SchemaValidator(Type) : Visitor {
	import std.experimental.typecons : Final;
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
	GQLDType[] schemaStack;

	this(const(Document) doc, GQLDSchema!(Type) schema) {
		this.doc = doc;
		this.schema = schema;
		this.schemaStack ~= this.schema;
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

	override void enter(const(FragmentSpread) fragSpread) {
		const(FragmentDefinition) frag = findFragment(this.doc,
				fragSpread.name.value
			);
		frag.ss.visit(this);
	}

	override void enter(const(OperationDefinition) op) {
		auto t = this.schema.__schema;
		this.schemaStack ~= op.ruleSelection == OperationDefinitionEnum.SelSet
			? this.schema.getReturnType(t, "queryType")
			: op.ot.ruleSelection == OperationTypeEnum.Query
				? this.schema.getReturnType(t, "queryType")
				: op.ot.ruleSelection == OperationTypeEnum.Mutation
					? this.schema.getReturnType(t, "mutationType")
					: op.ot.ruleSelection == OperationTypeEnum.Sub
						? this.schema.getReturnType(t, "subscriptionType")
						: null;
		enforce(this.schemaStack.back !is null);
	}

	override void exit(const(OperationDefinition) op) {
		this.schemaStack.popBack();
	}
}

import graphql.testschema;
unittest {
	string str = `
subscription sub {
	newMessage {
		body
		sender
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
  newMessage {
    body
    sender
  }
  disallowedSecondRootField
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
  newMessage {
    body
    sender
  }
  disallowedSecondRootField
}`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!SingleRootField(fv.accept(doc));
}

unittest {
	string str = `
subscription sub {
  newMessage {
    body
    sender
  }
  __typename
}`;

	GQLDSchema!(Schema) testSchema = new GQLDSchema!(Schema)();
	auto doc = lexAndParse(str);

	auto fv = new SchemaValidator!Schema(doc, testSchema);
	assertThrown!SingleRootField(fv.accept(doc));
}
