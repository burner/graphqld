module parsertests;

import std.format : format;
import std.experimental.allocator;
import std.experimental.allocator.mallocator : Mallocator;
import std.stdio;

import lexer;
import parser;

private struct TestCase {
	int id;
	string str;
}

unittest {
	TestCase[] tests;
	tests ~= TestCase(0, 
	`
mutation updateUser($userId: String! $name: String!) {  
  updateUser(id: $userId name: $name) {
    name
  }
}
`);

	tests ~= TestCase(1,`
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

	tests ~= TestCase(2, `
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

	tests ~= TestCase(3, `
mutation CreateReviewForEpisode($ep: Episode!, $review: ReviewInput!) {
  createReview(episode: $ep, review: $review) {
    stars
    commentary
  }
}
`);

	tests ~= TestCase(4, `
query HeroNameAndFriends($episode: Episode = "JEDI") {
  hero(episode: $episode) {
    name
    friends {
      name
    }
  }
}`);

	tests ~= TestCase(5, `
query  hero {
    name
    # Queries can have comments!

    # Queries can have comments Another!
    friends {
      name
    }
}`);

	tests ~= TestCase(6, `
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

	tests ~= TestCase(7, `
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

	tests ~= TestCase(8, `
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

	tests ~= TestCase(9, `type Person {
  name: String
  age: Int
  picture: Url
}`);

	tests ~= TestCase(10, `
query myQuery($someTest: Boolean) {
  experimentalField @skip(if: $someTest)
}`);

	tests ~= TestCase(11, `
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

	tests ~= TestCase(11, `
query HeroNameAndFriends($episode: Episode) {
  hero(episode: $episode) {
    name,
    friends {
      name
    }
  }
}`);

	tests ~= TestCase(12, `
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

	tests ~= TestCase(13, `
query name{
 builds(first: 54) {
	all: number
 }
}
`);

	tests ~= TestCase(14, `
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

	tests ~= TestCase(15, `
query foo {
	name
    builds(first: 1) {
		abc
  }
 }`);

	tests ~= TestCase(16, `
query h {
	name
    builds
  }
`);

	tests ~= TestCase(17, `
  query human($id: H, $limit: lim, $gender: Gen) {
    name
    height
	friends {
		id
		gender
		income
	}
  }` );

	tests ~= TestCase(18, `
  query human($id: Var) {
    name
    height
  }`);

	tests ~= TestCase(19, `
  query human() {
    name
    height
  }`);

	tests ~= TestCase(20, `
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

	tests ~= TestCase(21, `{
 user(id: 1) {
   friends {
     name
   }
 }
}`);

	tests ~= TestCase(22, `query IntrospectionQueryTypeQuery {
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

	tests ~= TestCase(23, `query IntrospectionDroidFieldsQuery {
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

	tests ~= TestCase(24, `
        query IntrospectionCharacterKindQuery {
          __type(name: "Character") {
            name
            kind
          }
        }`);


	tests ~= TestCase(25, `query IntrospectionDroidKindQuery {
          __type(name: "Droid") {
            name
            kind
          }
        }`);

	tests ~= TestCase(26, `query IntrospectionDroidTypeQuery {
          __type(name: "Droid") {
            name
          }
        }`);

	tests ~= TestCase(27, `query IntrospectionQueryTypeQuery {
          __schema {
            queryType {
              name
            }
          }
        }`);

	tests ~= TestCase(28, `query IntrospectionTypeQuery {
          __schema {
            types {
              name
            }
          }
        }`);

	tests ~= TestCase(29, `query IntrospectionDroidDescriptionQuery {
          __type(name: "Droid") {
            name
            description
          }
        }`);

	foreach(test; tests) {
		auto l = Lexer(test.str);
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
		assert(p.lex.empty, format("%d", test.id));
	}
}
