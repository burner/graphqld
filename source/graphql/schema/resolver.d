module graphql.schema.resolver;

import std.array : array, empty;
import std.conv : to;
import std.algorithm.iteration : filter, map;
import std.algorithm.searching : canFind, startsWith;
import std.exception : enforce;
import std.format : format;
import std.meta;
import std.traits;
import std.typecons : Nullable;
import std.stdio;
import std.string : capitalize, strip;

import vibe.data.json;

import graphql.constants;
import graphql.exception;
import graphql.graphql;
import graphql.helper;
import graphql.reflection;
import graphql.schema.typeconversions;
import graphql.schema.types;
import graphql.traits;
import graphql.uda;

@safe:

alias QueryResolver(Con) = Json delegate(string name, Json parent,
		Json args, ref Con context) @safe;

QueryResolver!(Con) buildSchemaResolver(Type, Con)() {
	return ret;
}

QueryResolver!(Con) buildTypeResolver(Type, Con)() {
	return ret;
}

GQLDSchema!(Type) toSchema(Type)() {
	import graphql.uda : getUdaData, Ignore, TypeKind;
	typeof(return) ret = new GQLDSchema!Type();

	static foreach(qms; ["queryType", "mutationType", "subscriptionType"]) {{
		GQLDMap cur = new GQLDObject(qms, TypeKind.OBJECT);
		cur.name = qms;
		ret.member[qms] = cur;
		ret.types[qms] = cur;
		if(qms == "queryType") {
			cur.member["__schema"] = ret.__schema;
			cur.member["__type"] = ret.__nonNullType;
		}
		static if(__traits(hasMember, Type, qms)) {
			alias QMSType = typeof(__traits(getMember, Type, qms));
			static foreach(mem; __traits(allMembers, QMSType)) {{
				enum uda = getUdaData!(QMSType, mem);
				static if(uda.ignore != Ignore.yes) {
					alias MemType = typeof(__traits(getMember, QMSType, mem));
					static if(isCallable!(MemType)) {{
						GQLDOperation op = qms == "queryType"
							? new GQLDQuery()
							: qms == "mutationType" ? new GQLDMutation()
							: qms == "subscriptionType" ? new GQLDSubscription()
							: null;
						cur.member[mem] = op;
						assert(op !is null);
						op.returnType = typeToGQLDType!(ReturnType!(MemType))(
								ret
							);

						alias paraNames = ParameterIdentifierTuple!(
								__traits(getMember, QMSType, mem)
							);
						alias paraTypes = Parameters!(
								__traits(getMember, QMSType, mem)
							);
						static foreach(idx; 0 .. paraNames.length) {
							auto tmp = typeToGQLDType!(paraTypes[idx])(ret);
							op.parameters[paraNames[idx]] = tmp;
						}

					}}
				}
			}}
		}
	}}
	return ret;
}

enum __DirectiveLocation {
	QUERY
	, MUTATION
	, SUBSCRIPTION
	, FIELD
	, FRAGMENT_DEFINITION
	, FRAGMENT_SPREAD
	, INLINE_FRAGMENT
	, SCHEMA
	, SCALAR
	, OBJECT
	, FIELD_DEFINITION
	, ARGUMENT_DEFINITION
	, INTERFACE
	, UNION
	, ENUM
	, ENUM_VALUE
	, INPUT_OBJECT
	, INPUT_FIELD_DEFINITION
}

class __Directive {
	string name;
	Nullable!string description;
	__DirectiveLocation[] locations;
	__InputValue[] args;
}

enum __TypeKind {
	SCALAR
	, OBJECT
	, INTERFACE
	, UNION
	, ENUM
	, INPUT_OBJECT
	, LIST
	, NON_NULL
}

class __EnumValue {
	string name;
	Nullable!string description;
	bool isDeprecated;
	Nullable!string deprecationReason;
}

class __InputValue {
	string name;
	Nullable!string description;
	__Type type;
	Nullable!string defaultValue;
}

class __Field {
	string name;
	Nullable!string description;
	__InputValue[] args;
	__Type type;
	bool isDeprecated;
	Nullable!string deprecationReason;
}

class __Type {
	__TypeKind kind;
	string name;
	Nullable!string description;
	__Field[] fields(bool includeDeprecated = false) { assert(false);
	}
	Nullable!(__Type[]) interfaces;
	Nullable!(__Type[]) possibleTypes;
	Nullable!(__Field[]) enumValues(bool includeDeprecated = false) {
		assert(false);
	}
	Nullable!(__InputValue[]) inputFields;
	Nullable!(__Type) ofType;
}

class __Schema {
	__Type types;
	__Directive directives;
}

private template RemoveInout(T) {
	static if (is(T == inout V, V)) {
	    alias RemoveInout = V;
	} else {
	    alias RemoveInout = T;
	}
}

string toKind(GQLDType type) {
	string ret;
	if(GQLDNonNull nn = toNonNull(type)) {
		ret = "NON_NULL";
	} else if(GQLDNullable l = toNullable(type)) {
		ret ="OBJECT";
	} else if(GQLDList l = toList(type)) {
		ret ="LIST";
	} else if(GQLDString l = toString(type)) {
		ret ="SCALAR";
	} else if(GQLDFloat l = toFloat(type)) {
		ret ="SCALAR";
	} else if(GQLDInt l = toInt(type)) {
		ret ="SCALAR";
	} else if(GQLDEnum l = toEnum(type)) {
		ret ="ENUM";
	} else if(GQLDBool l = toBool(type)) {
		ret ="SCALAR";
	} else if(GQLDScalar l = toScalar(type)) {
		ret ="SCALAR";
	} else if(GQLDObject l = toObject(type)) {
		ret ="OBJECT";
	} else if(GQLDUnion l = toUnion(type)) {
		ret ="UNION";
	} else if(GQLDQuery l = toQuery(type)) {
		ret ="OBJECT";
	} else if(GQLDMutation l = toMutation(type)) {
		ret ="OBJECT";
	} else if(GQLDSubscription l = toSubscription(type)) {
		ret ="OBJECT";
	} else if(GQLDOperation l = toOperation(type)) {
		ret ="OBJECT";
	} else if(GQLDMap l = toMap(type)) {
		ret ="OBJECT";
	}
	enforce(!ret.empty, "Unhandled type " ~ type.toString());
	//writefln("toKind %s %s %s", ret, type.kind, type.toString());
	return ret;
}

private Json toJsonInputValue(GQLDType field, string argsName) {
	Json ret = Json.emptyObject();
	ret["__typename"] = "__InputValue";
	ret["__gqldTypeName"] = field.name;
	ret["name"] = argsName;
	//ret["description"] = field.description;
	ret["defaultValue"] = Json(null);
	ret["description"] = field.description;
	if(GQLDList l = toList(field)) {
		ret["type"] = toJsonType(l, "type");
	} else if(GQLDNullable n = toNullable(field)) {
		ret["type"] = toJsonType(n, "type");
	}
	return ret;
}

private Json toJsonField(GQLDType field, string fieldName) {
	Json ret = Json.emptyObject();
	ret["__typename"] = "__Field";
	ret["name"] = fieldName;
	ret["description"] = field.description;
	ret["__gqldTypeName"] = field.name;
	//ret["description"] = field.description;
	ret["isDeprecated"] = field.deprecatedInfo.isDeprecated == IsDeprecated.yes;
	if(field.deprecatedInfo.isDeprecated == IsDeprecated.yes) {
		ret["deprecationReason"] = field.deprecatedInfo.deprecationReason;
	} else {
		ret["deprecationReason"] = Json(null);
	}
	GQLDOperation op = toOperation(field);
	ret["args"] = Json.emptyArray();
	if(op !is null) {
		foreach(key, value; op.parameters) {
			ret["args"] ~= toJsonInputValue(value, key);
		}
	}
	if(GQLDList l = toList(field)) {
		ret["type"] = toJsonType(l, "type");
	} else if(GQLDNullable n = toNullable(field)) {
		ret["type"] = toJsonType(n, "type");
	}
	return ret;
}

private Json toJsonType(GQLDType type, string into = "ofType") {
	Json ret = emptyType();
	ret[Constants.isDeprecated] = type.deprecatedInfo.isDeprecated;
	ret[Constants.deprecationReason] = type.deprecatedInfo.deprecationReason;
	ret["kind"] = toKind(type);
	ret[Constants.__typename] = "__Type";
	ret["name"] = type.name;

	if(GQLDInt i = toInt(type)) {
		ret["kind"] = "SCALAR";
		ret["name"] = "Int";
	} else if(GQLDFloat i = toFloat(type)) {
		ret["kind"] = "SCALAR";
		ret["name"] = "Float";
	} else if(GQLDNonNull nn = toNonNull(type)) {
		ret["kind"] = "NON_NULL";
		ret[into] = toJsonType(nn.elementType);
		ret["name"] = nn.name;
	} else if(GQLDList l = toList(type)) {
		ret["kind"] = "LIST";
		ret[into] = toJsonType(l.elementType);
		ret["name"] = l.name;
	} else if(GQLDNullable l = toNullable(type)) {
		ret["kind"] = "NULLABLE";
		ret[into] = toJsonType(l.elementType);
		ret["name"] = l.name;
	} else if(GQLDOperation o = toOperation(type)) {
		ret["kind"] = toKind(o);
		ret[into] = toJsonType(o.returnType);
		ret["name"] = o.name;
	}

	return ret;
}

private void enforceGQLD(bool cond, string msg, long line = __LINE__) {
	msg = msg ~ " " ~ to!string(line);
	//if(!cond) {
	//	writeln(msg);
	//}
	enforce!GQLDExecutionException(cond, msg);
}

private Json getJsonForTypeFrom(GQLD)(GQLD graphql, string typename, long line = __LINE__) {
	GQLDType* type = typename in graphql.schema.types;
	enforceGQLD(type !is null, format("No type for typename '%s' found in the Schema"
			, typename), line);
	Json ret = toJsonType(*type);
	return ret;
}

private string getName(Json args, Json parent, string which = "name") {
	if(args.type == Json.Type.object && which in args
			&& args[which].type == Json.Type.string)
	{
		return args[which].get!string();
	} else if(parent.type == Json.Type.object && which in parent
			&& parent[which].type == Json.Type.string)
	{
		return parent[which].get!string();
	}
	return "";
}

void setDefaultSchemaResolver(T, Con)(GraphQLD!(T,Con) graphql) {
	graphql.setResolver("queryType", "__type",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			//writefln("\nqueryType.__type args %s parent %s", args.toPrettyString(),
			//		parent.toPrettyString());
			string typeName;
			if(Constants.name in args) {
				typeName = args[Constants.name].get!string();
			}
			if(Constants.typenameOrig in parent) {
				typeName = parent[Constants.typenameOrig].get!string();
			} else if(Constants.name in parent) {
				typeName = parent[Constants.name].get!string();
			}

			enforceGQLD(!typeName.empty, "No typename found to look for");
			typeName = typeName.strip("'");
			return getJsonForTypeFrom(graphql, typeName);
		}
	);

	graphql.setResolver("__Type", "interfaces",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			//writefln("\n__Type.interfaces args %s parent %s", args.toPrettyString(),
			//		parent.toPrettyString());
			string nameOfType = getName(args, parent);
			enforceGQLD(!nameOfType.empty, format("No __typename in args %s nor parent %s"
					, args.toPrettyString(), parent.toPrettyString()));

			GQLDType* typePtr = nameOfType in graphql.schema.types;
			enforceGQLD(typePtr !is null, format("No type for typename '%s' found in the Schema"
					, nameOfType));

			GQLDType type = *typePtr;
			GQLDMap m = toMap(type);

			Json ret = Json.emptyObject();
			ret["data"] = m is null
				? Json(null)
				: m.derivatives.map!(i => i.toJsonType()).array.Json();
			return ret;
		}
	);

	graphql.setResolver("__Type", "fields",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			//writefln("\n__Type.fields args %s parent %s", args.toPrettyString(),
			//		parent.toPrettyString());
			string nameOfType = getName(args, parent);
			enforceGQLD(!nameOfType.empty, format("No __typename in args %s nor parent %s"
					, args.toPrettyString(), parent.toPrettyString()));

			GQLDType* typePtr = nameOfType in graphql.schema.types;
			enforceGQLD(typePtr !is null, format("No type for typename '%s' found in the Schema"
					, nameOfType));

			GQLDType type = *typePtr;
			GQLDMap m = toMap(type);

			Json ret = Json.emptyObject();
			if(m !is null) {
				ret["data"] = Json.emptyArray();
				ret["data"] = m.member.byKeyValue
					.filter!(kv => !kv.key.startsWith("__"))
					.filter!(kv => !canFind(["Query", "Mutation", "Subscription"], kv.key))
					.map!(kv => toJsonField(kv.value, kv.key))
					.array
					.Json();
				//foreach(key, value; m.member) {
				//	ret["data"] ~= toJsonField(value, key);
				//}
			} else {
				ret["data"] = Json(null);
			}
			return ret;
		}
	);

	graphql.setResolver("__Type", "ofType",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			//writefln("\n__Type.ofType args %s parent %s", args.toPrettyString(),
			//		parent.toPrettyString());
			if(parent.type == Json.Type.object && "ofType" in parent
					&& parent["ofType"].type == Json.Type.object)
			{
				Json ret = Json.emptyObject();
				ret["data"] = parent["ofType"];
				//writefln("__Type.ofType via parent['ofType'] %s", ret.toPrettyString());
				return ret;
			}
			if(parent.type == Json.Type.object && "type" in parent
					&& parent["type"].type == Json.Type.object)
			{
				Json ret = Json.emptyObject();
				ret["data"] = parent["type"];
				//writefln("__Type.ofType via parent['type'] %s", ret.toPrettyString());
				return ret;
			}
			if(parent.type == Json.Type.object && "kind" in parent
					&& parent["kind"].type == Json.Type.string)
			{
				foreach(tt; ["SCALAR", "ENUM"]) {
					if(parent["kind"].get!string() == tt) {
						Json ret = Json.emptyObject();
						ret["data"] = Json(null);
						return ret;
					}
				}
			}

			Json ret = Json.emptyObject();
			string nameOfType = getName(args, parent, "__gqldTypeName");
			if(nameOfType.empty) {
				ret["data"] = Json(null);
				return ret;
			}
			enforceGQLD(!nameOfType.empty, format("No __typename in args %s nor parent %s"
					, args.toPrettyString(), parent.toPrettyString()));

			GQLDType* typePtr = nameOfType in graphql.schema.types;
			enforceGQLD(typePtr !is null, format("No type for typename '%s' found in the Schema"
					, nameOfType));

			GQLDType type = *typePtr;

			ret["data"] = toJsonType(type);
			//writefln("__Type.ofType via __gqldTypeName %s", ret.toPrettyString());
			return ret;
		}
	);

	graphql.setResolver("__Field", "type",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			//writefln("\n__Field.type args %s parent %s", args.toPrettyString(),
			//		parent.toPrettyString());
			string nameOfType = getName(args, parent, "__gqldTypeName");
			//writefln("\n\nname %s %s\n\n", nameOfType, parent);
			if(parent.type == Json.Type.object && "type" in parent
					&& parent["type"].type == Json.Type.object)
			{
				Json ret = Json.emptyObject();
				ret["data"] = parent["type"];
				//writefln("__Field.type via parent %s", ret.toPrettyString());
				return ret;
			}
			/*
			if(nameOfType == "Query") {
				nameOfType = "queryType";
			} else if(nameOfType == "Mutation") {
				nameOfType = "mutationType";
			} else if(nameOfType == "Subscription") {
				nameOfType = "subscriptionType";
			}*/
			return getJsonForTypeFrom(graphql, nameOfType);
		}
	);

	graphql.setResolver("__InputValue", "type",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			//writefln("\n__InputValue.type args %s parent %s", args.toPrettyString(),
			//		parent.toPrettyString());
			if(parent.type == Json.Type.object && "type" in parent
					&& parent["type"].type == Json.Type.object)
			{
				Json ret = Json.emptyObject();
				ret["data"] = parent["type"];
				return ret;
			}
			string nameOfType = getName(args, parent, "__gqldTypeName");
			return getJsonForTypeFrom(graphql, nameOfType);
		}
	);

	graphql.setResolver("__schema", "queryType",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			Json ret = getJsonForTypeFrom(graphql, "queryType");
			return ret;
		}
	);

	graphql.setResolver("__schema", "mutationType",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			GQLDType* type = "mutationType" in graphql.schema.types;
			Json ret = Json.emptyObject();
			ret["data"] = type is null
				? Json(null)
				: toJsonType(*type);
			return ret;
		}
	);

	graphql.setResolver("__schema", "subscriptionType",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			GQLDType* type = "subscriptionType" in graphql.schema.types;
			Json ret = Json.emptyObject();
			ret["data"] = type is null
				? Json(null)
				: toJsonType(*type);
			return ret;
		}
	);

	graphql.setResolver("__schema", "types",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			Json ret = Json.emptyObject();
			ret["data"] = graphql.schema.types.byValue
				.map!(t => toJsonType(t))
				.array
				.Json();
			return ret;
		}
	);

	graphql.setResolver("__schema", "directives",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			Json ret = Json.emptyObject();
			ret["data"] = parseJsonString(`
					[ { "name" : "include", "description": null
					  , "locations" : []
					  , "args" : []
					  }
					, { "name" : "skip", "description": null
					  , "locations" : []
					  , "args" : []
					  }
					]`);
			return ret;
		}
	);
}
