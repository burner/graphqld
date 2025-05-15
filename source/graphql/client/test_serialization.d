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
			ni: Int
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
			auto q = query(new schema.Schema.TestInput().i(42));
			assert(serialize(q.variables) == `{"input":{"i":42}}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query.Variables)(`{"input":{"i":42,"ni":43}}`);
			assert(v.input.i == 42);
			assert(v.input.ni.get.get == 43);
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
	static immutable GraphQLSettings.CustomScalar scalarDefinition = {
		graphqlType: "Data",
		dType: q{ubyte[]},
		transformations: [
			GraphQLSettings.CustomScalar.Direction.serialization:
				q{.imported!"std.base64".Base64.encode},
			GraphQLSettings.CustomScalar.Direction.deserialization:
				q{.imported!"std.base64".Base64.decode},
		]
	};
	static immutable GraphQLSettings settings = {
		serializationLibraries: {
			vibe_data_json: true,
			ae_utils_json: true,
		},
		customScalars: [
			scalarDefinition,
		],
	};

	static immutable schema = graphqlSchema!(`
		scalar Data

		interface ITest {
			d: Data!
		}

		type Test implements ITest {
			d: Data!
		}

		input TestInput {
			d: Data!
			nd: Data
		}

		type Query {
			field(input: TestInput!): Test!
		}
	`, settings);

	immutable query1 = schema.query!`
		query($input: TestInput!) {
			field(input: $input) {
				d
			}
		}
	`;

	immutable query2 = schema.query!`
		query($data: Data!) {
			field(input: { d: $data }) {
				d
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
			auto q = query1(new schema.Schema.TestInput()
				.d(cast(ubyte[])x"01 02 03 04"),
			);
			assert(serialize(q.variables) == `{"input":{"d":"AQIDBA=="}}`);
		}
		{
			auto q = query2(cast(ubyte[])x"01 02 03 04");
			assert(serialize(q.variables) == `{"data":"AQIDBA=="}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query1.Variables)(`{"input":{"d":"AQIDBA=="}}`);
			assert(v.input.d == x"01 02 03 04");
		}}

		// Return types
		{
			query1.ReturnType r = {
				field: {
					d: [0x01, 0x02, 0x03, 0x04]
				}
			};
			assert(serialize(r) == `{"field":{"d":"AQIDBA=="}}`);
		}
		static if (testExtras) {{
			auto v = deserialize!(query1.ReturnType)(`{"field":{"d":"AQIDBA=="}}`);
			assert(v.field.d == [0x01, 0x02, 0x03, 0x04]);
		}}

		// Object types
		static if (testExtras) {{
			auto t = new schema.Schema.Test(d: [0x01, 0x02, 0x03, 0x04]);
			assert(serialize(t) == `{"d":"AQIDBA=="}`);
		}}
		static if (testExtras) {{
			auto v = deserialize!(schema.Schema.Test)(`{"d":"AQIDBA=="}`);
			assert(v.d == [0x01, 0x02, 0x03, 0x04]);
		}}

		// Test serialization of null objects
		{
			// Input types and variables
			{
				auto q = query1(null);
				assert(serialize(q.variables) == `{"input":null}`);
			}
			// Object types
			static if (testExtras) {{
				schema.Schema.Test t = null;
				assert(serialize(t) == `null`);
			}}
		}
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

// Enums test
unittest {
	static immutable GraphQLSettings settings = {
		serializationLibraries: {
			vibe_data_json: true,
			ae_utils_json: true,
		},
	};

	static immutable schema = graphqlSchema!(`
		enum Test {
			FOO
			BAR
		}
	`, settings);
}
