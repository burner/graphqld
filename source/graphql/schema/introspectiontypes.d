module graphql.schema.introspectiontypes;

import std.meta : AliasSeq;
import std.typecons : Nullable;

import nullablestore;

import graphql.uda;

alias IntrospectionTypes = AliasSeq!(__TypeKind, __DirectiveLocation,
		__Directive, __EnumValue, __InputValue, __Field, __Type, __Schema);

struct __Schema {
	__Type[] types;
	__Type queryType;
	Nullable!__Type mutationType;
	Nullable!__Type subscriptionType;
	__Directive[] directives;

	@GQLDUda(Ignore.yes)
	string toString() const {
		return "__Schema";
	}
}

struct __Type {
	__TypeKind kind;
	Nullable!string name;
	Nullable!string description;

	// OBJECT and INTERFACE only
	Nullable!(__Field[]) fields(bool includeDeprecated = false);

	// OBJECT only
	Nullable!(__Type[]) interfaces;

	// INTERFACE and UNION only
	Nullable!(__Type[]) possibleTypes;

	// ENUM only
	Nullable!(__EnumValue[]) enumValues(bool includeDeprecated = false);

	// INPUT_OBJECT only
	Nullable!(__InputValue[]) inputFields;

	// NON_NULL and LIST only
	NullableStore!(__Type) ofType;

	@GQLDUda(Ignore.yes)
	string toString() const {
		return "__Type";
	}
}

struct __Field {
	string name;
	Nullable!string description;
	__InputValue[] args;
	__Type type;
	bool isDeprecated;
	Nullable!string deprecationReason;

	@GQLDUda(Ignore.yes)
	string toString() const {
		return "__Field";
	}
}

struct __InputValue {
	string name;
	Nullable!string description;
	NullableStore!__Type type; // TODO should not be NullableStore
	Nullable!string defaultValue;

	@GQLDUda(Ignore.yes)
	string toString() const {
		return "__InputValue";
	}
}

struct __EnumValue {
	string name;
	Nullable!string description;
	bool isDeprecated;
	Nullable!string deprecationReason;

	@GQLDUda(Ignore.yes)
	string toString() const {
		return "__EnumValue";
	}
}

enum __TypeKind {
	SCALAR,
	OBJECT,
	INTERFACE,
	UNION,
	ENUM,
	INPUT_OBJECT,
	LIST,
	NON_NULL
}

struct __Directive {
	string name;
	Nullable!string description;
	__DirectiveLocation[] locations;
	__InputValue[] args;

	@GQLDUda(Ignore.yes)
	string toString() const {
		return "__Directive";
	}
}

enum __DirectiveLocation {
	QUERY,
	MUTATION,
	SUBSCRIPTION,
	FIELD,
	FRAGMENT_DEFINITION,
	FRAGMENT_SPREAD,
	INLINE_FRAGMENT,
	SCHEMA,
	SCALAR,
	OBJECT,
	FIELD_DEFINITION,
	ARGUMENT_DEFINITION,
	INTERFACE,
	UNION,
	ENUM,
	ENUM_VALUE,
	INPUT_OBJECT,
	INPUT_FIELD_DEFINITION
}
