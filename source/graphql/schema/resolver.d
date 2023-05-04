module graphql.schema.resolver;

import std.array : array, assocArray, empty;
import std.conv : to;
import std.algorithm.iteration : filter, map, uniq;
import std.algorithm.searching : canFind, startsWith;
import std.algorithm.sorting : sort;
import std.exception : enforce;
import std.format : format;
import std.meta;
import std.traits;
import std.typecons : Nullable, tuple;
import std.stdio;
import std.string : capitalize, strip;

import vibe.data.json;

import graphql.constants;
import graphql.exception;
import graphql.graphql;
import graphql.helper;
import graphql.schema.typeconversions;
import graphql.schema.types;
import graphql.traits;
import graphql.uda;
import graphql.schema.introspectiontypes;

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
	ret.typeKind = TypeKind.OBJECT;

	static foreach(qms; ["queryType", "mutationType", "subscriptionType"]) {{
		static if(__traits(hasMember, Type, qms)) {
			alias QMSType = typeof(__traits(getMember, Type, qms));
			GQLDMap cur = toMap(typeToGQLDType!(QMSType)(ret, false));
			cur.name = qms;
			cur.member["fields"] = ret.__type.member[Constants.fields];
			cur.member["name"] = ret.__nnStr;
			ret.member[qms] = cur;
			ret.member[QMSType.stringof] = cur;
			ret.types[qms] = cur;
			ret.types[QMSType.stringof] = cur;
			ret.__schema.member[qms] = cur;
			ret.__schema.member[QMSType.stringof] = cur;
			if(qms == "queryType") {
				ret.types["__schema"] = ret.__schema;
				cur.member["__schema"] = ret.__schema;
				cur.member["__type"] = ret.__typeIntrospection;
				ret.__schema.member["__schema"] = ret.__schema;
				ret.__schema.member["__type"] = ret.__typeIntrospection;
			}
		}
	}}
	foreach(key, value; ret.types) {
		writefln("%s %s", key, value.typeKind);
	}

	writefln("__type %s", ret.__type.typeKind);
	writefln("__field %s", ret.__field.typeKind);
	writefln("__inputValue %s", ret.__inputValue.typeKind);
	writefln("__enumValue %s", ret.__enumValue.typeKind);
	writefln("__directives %s", ret.__directives.typeKind);
	writefln("__typeIntrospection %s", ret.__typeIntrospection.typeKind);
	writefln("__nonNullType %s", ret.__nonNullType.typeKind);
	writefln("__nullableType %s", ret.__nullableType.typeKind);
	writefln("__listOfNonNullType %s", ret.__listOfNonNullType.typeKind);
	writefln("__nonNullListOfNonNullType %s", ret.__nonNullListOfNonNullType.typeKind);
	writefln("__nonNullField %s", ret.__nonNullField.typeKind);
	writefln("__listOfNonNullField %s", ret.__listOfNonNullField.typeKind);
	writefln("__nonNullInputValue %s", ret.__nonNullInputValue.typeKind);
	writefln("__listOfNonNullInputValue %s", ret.__listOfNonNullInputValue.typeKind);
	writefln("__nonNullListOfNonNullInputValue %s", ret.__nonNullListOfNonNullInputValue.typeKind);
	writefln("__listOfNonNullEnumValue %s", ret.__listOfNonNullEnumValue.typeKind);
	writefln("__nnStr %s", ret.__nnStr.typeKind);
	return ret;
}

private template RemoveInout(T) {
	static if (is(T == inout V, V)) {
	    alias RemoveInout = V;
	} else {
	    alias RemoveInout = T;
	}
}

private Json toJsonInputValue(GQLDType field, string argsName) {
	//writefln("%s %s", field.name, field.udaData);
	Json ret = Json.emptyObject();
	ret["__typename"] = "__InputValue";
	ret["__gqldTypeName"] = field.name;
	ret["name"] = argsName;
	ret["description"] = field.udaData.description.getText();
	ret["defaultValue"] = Json(null);
	if(GQLDList l = toList(field)) {
		ret["type"] = toJsonType(l, "type");
	} else if(GQLDNullable n = toNullable(field)) {
		ret["type"] = toJsonType(n.elementType, "type");
	} else if(GQLDNonNull n = toNonNull(field)) {
		ret["type"] = toJsonType(n, "type");
	}
	return ret;
}

private Json toJsonField(GQLDType field, string fieldName) {
	Json ret = Json.emptyObject();
	ret["__typename"] = "__Field";
	ret["name"] = fieldName;
	ret["description"] = field.udaData.description.getText();
	ret["__gqldTypeName"] = field.name;
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
		ret = toJsonField(n.elementType, fieldName);
		if(ret.type == Json.Type.object && "description" in ret
				&& ret["description"].get!string() == "")
		{
			ret["description"] = field.udaData.description.getText();
		}
		//ret["type"] = toJsonType(n, "type");
	} else if(GQLDNonNull n = toNonNull(field)) {
		ret["type"] = toJsonType(n, "type");
	}
	return ret;
}

private string typeKindToString(GQLDType type) {
	final switch(type.udaData.typeKind) {
		case TypeKind.UNDEFINED: {
			if(GQLDNonNull nn = toNonNull(type)) {
				return "NON_NULL";
			} else if(GQLDList l = toList(type)) {
				return "LIST";
			} else if(GQLDString l = toString(type)) {
				return "SCALAR";
			} else if(GQLDFloat l = toFloat(type)) {
				return "SCALAR";
			} else if(GQLDInt l = toInt(type)) {
				return "SCALAR";
			} else if(GQLDEnum l = toEnum(type)) {
				return "ENUM";
			} else if(GQLDBool l = toBool(type)) {
				return "SCALAR";
			} else if(GQLDObject l = toObject(type)) {
				return "OBJECT";
			} else if(GQLDUnion l = toUnion(type)) {
				return "UNION";
			} else if(GQLDQuery l = toQuery(type)) {
				return "QUERY";
			} else if(GQLDMutation l = toMutation(type)) {
				return "OBJECT";
			} else if(GQLDSubscription l = toSubscription(type)) {
				return "OBJECT";
			} else if(GQLDOperation l = toOperation(type)) {
				return "OBJECT";
			} else if(GQLDScalar l = toScalar(type)) {
				return "SCALAR";
			} else if(GQLDMap l = toMap(type)) {
				return "SCALAR";
			}
			return "UNDEFINED";
		}
		case TypeKind.SCALAR: return "SCALAR";
		case TypeKind.OBJECT: return "OBJECT";
		case TypeKind.INTERFACE: return "INTERFACE";
		case TypeKind.UNION: return "UNION";
		case TypeKind.ENUM: return "ENUM";
		case TypeKind.INPUT_OBJECT: return "INPUT_OBJECT";
		case TypeKind.LIST: return "LIST";
		case TypeKind.NON_NULL: return "NON_NULL";
	}
}

private Json toJsonType(GQLDType type, string into = "ofType") {
	Json ret = emptyType();
	ret[Constants.isDeprecated] = type.deprecatedInfo.isDeprecated;
	ret[Constants.deprecationReason] = type.deprecatedInfo.deprecationReason;
	ret[Constants.description] = type.udaData.description.getText();
	//ret["kind"] = toKind(type);
	ret["kind"] = typeKindToString(type);
	ret[Constants.__typename] = "__Type";
	ret["name"] = type.name;

	if(GQLDInt i = toInt(type)) {
		ret["kind"] = typeKindToString(i);
		ret["name"] = "Int";
	} else if(GQLDFloat i = toFloat(type)) {
		ret["kind"] = typeKindToString(i);
		ret["name"] = "Float";
	} else if(GQLDEnum i = toEnum(type)) {
		ret["kind"] = typeKindToString(i);
		ret["name"] = i.name;
	} else if(GQLDNonNull nn = toNonNull(type)) {
		ret["kind"] = typeKindToString(nn);
		ret[into] = toJsonType(nn.elementType);
		//ret["name"] = nn.elementType.name;
		ret["name"] = Json(null);
	} else if(GQLDList l = toList(type)) {
		ret["kind"] = typeKindToString(l);
		ret[into] = toJsonType(l.elementType);
		if(GQLDNullable nn = toNullable(l.elementType)) {
			ret["name"] = Json(null);
		} else {
			ret["name"] = l.elementType.name;
		}
	} else if(GQLDNullable l = toNullable(type)) {
		ret["kind"] = typeKindToString(l.elementType);
		ret[into] = toJsonType(l.elementType);
		if(GQLDNullable nn = toNullable(l.elementType)) {
			ret["name"] = Json(null);
		} else {
			ret["name"] = l.elementType.name;
		}
		//ret["name"] = l.elementType.name;
		//ret["name"] = Json(null);
	} else if(GQLDOperation o = toOperation(type)) {
		//ret["kind"] = toKind(o);
		ret["kind"] = typeKindToString(o);
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
	auto fieldsResolver = delegate(string name, Json parent, Json args, ref Con context) @safe
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
				Json[string] fields = m.member.byKeyValue
					.filter!(kv => !kv.key.startsWith("__"))
					.filter!(kv => !canFind(["Query", "Mutation", "Subscription"], kv.key))
					.map!(kv => tuple(kv.key, toJsonField(kv.value, kv.key)))
					.assocArray;

				GQLDObject obj = toObject(m);
				if(obj !is null && obj.base !is null) {
					foreach(kv; obj.base.member.byKeyValue
							.filter!(kv => !kv.key.startsWith("__"))
							.filter!(kv => !canFind(["Query", "Mutation", "Subscription"], kv.key)))
					{
						if(kv.key !in fields) {
							fields[kv.key] = toJsonField(kv.value, kv.key);
						}
					}
				}
				ret["data"] = fields.byValue.array.Json();
				//foreach(key, value; m.member) {
				//	ret["data"] ~= toJsonField(value, key);
				//}
			} else {
				ret["data"] = Json(null);
			}
			return ret;
		};

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

	graphql.setResolver("queryType", "fields", fieldsResolver);

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

	graphql.setResolver("__Type", "fields", fieldsResolver);

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
			writefln("sub is null %s", type is null);
			Json ret = Json.emptyObject();
			ret["data"] = type is null
				? Json(null)
				: toJsonType(*type);
			writeln(ret);
			return ret;
		}
	);

	graphql.setResolver("__schema", "types",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			Json ret = Json.emptyObject();
			ret["data"] = graphql.schema.types.byValue
				.filter!(it => it.name != "__schema")
				.array
				.sort!((a, b) => a.name < b.name)
				.uniq!((a, b) => a.name == b.name)
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
