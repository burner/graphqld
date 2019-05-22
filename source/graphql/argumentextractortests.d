module graphql.argumentextractortests;

import vibe.data.json;

import graphql.ast;
import graphql.helper : lexAndParse;
import graphql.argumentextractor;
import graphql.testschema;
import graphql.graphql;

unittest {
	string q = `
query a($s: boolean) {
  starships(overSize: 10) {
    name
    crew @skip(if: $s) {
      ...hyooman
      ...robot
      ...charac
    }
  }
}

fragment hyooman on Humanoid {
  species
  dateOfBirth
}

fragment robot on Android {
  primaryFunction
}

fragment charac on Character {
  ...robot
  id
  ...hyooman
  name
  series
}`;

	Json vars = parseJsonString(`{ "s": false }`);

	Document doc = cast()lexAndParse(q);
	assert(doc !is null);

	auto gql = new GraphQLD!Schema();
}
