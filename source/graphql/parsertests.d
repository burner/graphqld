module graphql.parsertests;

import std.format : format;
import std.experimental.allocator;
import std.experimental.allocator.mallocator : Mallocator;
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

	tests ~= TestCase(2, QueryParser.yes,  `
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

	tests ~= TestCase(3, QueryParser.yes,  `
mutation CreateReviewForEpisode($ep: Episode!, $review: ReviewInput!) {
  createReview(episode: $ep, review: $review) {
    stars
    commentary
  }
}
`);

	tests ~= TestCase(4, QueryParser.yes,  `
query HeroNameAndFriends($episode: Episode = "JEDI") {
  hero(episode: $episode) {
    name
    friends {
      name
    }
  }
}`);

	tests ~= TestCase(5, QueryParser.yes,  `
query hero {
    name
    # Queries can have comments!

    # Queries can have comments Another!
    friends {
      name
    }
}`);

	tests ~= TestCase(6, QueryParser.no,  `
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

	tests ~= TestCase(7, QueryParser.no,  `
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

	tests ~= TestCase(8, QueryParser.no,  `
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
#     {
#       field(arg: "value") {
#         subField
#       }
#     }
#
# Keyboard shortcuts:
#
#  Prettify Query:  Shift-Ctrl-P (or press the prettify button above)
#
#       Run Query:  Ctrl-Enter (or press the play button above)
#
#   Auto Complete:  Ctrl-Space (or just start typing)
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
