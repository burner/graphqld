module graphql.starwars.validation;

import std.typecons : Nullable, nullable;
import std.format : format;
import std.experimental.logger;
import std.exception;
import std.stdio;

import vibe.data.json;

import graphql.validation.exception;
import graphql.constants;
import graphql.parser;
import graphql.builder;
import graphql.lexer;
import graphql.ast;
import graphql.graphql;
import graphql.helper;
import graphql.starwars.data;
import graphql.starwars.schema;
import graphql.starwars.types;
import graphql.validation.querybased;
import graphql.validation.schemabased;

@safe:

void test(string s) {
	auto graphqld = new GraphQLD!(StarWarsSchema);
	auto l = Lexer(s);
	auto p = Parser(l);

	Document d = p.parseDocument();
	const(Document) cd = d;
	QueryValidator fv = new QueryValidator(d);
	fv.accept(cd);
	noCylces(fv.fragmentChildren);
	allFragmentsReached(fv);
	SchemaValidator!StarWarsSchema sv = new SchemaValidator!StarWarsSchema(d,
			graphqld.schema
		);
	sv.accept(cd);
	DefaultContext con;
	Json gqld = graphqld.execute(d, Json.emptyObject(), con);
}

@safe unittest {
	assertNotThrown(test(`
		query NestedQueryWithFragment {
			hero {
				...NameAndAppearances
				friends {
					...NameAndAppearances
					friends {
						...NameAndAppearances
					}
				}
			}
		}

		fragment NameAndAppearances on Character {
			name
			appearsIn
		}`));
}

@safe unittest {
	assertThrown!FieldDoesNotExist(test(`
		query HeroSpaceshipQuery {
			hero {
				favoriteSpaceship
			}
		}
		`));
}

@safe unittest {
	assertThrown!FieldDoesNotExist(test(`
		query HeroFieldsOnScalarQuery {
			hero {
				name {
					firstCharacterOfName
				}
			}
		}
		`));
}

@safe unittest {
	assertNotThrown(test(`
				query DroidFieldInFragment {
					hero {
						name
						...DroidFields
					}
				}

				fragment DroidFields on Droid {
					primaryFunction
				}
		`));
}

@safe unittest {
	assertNotThrown(test(`
				query DroidFieldInFragment {
					hero {
						name
						... on Droid {
							primaryFunction
						}
					}
				}
		`));
}
