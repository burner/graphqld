module graphql.schema.resolver;

import std.array : empty;
import std.format : format;
import std.meta;
import std.traits;
import std.typecons : Nullable;
import std.experimental.logger;
import std.stdio;
import std.string : capitalize;

import vibe.data.json;

import graphql.schema.types;
import graphql.schema.typeconversions;
import graphql.helper;
import graphql.traits;
import graphql.constants;
import graphql.graphql;

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
	typeof(return) ret = new GQLDSchema!Type();

	static foreach(qms; ["queryType", "mutationType", "subscriptionType"]) {{
		GQLDMap cur = new GQLDMap();
		cur.name = qms;
		ret.member[qms] = cur;
		if(qms == "queryType") {
			cur.member["__schema"] = ret.__schema;
			cur.member["__type"] = ret.__nonNullType;
		}
		static if(__traits(hasMember, Type, qms)) {
			alias QMSType = typeof(__traits(getMember, Type, qms));
			static foreach(mem; __traits(allMembers, QMSType)) {{
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

void setDefaultSchemaResolver(T, Con)(GraphQLD!(T,Con) graphql) {

	Json typeResolverImpl(Type)(ref const(StringTypeStrip) stripType,
			Json parent)
	{
		Json ret = Json.emptyObject();
		const bool inner = stripType.innerNotNull;
		const bool outer = stripType.outerNotNull;
		const bool arr = stripType.arr;

		if(inner && outer && arr) {
			alias PassType = Type[];
			ret["data"] = typeToJson!(PassType,T)();
		} else if(!inner && outer && arr) {
			static if(!is(Type == void)) {
				alias PassType = Nullable!(Type)[];
				ret["data"] = typeToJson!(PassType,T)();
			} else {
				ret.insertError(format("invalid type %s in %s",
							Type.stringof,
							parent.toPrettyString()));
			}
		} else if(inner && !outer && arr) {
			alias PassType = Nullable!(Type[]);
			ret["data"] = typeToJson!(PassType,T)();
		} else if(!inner && !outer && arr) {
			static if(!is(type == void)) {
				alias PassType = Nullable!(Nullable!(Type)[]);
				ret["data"] = typeToJson!(PassType,T)();
			} else {
				ret.insertError(format("invalid type %s in %s",
							Type.stringof,
							parent.toPrettyString()));
			}
		} else if(!inner && !arr) {
			static if(!is(Type == void)) {
				alias PassType = Nullable!(Type);
				ret["data"] = typeToJson!(PassType,T)();
			} else {
				ret.insertError(format("invalid type %s in %s",
							Type.stringof,
							parent.toPrettyString()));
			}
		} else if(inner && !arr) {
			alias PassType = Type;
			ret["data"] = typeToJson!(PassType,T)();
		} else {
			assert(false, format("%s", stripType));
		}
		graphql.defaultResolverLog.logf("%s %s", stripType.str, ret["data"]);
		return ret;
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
			static foreach(type; collectTypes!(T)) {{
				enum typeConst = typeToTypeName!(type);
				if(stripType.str == typeConst) {
					static if(!is(type == void)) {
						ret = typeResolverImpl!(type)(stripType, parent);
						goto retLabel;
					}
				} else {
					graphql.defaultResolverLog.logf("||||||||||| %s %s",
							stripType.str, typeConst
						);
				}
			}}
			if(stripType.str == "__Type") {
				ret = typeResolverImpl!(__Type)(stripType, parent);
			} else if(stripType.str == "__Field") {
				ret = typeResolverImpl!(__Field)(stripType, parent);
			} else if(stripType.str == "__InputValue") {
				ret = typeResolverImpl!(__InputValue)(stripType, parent);
			} else if(stripType.str == "__EnumValue") {
				ret = typeResolverImpl!(__EnumValue)(stripType, parent);
			} else if(stripType.str == "__TypeKind") {
				ret = typeResolverImpl!(__TypeKind)(stripType, parent);
			} else if(stripType.str == "__Directive") {
				ret = typeResolverImpl!(__Directive)(stripType, parent);
			} else if(stripType.str == "__DirectiveLocation") {
				ret = typeResolverImpl!(__DirectiveLocation)(stripType, parent);
			}
			retLabel:
			//graphql.defaultResolverLog.logf("%s", ret.toPrettyString());
			graphql.defaultResolverLog.logf("TTTTT____RRRR %s",
					ret.toPrettyString());
			return ret;
		};

	QueryResolver!(Con) schemaResolver = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			//logf("%s %s %s", name, args, parent);
			StringTypeStrip stripType;
			Json ret = Json.emptyObject();
			ret["data"] = Json.emptyObject();
			ret["data"]["types"] = Json.emptyArray();
			ret["data"]["types"] ~=
				typeResolverImpl!(__Type)(stripType, parent)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__Field)(stripType, parent)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__InputValue)(stripType, parent)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__EnumValue)(stripType, parent)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__TypeKind)(stripType, parent)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__Directive)(stripType, parent)["data"];
			ret["data"]["types"] ~=
				typeResolverImpl!(__DirectiveLocation)(stripType, parent)
					["data"];

			alias AllTypes = collectTypes!(T);
			alias NoListOrArray = staticMap!(stripArrayAndNullable, AllTypes);
			alias FixUp = staticMap!(fixupBasicTypes, NoListOrArray);
			static if(hasMember!(T, Constants.directives)) {
				alias NoDirectives = EraseAll!(
						typeof(__traits(getMember, T, Constants.directives)),
						FixUp
					);
			} else {
				alias NoDirectives = FixUp;
			}
			alias NoDup = NoDuplicates!(EraseAll!(T, NoDirectives));
			static foreach(type; NoDup) {{
				Json tmp = typeToJsonImpl!(type,T,type)();
				ret["data"]["types"] ~= tmp;
			}}
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
							l: switch(typeCap) {
								static foreach(type; collectTypes!(T)) {{
									case typeToTypeName!(type): {
										alias striped =
											stripArrayAndNullable!type;
										graphql.defaultResolverLog.logf("%s %s",
												typeCap, striped.stringof
											);
										ret["data"] ~=
											typeToJsonImpl!(striped,T,type)();
										break l;
									}
								}}
								default: break;
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
						l: switch(typeCap) {
							static foreach(type; collectTypes!(T)) {
								case typeToTypeName!(type): {
									alias striped = stripArrayAndNullable!type;
									graphql.defaultResolverLog.logf("%s %s",
											typeCap, striped.stringof
										);
									ret["data"] ~=
										typeToJsonImpl!(striped,T,type)();
									break l;
								}
							}
							default: {
								break;
							}
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
