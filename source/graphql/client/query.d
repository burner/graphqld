/// Building blocks for type-safe GraphQL queries.
module graphql.client.query;

import graphql.client.document;
import graphql.client.codegen : toD, CodeGenerationSettings, toDLiteral;
import graphql.lexer;
import graphql.parser;

public import graphql.client.codegen : GraphQLSettings, SerializationLibraries;

/// Represents a parsed GraphQL schema, an object which can serve
/// as a base for building GraphQL queries.
struct GraphQLSchema(alias document_, GraphQLSettings settings_) {
	alias document = document_;
	alias settings = settings_;

	enum code = {
		const CodeGenerationSettings settings = {
			graphqlSettings: this.settings,
			schemaRefExpr: q{},
		};
		return toD(document, settings);
	}();

	mixin(code);

	template query(string queryText_) {
		static immutable queryText = queryText_;
		enum query = GraphQLQuery!(typeof(this), queryText).init;
	}
}

struct GraphQLQuery(GraphQLSchema, alias queryText_) {
	alias queryText = queryText_;
	static const document = {
		auto l = Lexer(queryText, QueryParser.yes);
		auto p = Parser(l);
		auto d = p.parseDocument();

		return QueryDocument(d);
	}();

	mixin({
		const CodeGenerationSettings settings = {
			graphqlSettings: GraphQLSchema.settings,
			schemaRefExpr: q{GraphQLSchema.},
		};
		return toD(document, GraphQLSchema.document, settings);
	}());
}

enum isQueryInstance(T) =
	is(T.Query == GraphQLQuery!(GraphQLSchema, queryText), GraphQLSchema, string queryText);

/// Parses a GraphQL schema at compile-time, returning a
/// compile-time-accessible representation of the schema.
auto graphqlSchema(
	alias/*string*/ schemaText,
	GraphQLSettings settings = GraphQLSettings()
)() {
	static const document = {
		auto l = Lexer(schemaText, QueryParser.no);
		auto p = Parser(l);
		auto d = p.parseDocument();

		return SchemaDocument(d);
	}();
    return GraphQLSchema!(document, settings)();
}

// Basic ReturnType test
unittest {
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
unittest {
	static immutable schema = graphqlSchema!`
		type User {
			id: ID!
			name: String!
			age: Int!
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
	static assert(!is(typeof(op.Query.ReturnType.updateUser.age)));
}


// Test arrays and (non-)nullables
unittest {
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

// Test implicit operation type
unittest {
	static immutable schema = graphqlSchema!`
		type Query {
			i: Int!
		}
	`;

	immutable query = schema.query!`{ i }`;

	static assert(is(typeof(query.ReturnType.i) == int));
	static assert(isQueryInstance!(typeof(query())));
}

// Test __typename
unittest {
	static immutable schema = graphqlSchema!`
        type S {
            i: Int
        }

		type Query {
            s: S!
		}
	`;

	immutable query = schema.query!`{
        __typename
        s {
            __typename
        }
    }`;

	static assert(is(typeof(query.ReturnType.__typename) == string));
	static assert(is(typeof(query.ReturnType.s.__typename) == string));
}

// Test schema type generation
unittest {
	static immutable schema = graphqlSchema!`
        type S {
			str: String!
            next: S
        }
	`;

	static assert(is(typeof(schema.Schema.S.init.str) == string));
	static assert(is(typeof(schema.Schema.S.init.next) == schema.Schema.S));
}

// Test schema type construction
unittest {
	import std.typecons : nullable;

	static immutable schema = graphqlSchema!`
        type S {
			str: String!
            next: S
        }
	`;

	auto s = new schema.Schema.S(
		str: "first",
		next: new schema.Schema.S(
			str: "second"
		)
	);
}

// Test types with interfaces
unittest {
	static immutable schema = graphqlSchema!`
		interface Node {
			nodeId: ID!
		}
        type SomeNode implements Node {
			nodeId: ID!
        }
        type Query {
			someNode: SomeNode!
        }
	`;

	static assert(is(typeof(schema.Schema.SomeNode.init.nodeId) == string));

	immutable query = schema.query!`{
        someNode {
            nodeId
        }
    }`;

	static assert(is(typeof(query.ReturnType.someNode.nodeId) == string));
}

/// Parses `schemaText` as a GraphQL schema, and returns a string containing
/// D code for the parsed schema.  The resulting code should be pasted into
/// a struct definition.
string toDStruct(string schemaText, GraphQLSettings settings = GraphQLSettings()) {
	const document = {
		auto l = Lexer(schemaText, QueryParser.no);
		auto p = Parser(l);
		auto d = p.parseDocument();

		return SchemaDocument(d);
	}();

	CodeGenerationSettings codeGenSettings;
	codeGenSettings.graphqlSettings = settings;
	codeGenSettings.schemaRefExpr = q{};

	return "
		private static import graphql.ast;
		private static import graphql.client.codegen;
		private static import graphql.client.document;
		private static import graphql.client.query;

		static const document = " ~ document.toDLiteral() ~ ";
		static const settings = " ~ settings.toDLiteral() ~ ";

		" ~ toD(document, codeGenSettings) ~ "

		template query(string queryText_) {
			static immutable queryText = queryText_;
			enum query = graphql.client.query.GraphQLQuery!(typeof(this), queryText).init;
		}
	";
}

// Test ahead-of-time code generation
unittest {
	enum code = toDStruct(`
		type Query {
			hello: String!
		}
	`);

	static struct schema { mixin(code); }

	immutable query = schema.query!`
		query {
			hello
		}
	`;

	static assert(is(typeof(query.ReturnType.hello) == string));
}

// Test settings serialisation
unittest {
	enum code = toDStruct(`
        scalar Date
		type Query {
			today: Date!
		}
	`, GraphQLSettings(
		customScalars: [
			GraphQLSettings.CustomScalar(
				graphqlType: "Date",
				dType: q{.imported!q{std.datetime.date}.Date},
				transformations: [
					q{.imported!q{std.datetime.date}.Date.fromISOExtString},
					q{(x => x.toISOExtString())},
				],
			),
		],
	));

	static import std.datetime.date;
	static struct schema { mixin(code); }

	immutable query = schema.query!`
		query {
			today
		}
	`;

	static assert(is(typeof(query.ReturnType.today) == std.datetime.date.Date));
}
