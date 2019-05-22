module graphql.argumentextractortests;

import graphql.ast;
import graphql.helper : lexAndParse;
import graphql.argumentextractor;

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

	Document doc = cast()lexAndParse(q);
	assert(doc !is null);
}
