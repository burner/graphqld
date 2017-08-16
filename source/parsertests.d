module parsertests;

import std.format : format;
import std.experimental.allocator;
import std.experimental.allocator.mallocator : Mallocator;
import std.stdio;

import lexer;
import parser;

unittest {
	string s = 
`{
  query name {
	  foo
  }
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
  query human() {
    name
    height
  }
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
  query human($id: Var) {
    name
    height
  }
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
  query human($id: H, $limit: lim, $gender: Gen) {
    name
    height
	friends {
		id
		gender
		income
	}
  }
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
query h {
	name
    builds
  }
 }
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
query foo {
	name
    builds(first: 1) {
		abc
  }
 }
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
	{
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
	}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
query name{
 builds(first: 54) {
	all: number
 }
}
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
  query name {
    leftComparison: hero(episode: $EMPIRE) {
      ...comparisonFields
    }
    rightComparison: hero(episode: $JEDI) {
      ...comparisonFields
    }
  }
}  
fragment comparisonFields on Character {
  name
  appearsIn
  friends {
    name
  }
}

`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
query HeroNameAndFriends($episode: Episode) {
  hero(episode: $episode) {
    name,
    friends {
      name
    }
  }
}
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

/*unittest {
	string s = `{
		query {
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
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}*/

unittest {
	string s = `{
subscription sub {
  newMessage {
    body
    sender
  }
}
}
fragment newMessageFields on Message {
  body
  sender
}

{
subscription sub {
  newMessage {
    ... newMessageFields  
  }

}}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
query myQuery($someTest: Boolean) {
  experimentalField @skip(if: $someTest)
}
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `type Person {
  name: String
  age: Int
  picture: Url
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty);
}

unittest {
	string s = `
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
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty);
}

unittest {
	string s = `
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
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty, format("%s", p.lex.front));
}

unittest {
	string s = `
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
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty, format("%s", p.lex.front));
}

unittest {
	string s = `{
query  hero {
    name
    # Queries can have comments!

    # Queries can have comments Another!
    friends {
      name
    }
  }
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty);
}

unittest {
	string s = `{
query HeroNameAndFriends($episode: Episode = "JEDI") {
  hero(episode: $episode) {
    name
    friends {
      name
    }
  }
}
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty);
}

unittest {
	string s = `{
mutation CreateReviewForEpisode($ep: Episode!, $review: ReviewInput!) {
  createReview(episode: $ep, review: $review) {
    stars
    commentary
  }
}
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty);
}

unittest {
	string s = `{
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
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty);
}
