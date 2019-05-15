module testqueries;

import std.typecons : Flag;

alias ShouldThrow = Flag!"ShouldThrow";

struct TestQuery {
	string query;
	ShouldThrow st;
}

TestQuery[] queries = [
TestQuery(`
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
`, ShouldThrow.no)
,
TestQuery(`
query a {
  starships(overSize: 10) {
    name
    crew {
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
}
`, ShouldThrow.no),
TestQuery(`
{
  starships
}
`, ShouldThrow.yes),
TestQuery(`
{
  starships {
    designation
    name
    size
  }

  starship(id: 44) {
    designation
  }
  currentTime
}

`, ShouldThrow.no),
TestQuery(`
query a {
  __type(name: "Starship") {
		...FullType
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type {
    ...TypeRef
  }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
`, ShouldThrow.no),
TestQuery(`
{
	shipsselection(ids:[42,45]) {
    id
    commander {
      name
    }
    __typename
    designation
  }
}
`, ShouldThrow.no),
TestQuery(`
mutation one {
  addCrewman(input: {name: "Robert", shipId: 44, series: [Enterprise, DeepSpaceNice]}) {
    id
    name
    ship {
      id
      designation
    }
  }
}
`, ShouldThrow.no)
];
