module graphql.parsertests;

import std.format : format;
import std.stdio;

import graphql.lexer;
import graphql.parser;

private struct TestCase {
	int id;
	QueryParser qp;
	string str;
}

unittest {
	TestCase[] tests;
	tests ~= TestCase(0, QueryParser.yes,
	`
mutation updateUser($userId: String! $name: String!) {
	updateUser(id: $userId name: $name) {
		name
	}
}
`);

	tests ~= TestCase(1, QueryParser.yes, `
query inlineFragmentNoType($expandedInfo: Boolean) {
	user(handle: "zuck") {
		id
		name
		... @include(if: $expandedInfo) {
			firstName
			lastName
			birthday
		}
	}
}
`);

	tests ~= TestCase(2, QueryParser.yes,	`
query HeroForEpisode($ep: Episode!) {
	hero(episode: $ep) {
		name
		... on Droid {
			primaryFunction
		}
		... on Human {
			height
		}
	}
}
`);

	tests ~= TestCase(3, QueryParser.yes,	`
mutation CreateReviewForEpisode($ep: Episode!, $review: ReviewInput!) {
	createReview(episode: $ep, review: $review) {
		stars
		commentary
	}
}
`);

	tests ~= TestCase(4, QueryParser.yes,	`
query HeroNameAndFriends($episode: Episode = "JEDI") {
	hero(episode: $episode) {
		name
		friends {
			name
		}
	}
}`);

	tests ~= TestCase(5, QueryParser.yes,	`
query hero {
		name
		# Queries can have comments!

		# Queries can have comments Another!
		friends {
			name
		}
}`);

	tests ~= TestCase(6, QueryParser.no,	`
enum DogCommand { SIT, DOWN, HEEL }

type Dog implements Pet {
	name: String!
	nickname: String
	barkVolume: Int
	doesKnowCommand(dogCommand: DogCommand!): Boolean!
	isHousetrained(atOtherHomes: Boolean): Boolean!
	owner: Human
}

interface Sentient {
	name: String!
}

interface Pet {
	name: String!
}

type Alien implements Sentient {
	name: String!
	homePlanet: String
}

type Human implements Sentient {
	name: String!
}

enum CatCommand { JUMP }

type Cat implements Pet {
	name: String!
	nickname: String
	doesKnowCommand(catCommand: CatCommand!): Boolean!
	meowVolume: Int
}

union CatOrDog = Cat | Dog
union DogOrHuman = Dog | Human
union HumanOrAlien = Human | Alien

type QueryRoot {
	dog: Dog
}
`);

	tests ~= TestCase(7, QueryParser.no,	`
union SearchResult = Photo | Person
union SearchResult = Photo Person

type Person {
	name: String
	age: Int
}

type Photo {
	height: Int
	width: Int
}

type SearchQuery {
	firstSearchResult: SearchResult
}`);

	tests ~= TestCase(8, QueryParser.no,	`
interface NamedEntity {
	name: String
}

type Person implements NamedEntity {
	name: String
	age: Int
}

type Business implements NamedEntity {
	name: String
	employeeCount: Int
}`);

	tests ~= TestCase(9, QueryParser.no, `type Person {
	name: String
	age: Int
	picture: Url
}`);

	tests ~= TestCase(10, QueryParser.yes, `
query myQuery($someTest: Boolean) {
	experimentalField @skip(if: $someTest)
}`);

	tests ~= TestCase(11, QueryParser.no, `
subscription sub {
	newMessage {
		body
		sender
	}
}

fragment newMessageFields on Message {
	body
	sender
}

subscription sub {
	newMessage {
		... newMessageFields
	}

}`);

	tests ~= TestCase(11, QueryParser.yes, `
query HeroNameAndFriends($episode: Episode) {
	hero(episode: $episode) {
		name,
		friends {
			name
		}
	}
}`);

	tests ~= TestCase(12, QueryParser.yes, `
query name {
	leftComparison: hero(episode: $EMPIRE) {
		...comparisonFields
	}
	rightComparison: hero(episode: $JEDI) {
		...comparisonFields
	}
}
fragment comparisonFields on Character {
	name
	appearsIn
	friends {
		name
	}
}

`);

	tests ~= TestCase(13, QueryParser.yes, `
query name{
	builds(first: 54) {
	   all: number
	}
}
`);

	tests ~= TestCase(14, QueryParser.yes, `
		query foo {
			viewer {
				user {
					name
						builds(first: 1) {
							edges {
								node {
									number
										branch
										message
								}
							}
						}
				}
			}
		}
`);

	tests ~= TestCase(15, QueryParser.yes, `
query foo {
	name
		builds(first: 1) {
		abc
	}
}`);

	tests ~= TestCase(16, QueryParser.yes, `
query h {
	name
		builds
	}
`);

	tests ~= TestCase(17, QueryParser.yes, `
	query human($id: H, $limit: lim, $gender: Gen) {
		name
		height
	friends {
		id
		gender
		income
	}
	}` );

	tests ~= TestCase(18, QueryParser.yes, `
	query human($id: Var) {
		name
		height
	}`);

	tests ~= TestCase(19, QueryParser.yes, `
	query human() {
		name
		height
	}`);

	tests ~= TestCase(20, QueryParser.yes, `
	query name {
		foo
}`);

	/*tests ~= TestCase(21, `{
		query n {
	__type(name: "User") {
		name
		fields {
			name
			type {
				name
			}
		}
	}
}
}`);*/

	tests ~= TestCase(21, QueryParser.yes, `{
user(id: 1) {
	friends {
		name
	}
}
}`);

	tests ~= TestCase(22, QueryParser.yes, `query IntrospectionQueryTypeQuery {
					__schema {
						queryType {
							fields {
								name
								args {
									name
									description
									type {
										name
										kind
										ofType {
											name
											kind
										}
									}
									defaultValue
								}
							}
						}
					}
				}`);

	tests ~= TestCase(23, QueryParser.yes, `query IntrospectionDroidFieldsQuery {
					__type(name: "Droid") {
						name
						fields {
							name
							type {
								name
								kind
							}
						}
					}
				}`);

	tests ~= TestCase(24, QueryParser.yes, `
				query IntrospectionCharacterKindQuery {
					__type(name: "Character") {
						name
						kind
					}
				}`);


	tests ~= TestCase(25, QueryParser.yes, `query IntrospectionDroidKindQuery {
					__type(name: "Droid") {
						name
						kind
					}
				}`);

	tests ~= TestCase(26, QueryParser.yes, `query IntrospectionDroidTypeQuery {
					__type(name: "Droid") {
						name
					}
				}`);

	tests ~= TestCase(27, QueryParser.yes, `query IntrospectionQueryTypeQuery {
					__schema {
						queryType {
							name
						}
					}
				}`);

	tests ~= TestCase(28, QueryParser.yes, `query IntrospectionTypeQuery {
					__schema {
						types {
							name
						}
					}
				}`);

	tests ~= TestCase(29, QueryParser.yes,
			`query IntrospectionDroidDescriptionQuery {
					__type(name: "Droid") {
						name
						description
					}
				}`);

	// Issue 20
	tests ~= TestCase(30, QueryParser.yes,
			`# a stupid comment that crashed Steven's tests
			# more comments
			query IntrospectionDroidDescriptionQuery {
					__type(name: "Droid") {
						name
						description
					}
				}`);

	tests ~= TestCase(31, QueryParser.yes,
`# Welcome to GraphiQL
#
# GraphiQL is an in-browser tool for writing, validating, and
# testing GraphQL queries.
#
# Type queries into this side of the screen, and you will see intelligent
# typeaheads aware of the current GraphQL type schema and live syntax and
# validation errors highlighted within the text.
#
# GraphQL queries typically start with a "{" character. Lines that starts
# with a # are ignored.
#
# An example GraphQL query might look like:
#
#		 {
#			 field(arg: "value") {
#				 subField
#			 }
#		 }
#
# Keyboard shortcuts:
#
#	Prettify Query:	Shift-Ctrl-P (or press the prettify button above)
#
#			 Run Query:	Ctrl-Enter (or press the play button above)
#
#	 Auto Complete:	Ctrl-Space (or just start typing)
#


{allEmployees
{
	info
	{
		addressInstance
		{
			line1
		}
	}
}}
			`);
	tests ~= TestCase(32, QueryParser.yes,
`query IntrospectionDroidFieldsQuery {
	__typenameA
	__type(name: "Droid") {
		name
		fields {
			name
			type {
				name
				kind
			}
		}
	}
}`);

	tests ~= TestCase(33, QueryParser.no, `
"""
Autogenerated input type of ApproveDeployments
"""
input ApproveDeploymentsInput {
  """
  A unique identifier for the client performing the mutation.
  """
  clientMutationId: String

  """
  Optional comment for approving deployments
  """
  comment: String = ""

  """
  The ids of environments to reject deployments
  """
  environmentIds: [ID!]!

  """
  The node ID of the workflow run containing the pending deployments.
  """
  workflowRunId: ID! @possibleTypes(concreteTypes: ["WorkflowRun"])
}
`);

	tests ~= TestCase(34, QueryParser.no, `
type TestType {
  input: String!
  type: String!
  query: String!
}

input TestInput {
  input: String!
  type: String!
  query: String!
}
`);

	tests ~= TestCase(35, QueryParser.yes, `
query {
  input
  type
  query
}
`);

	tests ~= TestCase(36, QueryParser.yes, `
mutation m {
	update(id: 1, patch: {}) @dir(arg: {}) {
		id
	}
}
`);

	tests ~= TestCase(37, QueryParser.yes, `
query q($a: Int = 1, $o: In = {}) {
	f(list: [{x: 1}, {x: {}} {}], objs: [[{}], {}], obj: {x: {y: {}}}) {
		g
	}
}
`);

	tests ~= TestCase(38, QueryParser.yes, `
mutation removeItem($itemId: ID!) {
	removeItems(input: {itemIds: [$itemId]}) {
		ok
	}
}
`);

	tests ~= TestCase(39, QueryParser.yes, `
query q($a: Int, $b: Int) {
	f(list: [$a], list2: [1, $a, 2 $b], nested: [[$a], [], [[$b, 3]]]) {
		g @dir(arg: [$a, {x: [$b]}])
	}
}
`);

	tests ~= TestCase(40, QueryParser.yes, `
query q($a: Int) {
	f(list: [{x: $a}, {x: [$a]} {}], objs: [{x: [{y: [$a]}]}, $a]) {
		g
	}
}
`);

	foreach(test; tests) {
		auto l = Lexer(test.str, test.qp);
		auto p = Parser(l);
		try {
			auto d = p.parseDocument();
		} catch(Throwable e) {
			writeln(e.toString());
			while(e.next) {
				writeln(e.next.toString());
				e = e.next;
			}
			assert(false, format("Test %d", test.id));
		}
		assert(p.lex.empty, format("%d %s", test.id, p.lex.getRestOfInput()));
	}
}

unittest {
	enum ok = {
		auto l = Lexer(`
mutation updateUser($userId: String! $name: String!) {
	updateUser(id: $userId name: $name) {
		name
	}
}
`, QueryParser.yes);
		auto p = Parser(l);
		auto d = p.parseDocument();
		assert(p.lex.empty, format("%s", p.lex.getRestOfInput()));
		return true;
	}();
	static assert(ok);
}

unittest {
	import std.file : readText;
	auto l = Lexer(readText("starwarsschemaparsetest.graphql"), QueryParser.no);
	auto p = Parser(l);
	auto a = p.parseDocument();
}

unittest {
	import graphql.ast;

	auto l = Lexer(`{ f(obj: {}, nested: {x: {}}) }`, QueryParser.yes);
	auto p = Parser(l);
	auto d = p.parseDocument();
	assert(p.lex.empty, format("%s", p.lex.getRestOfInput()));

	auto args = d.defs.def.op.ss.sel.sel.field.args.arg;

	auto obj = args.arg;
	assert(obj.name.value == "obj");
	assert(obj.vv.ruleSelection == ValueOrVariableEnum.Val);
	assert(obj.vv.val.ruleSelection == ValueEnum.O);
	assert(obj.vv.val.obj.ruleSelection == ObjectTypeEnum.Empty);
	assert(obj.vv.val.obj.vals is null);

	auto nested = args.follow.arg;
	assert(nested.name.value == "nested");
	auto x = nested.vv.val.obj.vals;
	assert(nested.vv.val.obj.ruleSelection == ObjectTypeEnum.Var);
	assert(x.name.value == "x");
	assert(x.follow is null);
	assert(x.val.val.ruleSelection == ValueEnum.O);
	assert(x.val.val.obj.ruleSelection == ObjectTypeEnum.Empty);
}

unittest {
	foreach(str; [`{ f(a: {x}) }`, `{ f(a: {x: }) }`, `{ f(a: {]) }`,
			`{ f(a: {) }`])
	{
		auto l = Lexer(str, QueryParser.yes);
		auto p = Parser(l);
		bool failed;
		try {
			p.parseDocument();
		} catch(Exception e) {
			failed = true;
		}
		assert(failed, str);
	}
}

unittest {
	import graphql.ast;

	auto l = Lexer(`
query q($a: Int, $b: Int) {
	f(list: [1, $a, [$b], {x: $a}])
}
`, QueryParser.yes);
	auto p = Parser(l);
	auto d = p.parseDocument();
	assert(p.lex.empty, format("%s", p.lex.getRestOfInput()));

	auto arg = d.defs.def.op.ss.sel.sel.field.args.arg.arg;
	assert(arg.name.value == "list");
	assert(arg.vv.ruleSelection == ValueOrVariableEnum.Val);
	assert(arg.vv.val.ruleSelection == ValueEnum.ARR);
	assert(arg.vv.val.arr.ruleSelection == ArrayEnum.Value);

	ValueOrVariable[] elements;
	for(Values v = arg.vv.val.arr.vals; v !is null; v = v.follow) {
		elements ~= v.val;
	}
	assert(elements.length == 4, format("%s", elements.length));

	// 1
	assert(elements[0].ruleSelection == ValueOrVariableEnum.Val);
	assert(elements[0].val.ruleSelection == ValueEnum.INT);
	assert(elements[0].val.tok.value == "1");

	// $a
	assert(elements[1].ruleSelection == ValueOrVariableEnum.Var);
	assert(elements[1].var.name.value == "a");

	// [$b]
	assert(elements[2].ruleSelection == ValueOrVariableEnum.Val);
	assert(elements[2].val.ruleSelection == ValueEnum.ARR);
	auto inner = elements[2].val.arr.vals;
	assert(inner.ruleSelection == ValuesEnum.Val);
	assert(inner.val.ruleSelection == ValueOrVariableEnum.Var);
	assert(inner.val.var.name.value == "b");

	// {x: $a}
	assert(elements[3].ruleSelection == ValueOrVariableEnum.Val);
	assert(elements[3].val.ruleSelection == ValueEnum.O);
	assert(elements[3].val.obj.vals.name.value == "x");
	assert(elements[3].val.obj.vals.val.ruleSelection
			== ValueOrVariableEnum.Var);
	assert(elements[3].val.obj.vals.val.var.name.value == "a");
}

unittest {
	foreach(str; [`{ f(a: [$x }`, `{ f(a: [$]) }`, `{ f(a: [$1]) }`,
			`{ f(a: [}) }`])
	{
		auto l = Lexer(str, QueryParser.yes);
		auto p = Parser(l);
		bool failed;
		try {
			p.parseDocument();
		} catch(Exception e) {
			failed = true;
		}
		assert(failed, str);
	}
}

unittest {
	import graphql.ast;

	// Enum values which are keywords (other than true, false and null)
	auto l = Lexer("enum E {\n  type\n  input\n  \"d\" enum\n  name\n}\n", QueryParser.no);
	auto p = Parser(l);
	auto d = p.parseDocument();
	assert(p.lex.empty, p.lex.getRestOfInput());
	string[] names;
	EnumValueNameEnum[] rules;
	for(auto vals = d.defs.def.type.td.etd.evds; vals !is null;
			vals = vals.follow)
	{
		names ~= vals.evd.name.tok.value;
		rules ~= vals.evd.name.ruleSelection;
	}
	assert(names == ["type", "input", "enum", "name"], format("%s", names));
	assert(rules == [EnumValueNameEnum.Type, EnumValueNameEnum.Input,
			EnumValueNameEnum.Enum, EnumValueNameEnum.I],
		format("%s", rules));

	foreach(str; ["enum E { true }", "enum E { false }", "enum E { null }"]) {
		auto l2 = Lexer(str, QueryParser.no);
		auto p2 = Parser(l2);
		bool failed;
		try {
			p2.parseDocument();
		} catch(Exception e) {
			failed = true;
		}
		assert(failed, str);
	}
}
