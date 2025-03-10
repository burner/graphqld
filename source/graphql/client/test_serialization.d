/// Tests for serialization and deserialization using supported JSON libraries.
module graphql.client.test_serialization_vibe;

import graphql.client.query;

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
