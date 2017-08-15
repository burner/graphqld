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


__EOF__
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
	string s = `
{
query {
	name
    builds(first: 1) {
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
query {
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
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
query {
 all: builds(first: 1) {
       number
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
  query {
  {
    leftComparison: hero(episode: EMPIRE) {
      ...comparisonFields
    }
    rightComparison: hero(episode: JEDI) {
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
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
  __type(name: "User") {
    name
    fields {
      name
      type {
        name
      }
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
}
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
fragment inDirectFieldSelectionOnUnion on CatOrDog {
  __typename
  ... on Pet {
    name
  }
  ... on Dog {
    barkVolume
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
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
}

unittest {
	string s = `{
		query foo ($b, $n: [ bar, args ]) {
			name
		}
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();
	assert(p.lex.empty, format("%s", p.lex.front));
}
