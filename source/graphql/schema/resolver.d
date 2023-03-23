module graphql.schema.resolver;

import std.array : array, empty;
import std.conv : to;
import std.algorithm.iteration : map;
import std.format : format;
import std.meta;
import std.traits;
import std.typecons : Nullable;
import std.stdio;
import std.string : capitalize, strip;

import vibe.data.json;

import graphql.schema.types;
import graphql.schema.typeconversions;
import graphql.helper;
import graphql.traits;
import graphql.constants;
import graphql.graphql;
import graphql.reflection;

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
							op.parameters[paraNames[idx]] =
								typeToGQLDType!(paraTypes[idx])(ret);
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
	if(GQLDNonNull nn = toNonNull(type)) {
		return "NON_NULL";
	} else if(GQLDList l = toList(type)) {
		return "LIST";
	} else if(GQLDString l = toString(type)) {
		return "STRING";
	} else if(GQLDFloat l = toFloat(type)) {
		return "FLOAT";
	} else if(GQLDInt l = toInt(type)) {
		return "INT";
	} else if(GQLDEnum l = toEnum(type)) {
		return "ENUM";
	} else if(GQLDBool l = toBool(type)) {
		return "BOOL";
	} else if(GQLDObject l = toObject(type)) {
		return "OBJECT";
	} else if(GQLDUnion l = toUnion(type)) {
		return "UNION";
	} else if(GQLDQuery l = toQuery(type)) {
		return "QUERY";
	} else if(GQLDMutation l = toMutation(type)) {
		return "MUTATION";
	} else if(GQLDSubscription l = toSubscription(type)) {
		return "SUBSCRIPTION";
	} else if(GQLDOperation l = toOperation(type)) {
		return "OPERATION";
	} else if(GQLDScalar l = toScalar(type)) {
		return "SCALAR";
	} else if(GQLDMap l = toMap(type)) {
		return "SCALAR";
	}
	throw new Exception("Unhandled type " ~ type.toString());
}

Json fieldToJson(GQLDType type) {
	Json ret = emptyType();
	ret[Constants.isDeprecated] = type.deprecatedInfo.isDeprecated;
	ret[Constants.deprecationReason] = type.deprecatedInfo.deprecationReason;
	ret["kind"] = "TYPE";
	ret[Constants.__typename] = "__Field";
	ret["name"] = type.name;
	ret["fields"] = Json(null);

	if(GQLDNonNull nn = toNonNull(type)) {
		ret["kind"] = "NON_NULL";
		ret["ofType"] = toJson(nn.elementType);
		ret["name"] = nn.name;
		return ret;
	} else if(GQLDList l = toList(type)) {
		ret["kind"] = "LIST";
		ret["ofType"] = toJson(l.elementType);
		ret["name"] = l.name;
		return ret;
	}
	return ret;
}

Json toJson(GQLDType type) {
	Json ret = emptyType();
	ret[Constants.isDeprecated] = type.deprecatedInfo.isDeprecated;
	ret[Constants.deprecationReason] = type.deprecatedInfo.deprecationReason;
	ret["kind"] = "TYPE";
	ret[Constants.__typename] = "__Type";
	ret["name"] = type.name;
	ret["fields"] = Json(null);

	if(GQLDNonNull nn = toNonNull(type)) {
		ret["kind"] = "NON_NULL";
		ret["ofType"] = toJson(nn.elementType);
		ret["name"] = nn.name;
		return ret;
	} else if(GQLDList l = toList(type)) {
		ret["kind"] = "LIST";
		ret["ofType"] = toJson(l.elementType);
		ret["name"] = l.name;
		return ret;
	} else if(GQLDOperation o = toOperation(type)) {
		ret["kind"] = o.name;
		ret["ofType"] = toJson(o.returnType);
		ret["name"] = o.name;
		ret["fields"] = o.toMap() !is null
			? Json(o.toMap().member.byKeyValue()
				.map!(it => it.value.fieldToJson())
				.array)
			: Json(null);
		return ret;
	}

	return ret;
}

void setDefaultSchemaResolver(T, Con)(GraphQLD!(T,Con) graphql) {
	writeln("\n\nOOOOO");
	foreach(p; graphql.schema.types.byKeyValue()) {
		writefln("%s %s", p.key, p.value);
	}
	writeln("OOOOO\n\n");

	graphql.setResolver("queryType", "__type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				Json ret = Json.emptyObject();
				Json t = Json.emptyObject();
				string typeName;
				if(Constants.name in args) {
					typeName = args[Constants.name].get!string();
				}
				if(Constants.typenameOrig in parent) {
					typeName = parent[Constants.typenameOrig].get!string();
				} else if(Constants.name in parent) {
					typeName = parent[Constants.name].get!string();
				}

				if(typeName.empty) {
					ret.insertError("No typename found to look for");
					return ret;
				}
				typeName = typeName.strip("'");

				GQLDType* type = typeName in graphql.schema.types;
				if(type is null) {
					ret.insertError(format("No type for typename '%s' found\n"
							~ "available %(%s, %)"
							, typeName, graphql.schema.types.byKey()));
					return ret;
				}
				//writefln("%s %s", __LINE__, *type);

				GQLDType typeNN = *type;
				ret["name"] = typeNN.name;
				ret["kind"] = typeNN.kind.to!string();
				ret["fields"] = typeNN.toMap() !is null
					? Json(typeNN.toMap().member.byKeyValue()
						.map!(it => it.value.fieldToJson())
						.array)
					: Json(null);

				Json ts = Json.emptyObject();
				ts["data"] = ret;
				//writefln("%s %s", __LINE__, ts.toPrettyString());

				return ts;
			}
		);


	graphql.setResolver("__Field", "type",
		delegate(string name, Json parent, Json args, ref Con context) @safe
		{
			writefln("%s %s", __LINE__, parent.toString());
			Json r = Json.emptyObject();
			if(parent.type == Json.Type.object && "ofType" in parent) {
				r["data"] = parent["ofType"];
			} else {
				r["data"] = Json(null);
			}
			writefln("%s %s\n", __LINE__, r["data"]);
			return r;
		}
	);
}

/*
void setDefaultSchemaResolver(T, Con)(GraphQLD!(T,Con) graphql) {

	static Json typeResolverImpl(Type)(ref const(StringTypeStrip) stripType,
			Json parent, GraphQLD!(T,Con) graphql)
	{
		Json ret = Json.emptyObject();
		const bool inner = stripType.innerNotNull;
		const bool outer = stripType.outerNotNull;
		const bool arr = stripType.arr;

		if(inner && outer && arr) {
			alias PassType = RemoveInout!(Type)[];
			ret["data"] = typeToJson!(PassType,T)();
		} else if(!inner && outer && arr) {
			static if(!is(Type == void)) {
				alias PassType = Nullable!(RemoveInout!(Type))[];
				ret["data"] = typeToJson!(PassType,T)();
			} else {
				ret.insertError(format("invalid type %s in %s",
							Type.stringof,
							parent.toPrettyString()));
			}
		} else if(inner && !outer && arr) {
			alias PassType = Nullable!(RemoveInout!(Type)[]);
			ret["data"] = typeToJson!(PassType,T)();
		} else if(!inner && !outer && arr) {
			static if(!is(type == void)) {
				alias PassType = Nullable!(Nullable!(RemoveInout!(Type))[]);
				ret["data"] = typeToJson!(PassType,T)();
			} else {
				ret.insertError(format("invalid type %s in %s",
							Type.stringof,
							parent.toPrettyString()));
			}
		} else if(!inner && !arr) {
			static if(!is(Type == void)) {
				alias PassType = Nullable!(RemoveInout!(Type));
				ret["data"] = typeToJson!(PassType,T)();
			} else {
				ret.insertError(format("invalid type %s in %s",
							Type.stringof,
							parent.toPrettyString()));
			}
		} else if(inner && !arr) {
			alias PassType = RemoveInout!(Type);
			ret["data"] = typeToJson!(PassType,T)();
		} else {
			assert(false, format("%s", stripType));
		}
		graphql.defaultResolverLog.logf("%s %s", stripType.str, ret["data"]);
		return ret;
	}

	alias ResolverFunction =
		Json function(ref const(StringTypeStrip), Json, GraphQLD!(T,Con)) @safe;

	static ResolverFunction[string] handlers;

	if(handlers is null) {
		static void processType(type)(ref ResolverFunction[string] handlers) {
			static if(!is(type == void)) {
				enum typeConst = typeToTypeName!(type);
				handlers[typeConst] = &typeResolverImpl!(type);
			}
		}

		execForAllTypes!(T, processType)(handlers);

		foreach(t; AliasSeq!(__Type, __Field, __InputValue,
				__EnumValue, __TypeKind, __Directive, __DirectiveLocation))
		{
			 handlers[t.stringof] = &typeResolverImpl!t;
		}
	}

	auto typeResolver = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			graphql.defaultResolverLog.logf(
					"TTTTTTRRRRRRR name %s args %s parent %s", name, args,
					parent);
			Json ret = Json.emptyObject();
			string typeName;
			if(Constants.name in args) {
				typeName = args[Constants.name].get!string();
			}
			if(Constants.typenameOrig in parent) {
				typeName = parent[Constants.typenameOrig].get!string();
			} else if(Constants.name in parent) {
				typeName = parent[Constants.name].get!string();
			}
			string typeCap;
			string old;
			StringTypeStrip stripType;
			if(typeName.empty) {
				ret.insertError("unknown type");
				goto retLabel;
			} else {
				typeCap = typeName;
				old = typeName;
			}
			stripType = typeCap.stringTypeStrip();
			graphql.defaultResolverLog.logf("%s %s", __LINE__, stripType);

			if(auto h = stripType.str in handlers) {
				ret = (*h)(stripType, parent, graphql);
			}
			retLabel:
			//graphql.defaultResolverLog.logf("%s", ret.toPrettyString());
			graphql.defaultResolverLog.logf("TTTTT____RRRR %s",
					ret.toPrettyString());
			return ret;
		};

	QueryResolver!(Con) schemaResolver = delegate(string _unused, Json parent,
			Json args, ref Con context) @safe
		{
			//logf("%s %s %s", name, args, parent);
			StringTypeStrip stripType;
			Json ret = Json.emptyObject();
			ret["data"] = Json.emptyObject();
			ret["data"]["types"] = Json.emptyArray();
			ret["data"]["types"] ~=
				typeResolverImpl!(__Type)(stripType, parent, graphql)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__Field)(stripType, parent, graphql)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__InputValue)(stripType, parent, graphql)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__EnumValue)(stripType, parent, graphql)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__TypeKind)(stripType, parent, graphql)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__Directive)(stripType, parent, graphql)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__DirectiveLocation)(stripType, parent,
														graphql)["data"];

			Json jsonTypes;
			jsonTypes = Json.emptyArray;
			static if(hasMember!(T, Constants.directives)) {
				import graphql.schema.typeconversions : typeToTypeName;
				immutable string directiveTypeName =
			   	   typeToTypeName!(typeof(__traits(getMember, T,
												   Constants.directives)));
			} else {
				immutable string directiveTypeName = "";
			}
			foreach(n, ref tsn; SchemaReflection!T.instance.jsonTypes) {
				if(n != directiveTypeName && tsn.canonical)
					jsonTypes ~= tsn.typeJson.clone;
			}
			ret["data"]["types"] ~= jsonTypes;
			static if(hasMember!(T, Constants.directives)) {
				ret["data"][Constants.directives] =
					directivesToJson!(typeof(
							__traits(getMember, T, Constants.directives)
						));
			}

			static foreach(tName; ["subscriptionType",
					"queryType", "mutationType"])
			{
				static if(hasMember!(T, tName)) {
					ret["data"][tName] =
						typeToJsonImpl!(typeof(__traits(getMember, T, tName)),
								T, typeof(__traits(getMember, T, tName)));
				}
			}
			graphql.defaultResolverLog.logf("%s", ret.toPrettyString());
			return ret;
		};

	graphql.setResolver("queryType", "__type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("%s %s %s", name, parent, args);
				Json tr = typeResolver(name, parent, args, context);
				Json ret = Json.emptyObject();
				ret["data"] = tr["data"];
				graphql.defaultResolverLog.logf("%s %s", tr.toPrettyString(),
						ret.toPrettyString());
				return ret;
			}
		);

	graphql.setResolver("queryType", "__schema", schemaResolver);

	graphql.setResolver("__Field", "type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = typeResolver(name, parent, args, context);
				graphql.defaultResolverLog.logf("FIELDDDDD TYPPPPPE %s",
						ret.toPrettyString()
					);
				return ret;
			}
		);

	graphql.setResolver("__InputValue", "type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("%s %s %s", name, parent, args);
				Json tr = typeResolver(name, parent, args, context);
				Json ret = Json.emptyObject();
				Json d = tr["data"];
				ret["data"] = d;
				graphql.defaultResolverLog.logf("%s %s", tr.toPrettyString(),
						ret.toPrettyString()
					);
				return ret;
			}
		);

	graphql.setResolver("__Type", "ofType",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				Json ofType;
				if(parent.hasPathTo("ofType", ofType)) {
					ret["data"] = ofType;
				} else {
					ret["data"] = Json(null);
				}
				graphql.defaultResolverLog.logf("%s", ret);
				return ret;
			}
		);

	graphql.setResolver("__Type", "interfaces",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				ret["data"] = Json.emptyObject();
				if("kind" in parent
						&& parent["kind"].get!string() == "OBJECT")
				{
					ret["data"] = Json.emptyArray();
				}
				if("interfacesNames" !in parent) {
					return ret;
				}
				Json interNames = parent["interfacesNames"];
				if(interNames.type == Json.Type.array) {
					if(interNames.length > 0) {
						assert(ret["data"].type == Json.Type.array,
								format("%s", parent.toPrettyString())
							);
						ret["data"] = Json.emptyArray();
						foreach(Json it; interNames.byValue()) {
							string typeName = it.get!string();
							string typeCap = capitalize(typeName);
							if(auto v = typeCap in
							   SchemaReflection!T.instance.jsonTypes)
							{
								ret["data"] ~= v.typeJson.clone;
								graphql.defaultResolverLog.logf("%s %s", typeCap, v.name);
							}
						}
					}
				}
				graphql.defaultResolverLog.logf("__Type.interfaces result %s",
						ret
					);
				return ret;
			}
		);

	graphql.setResolver("__Type", "possibleTypes",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				if("possibleTypesNames" !in parent) {
					ret["data"] = Json(null);
					return ret;
				}
				Json pTypesNames = parent["possibleTypesNames"];
				if(pTypesNames.type == Json.Type.array) {
					graphql.defaultResolverLog.log();
					ret["data"] = Json.emptyArray();
					foreach(Json it; pTypesNames.byValue()) {
						string typeName = it.get!string();
						string typeCap = capitalize(typeName);
						if(auto v = typeCap in
						   SchemaReflection!T.instance.jsonTypes)
						{
							graphql.defaultResolverLog.logf("%s %s",
															typeCap, v.name);
							ret["data"] ~= v.typeJson.clone;
						}
					}
				} else {
					graphql.defaultResolverLog.log();
					ret["data"] = Json(null);
				}
				return ret;
			}
		);
}
*/
