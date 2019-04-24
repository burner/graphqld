# GraphqlD: A graphql implementation for the D Programming language

Graphql is a query language for apis.
Given a query like for the schema in folder test.

```
{
  shipsselection(ids:[44,45]) {
    id
    commander {
      name
    }
  }
}
```

You get back json that looks like:
```JS
{
  "error": [],
  "data": {
    "shipsselection": [
      {
        "id": 44,
        "commander": {
          "name": "Kathryn Janeway"
        }
      },
      {
        "id": 45,
        "commander": {
          "name": "Jonathan Archer"
        }
      }
    ]
  }
}
```

Graphiql type-ahead works, this makes schema introspection a lot nicer.

## Features
This graphql implementation is based on June 2018 spec.

### Operation Execution
- [x] Scalars
- [x] Objects
- [x] Lists of objects/interfaces
- [x] Interfaces
- [x] Unions
- [x] Arguments
- [x] Variables
- [x] Fragments
- [x] Directives
  - [ ] Include
  - [ ] Skip
  - [ ] Custom
- [x] Enumerations
- [x] Input Objects
- [x] Mutations
- [ ] Subscriptions (This needs vibe.d websocket integration)
- [ ] Async execution (when used with vibe.d blocking resolver are async by
  default)

### Validation
- [ ] Arguments of correct type
- [ ] Default values of correct type
- [x] Fields on correct type
- [ ] Fragments on composite types
- [ ] Known argument names
- [x] Executable Definition
- [ ] Known directives
- [x] Known fragment names
- [ ] Known type names
- [x] Lone anonymous operations
- [x] No fragment cycles
- [x] No undefined variables
- [x] No unused fragments
- [x] No unused variables
- [ ] Overlapping fields can be merged
- [ ] Possible fragment spreads
- [ ] Provide non-null arguments
- [ ] Scalar leafs
- [x] Unique argument names
- [ ] Unique directives per location
- [x] Unique fragment names
- [ ] Unique input field names
- [x] Unique operation names
- [x] Unique variable names
- [ ] Variables are input types
- [ ] Variables in allowed position
- [x] Single root field

### Schema Introspection
- [x] __typename
- [x] __type
  - [x] name
  - [x] kind
  - [x] description
  - [x] fields
  - [x] interfaces
  - [x] possibleTypes
  - [x] enumValues
  - [x] inputFields
  - [x] ofType
- [x] __schema
  - [x] types
  - [x] queryType
  - [x] mutationType
  - [x] subscriptionType
  - [x] directives

### Comfort Features
- [ ] Query AST cache
- [ ] Json to resolver argument extractor
- [ ] SQL query generation from AST
- [x] Custom Leaf types (e.g. GQLDCustomLeaf!(std.datetime.DateTime))

Thank you to [graphql-dot](https://github.com/graphql-dotnet/graphql-dotnet)
for the excelent list of features

## Documentation
The Documentation is still WIP, please have a look at the vibe.d project in the
test folder.

## Contributing
PRs are welcome!

# About Kaleidic Associates
We are a boutique consultancy that advises a small number of hedge fund clients.  We are
not accepting new clients currently, but if you are interested in working either remotely
or locally in London or Hong Kong, and if you are a talented hacker with a moral compass
who aspires to excellence then feel free to drop me a line: laeeth at kaleidic.io

We work with our partner Symmetry Investments, and some background on the firm can be
found here:

http://symmetryinvestments.com/about-us/
