/// Building blocks for type-safe GraphQL queries.
module graphql.client.query;

import graphql.client.document;
import graphql.client.codegen : toD, CodeGenerationSettings;
import graphql.lexer;
import graphql.parser;

public import graphql.client.codegen : SerializationLibraries;

struct GraphQLSettings
{
	SerializationLibraries serializationLibraries;
}

/// Represents a parsed GraphQL schema, an object which can serve
/// as a base for building GraphQL queries.
struct GraphQLSchema(alias document_, GraphQLSettings settings_)
{
	alias document = document_;
	alias settings = settings_;

	enum code = {
		CodeGenerationSettings settings;
		settings.serializationLibraries = this.settings.serializationLibraries;
		settings.schemaRefExpr = q{};
		return toD(document, settings);
	}();

	mixin(code);

	template query(string queryText_)
	{
		static immutable queryText = queryText_;
		enum query = GraphQLQuery!(typeof(this), queryText).init;
	}
}

struct GraphQLQuery(GraphQLSchema, alias queryText_)
{
	alias queryText = queryText_;
	static const document = {
		auto l = Lexer(queryText, QueryParser.yes);
		auto p = Parser(l);
		auto d = p.parseDocument();

		return QueryDocument(d);
	}();

	mixin({
		CodeGenerationSettings settings;
		settings.serializationLibraries = GraphQLSchema.settings.serializationLibraries;
		settings.schemaRefExpr = q{GraphQLSchema.};
		return toD(document, GraphQLSchema.document, settings);
	}());
}

/// Parses a GraphQL schema at compile-time, returning a
/// compile-time-accessible representation of the schema.
auto graphqlSchema(
	alias/*string*/ schemaText,
	GraphQLSettings settings = GraphQLSettings()
)()
{
	static const document = {
		auto l = Lexer(schemaText, QueryParser.no);
		auto p = Parser(l);
		auto d = p.parseDocument();

		return SchemaDocument(d);
	}();
    return GraphQLSchema!(document, settings)();
}

// Basic ReturnType test
unittest
{
	static immutable schema = graphqlSchema!`
		type Query {
			hello: String!
		}
	`;

	immutable query = schema.query!`
		query {
			hello
		}
	`;

	static assert(is(typeof(query.ReturnType.hello) == string));
}

// Variables test
unittest
{
	static immutable schema = graphqlSchema!`
		type User {
			id: ID!
			name: String!
		}

		type Mutation {
			updateUser(id: ID!, name: String!): User!
		}
	`;

	immutable updateUser = schema.query!`
		mutation($id: ID!, $name: String!) {
			updateUser(id: $id, name: $name) {
				id
				name
			}
		}
	`;

	// We want to be able to write something like:
	//
	// auto client = new VibeHttpGraphQLClient("http://.../graphql");
	// client.call(updateUser(id: "1", name: "John Doe"))
	//     .updateUser.name
	//     .writefln!"Name changed to %s";

	auto op = updateUser(id: "1", name: "John Doe");
	static assert(is(typeof(op.variables.name) == string));
	static assert(is(typeof(op.Query.ReturnType.updateUser.name) == string));
}


// Test arrays and (non-)nullables
unittest
{
	import std.typecons : Nullable;

	static immutable schema = graphqlSchema!`
		type Foo {
			i: Int!
		}

		type Query {
			v: Int!
			vn: Int
			va: [Int!]!
			vna: [Int]!
			van: [Int!]
			vnan: [Int]

			s: Foo!
			sn: Foo
			sa: [Foo!]!
			sna: [Foo]!
			san: [Foo!]
			snan: [Foo]
		}
	`;

	immutable query = schema.query!`
		query {
			v
			vn
			va
			vna
			van
			vnan

			s { i }
			sn { i }
			sa { i }
			sna { i }
			san { i }
			snan { i }
		}
	`;

	static assert(is(typeof(query.ReturnType.v) == int));
	static assert(is(typeof(query.ReturnType.vn.get()) == int));
	static assert(is(typeof(query.ReturnType.va[0]) == int));
	static assert(is(typeof(query.ReturnType.vna[0].get()) == int));
	static assert(is(typeof(query.ReturnType.van.get()[0]) == int));
	static assert(is(typeof(query.ReturnType.vnan.get()[0].get()) == int));

	static assert(is(typeof(query.ReturnType.s.i) == int));
	static assert(is(typeof(query.ReturnType.sn.get().i) == int));
	static assert(is(typeof(query.ReturnType.sa[0].i) == int));
	static assert(is(typeof(query.ReturnType.sna[0].get().i) == int));
	static assert(is(typeof(query.ReturnType.san.get()[0].i) == int));
	static assert(is(typeof(query.ReturnType.snan.get()[0].get().i) == int));
}


// unittest
// {
// 	static immutable schema = graphqlSchema!(import("schema.graphql"));
// }
