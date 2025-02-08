/// Building blocks for type-safe GraphQL queries.
module graphql.client.query;

import graphql.client.document;
import graphql.client.codegen : toD;
import graphql.lexer;
import graphql.parser;

/// Represents a parsed GraphQL schema, an object which can serve
/// as a base for building GraphQL queries.
struct GraphQLSchema(alias document_)
{
	alias document = document_;

	mixin(toD(document));

	auto query(string queryText)() const
	{
		static const document = {
			auto l = Lexer(queryText, QueryParser.yes);
			auto p = Parser(l);
			auto d = p.parseDocument();

			return QueryDocument(d);
		}();

		return GraphQLQuery!(typeof(this), document)();
	}
}

struct GraphQLQuery(GraphQLSchema, alias document_)
{
	alias document = document_;

	mixin(toD(document, GraphQLSchema.document, q{GraphQLSchema.}));
}

/// Parses a GraphQL schema at compile-time, returning a
/// compile-time-accessible representation of the schema.
auto graphqlSchema(string schemaText)()
{
	static const document = {
		auto l = Lexer(schemaText, QueryParser.no);
		auto p = Parser(l);
		auto d = p.parseDocument();

		return SchemaDocument(d);
	}();
    return GraphQLSchema!document();
}

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
	// updateUser(id: "1", name: "John Doe")
	//     .perform()  // network library (Vibe.d etc.) wrapper
	//     .updateUser.name
	//     .writefln!"Name changed to %s";

	static assert(is(typeof(updateUser.Variables.name) == string));
	static assert(is(typeof(updateUser.ReturnType.updateUser.name) == string));
}

// unittest
// {
// 	static immutable schema = graphqlSchema!(import("schema.graphql"));
// }
