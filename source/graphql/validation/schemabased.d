module graphql.validation.schemabased;

import std.exception : enforce, assertThrown, assertNotThrown;

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

	this(const(Document) doc, GQLDSchema!(Type) schema) {
		this.doc = doc;
		this.schema = schema;
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
