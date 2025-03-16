/// Tests for serialization and deserialization using supported JSON libraries.
module graphql.client.test_serialization_vibe;

import graphql.client.query;

// Basic test
unittest {
	static immutable GraphQLSettings settings = {
		serializationLibraries: {
			vibe_data_json: true,
			ae_utils_json: true,
		},
	};

	static immutable schema = graphqlSchema!(`
		type Test {
			i: Int!
		}

		input TestInput {
			i: Int!
			absent: Int
		}

		type Query {
			field(input: TestInput!): Test!
		}
	`, settings);

	immutable query = schema.query!`
		query($input: TestInput!) {
			field(input: $input) {
				i
			}
		}
	`;

	void test(
		alias serialize,
		alias deserialize,
		bool testExtras // Test features not needed for a minimal GraphQL client
	)() {
		// Input types and variables
		{
			auto q = query(new schema.Schema.TestInput(q{i}, 42));
			assert(serialize(q.variables) == `{"input":{"i":42}}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query.Variables)(`{"input":{"i":42}}`);
			assert(v.input.i == 42);
		}}

		// Return types
		{
			query.ReturnType r = {
				field: {
					i: 42
				}
			};
			assert(serialize(r) == `{"field":{"i":42}}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query.ReturnType)(`{"field":{"i":42}}`);
			assert(v.field.i == 42);
		}}

		// Object types
		static if (testExtras) {{
			auto t = new schema.Schema.Test(i: 42);
			assert(serialize(t) == `{"i":42}`);
		}}
		static if (testExtras) {{
			auto v = deserialize!(schema.Schema.Test)(`{"i":42}`);
			assert(v.i == 42);
		}}
	}

	{
		import vibe.data.json;
		test!(
			x => serializeToJson(x).toString(),
			deserializeJson,
			true
		)();
	}

	{
		import ae.utils.json;
		test!(
			toJson,
			jsonParse,
			false, // TODO: Finish ae support (needs classes)
		)();
	}
}

// Custom scalars test
unittest {
	static immutable GraphQLSettings.ScalarTransformation dateScalarDefinition = {
		dType: q{.imported!"std.datetime.date".Date},
		transformations: [
			GraphQLSettings.ScalarTransformation.Direction.serialization:
				q{(x => x.toISOExtString())},
			GraphQLSettings.ScalarTransformation.Direction.deserialization:
				q{.imported!"std.datetime.date".Date.fromISOExtString},
		]
	};
	static immutable GraphQLSettings settings = {
		serializationLibraries: {
			vibe_data_json: true,
			ae_utils_json: true,
		},
		customScalars: [
			"Date": dateScalarDefinition,
		],
	};

	static immutable schema = graphqlSchema!(`
		scalar Date

		type Test {
			d: Date!
		}

		input TestInput {
			d: Date!
		}

		type Query {
			field(input: TestInput!): Test!
		}
	`, settings);

	immutable query = schema.query!`
		query($input: TestInput!) {
			field(input: $input) {
				d
			}
		}
	`;

	import std.datetime.date : Date;

	void test(
		alias serialize,
		alias deserialize,
		bool testExtras // Test features not needed for a minimal GraphQL client
	)() {
		// Input types and variables
		{
			auto q = query(new schema.Schema.TestInput(
				q{d}, Date(2020, 01, 01),
			));
			assert(serialize(q.variables) == `{"input":{"d":"2020-01-01"}}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query.Variables)(`{"input":{"d":"2020-01-01"}}`);
			assert(v.input.d == Date(2020, 01, 01));
		}}

		// Return types
		{
			query.ReturnType r = {
				field: {
					d: Date(2020, 01, 01)
				}
			};
			assert(serialize(r) == `{"field":{"d":"2020-01-01"}}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query.ReturnType)(`{"field":{"d":"2020-01-01"}}`);
			assert(v.field.d == Date(2020, 01, 01));
		}}

		// Object types
		static if (testExtras) {{
			auto t = new schema.Schema.Test(d: Date(2020, 01, 01));
			assert(serialize(t) == `{"d":"2020-01-01"}`);
		}}
		static if (testExtras) {{
			auto v = deserialize!(schema.Schema.Test)(`{"d":"2020-01-01"}`);
			assert(v.d == Date(2020, 01, 01));
		}}
	}

	{
		import vibe.data.json;
		test!(
			x => serializeToJson(x).toString(),
			deserializeJson,
			true
		)();
	}

	{
		import ae.utils.json;
		test!(
			toJson,
			jsonParse,
			false, // TODO: Finish ae support (needs classes)
		)();
	}
}
