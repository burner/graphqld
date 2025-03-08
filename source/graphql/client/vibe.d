/// Vibe.d HTTP GraphQL client
module graphql.client.vibe;

import vibe.data.json;
import vibe.http.client;
import vibe.stream.operations : readAllUTF8;

import graphql.client.query : isQueryInstance;

@safe:

final class VibeHttpGraphQLClient {
	string url;
	string[string] headers;

	this(string url, string[string] headers = null) {
		this.url = url;
		this.headers = headers;
	}

	private Json callImpl(string query, Json variables, string[string] requestHeaders) {
		Json body = Json.emptyObject;
		body["query"] = query;
		body["variables"] = variables;

		Json result;
		requestHTTP(url,
			(scope req) {
				req.method = HTTPMethod.POST;
				req.headers["Content-Type"] = "application/json";
				foreach (key, value; this.headers) {
					req.headers[key] = value;
				}
				foreach (key, value; requestHeaders) {
					req.headers[key] = value;
				}

				req.writeJsonBody(body);
			},
			(scope res) {
				result = res.bodyReader.readAllUTF8().parseJsonString();
			}
		);
		return result;
	}

	struct Error {
		string message;
		struct Location {
			int line;
			int column;
		}
		@optional Location[] locations;
		@optional Json[] path;
		@optional Json[string] extensions;
	}

	static class GraphQLException : Exception {
		Error[] errors;
		this(Error[] errors) in(errors.length > 0) {
			this.errors = errors;
			super(errors[0].message);
		}
	}

	QueryInstance.Query.ReturnType call(QueryInstance)(
		QueryInstance queryInstance,
		string[string] headers = null,
	) if (isQueryInstance!QueryInstance) {
		struct Response {
			@optional QueryInstance.Query.ReturnType data;
			@optional Error[] errors;
		}

		auto response = callImpl(
			queryInstance.Query.queryText,
			queryInstance.variables.serializeToJson(),
			headers
		).deserializeJson!Response;

		if (response.errors.length > 0) {
			throw new GraphQLException(response.errors);
		}

		return response.data;
	}
}

unittest {
	if (false) { // Test instantiation only
		import graphql.client.query : graphqlSchema;

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

		auto client = new VibeHttpGraphQLClient("http://.../graphql");
		auto newName = client.call(updateUser(id: "1", name: "John Doe"))
		    .updateUser.name;
		static assert(is(typeof(newName) == string));
	}
}
