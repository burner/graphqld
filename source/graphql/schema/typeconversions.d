module graphql.schema.typeconversions;

import std.array : array, empty;
import std.algorithm.searching : canFind;
import std.algorithm.iteration : map;
import std.conv : to;
import std.stdio;
import std.traits;
import std.meta;
import std.format : format;
import std.typecons : Nullable, nullable;
import std.range : ElementEncodingType;

import vibe.data.json;

import nullablestore;

import graphql.schema.types;
import graphql.traits;
import graphql.uda;
import graphql.constants;

private enum memsToIgnore = ["__ctor", "toString", "toHash", "opCmp",
		"opEquals", "Monitor", "factory", "opAssign"];
@safe:

template typeToTypeEnum(Type) {
	static if(isAggregateType!Type && hasUDA!(Type, GQLDUdaData)
			&& getUDAs!(Type, GQLDUdaData)[0].typeKind != TypeKind.UNDEFINED)
	{
		enum udas = getUDAs!(Type, GQLDUdaData);
		static assert(udas.length == 1);
		enum GQLDUdaData u = udas[0];
		enum typeToTypeEnum = to!string(u.typeKind);
	} else static if(is(Type == enum)) {
		enum typeToTypeEnum = "ENUM";
	} else static if(is(Type == bool)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(is(Type : GQLDCustomLeaf!Fs, Fs...)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isFloatingPoint!(Type)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isIntegral!(Type)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isSomeString!Type) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(is(Type == void)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(is(Type == union)) {
		enum typeToTypeEnum = "UNION";
	} else static if(isAggregateType!Type) {
		enum typeToTypeEnum = "OBJECT";
	} else {
		static assert(false, Type.stringof ~ " not handled");
	}
}

template typeToTypeName(Type) {
	import graphql.uda : GQLDCustomLeaf;
	static if(is(Type == enum)) {
		enum typeToTypeName = Type.stringof;
	} else static if(is(Type == bool)) {
		enum typeToTypeName = "Boolean";
	} else static if(is(Type == GQLDCustomLeaf!Fs, Fs...)) {
		enum typeToTypeName = Fs[0].stringof;
	} else static if(isFloatingPoint!(Type)) {
		enum typeToTypeName = "Float";
	} else static if(isIntegral!(Type)) {
		enum typeToTypeName = "Int";
	} else static if(isSomeString!Type) {
		enum typeToTypeName = "String";
	} else {
		enum typeToTypeName = Type.stringof;
	}
}

unittest {
	import std.datetime : Date;

	string tS(Date d) {
		return "";
	}
	Date fromS(string s) {
		return Date.init;
	}
	static assert(typeToTypeName!(GQLDCustomLeaf!(Date, tS, fromS)) == "Date");
}

template typeToParameterTypeName(Type) {
	template level2(Type) {
		static if(is(Type : Nullable!F, F)) {
			enum level2 = typeToTypeName!F;
		} else {
			enum level2 = typeToTypeName!Type ~ "!";
		}
	}

	template level1(Type) {
		static if(isArray!Type && !isSomeString!Type) {
			enum level1 = "[" ~ level2!(ElementEncodingType!Type) ~ "]";
		} else {
			enum level1 = typeToTypeName!Type;
		}
	}

	template level0(Type) {
		static if(is(Type : Nullable!F, F)) {
			enum level0 = level1!F;
		} else {
			enum level0 = level1!Type ~ "!";
		}
	}

	template levelM1(Type) {
		static if(is(Type : NullableStore!F, F)) {
			enum levelM1 = level0!F;
		} else {
			enum levelM1 = level0!Type;
		}
	}

	enum typeToParameterTypeName = levelM1!Type;
}

unittest {
	import std.datetime : Date;
	string tS(Date d) {
		return "";
	}
	Date fS(string s) {
		return Date.init;
	}
	static assert(typeToParameterTypeName!(int) == "Int!");
	static assert(typeToParameterTypeName!(Nullable!int) == "Int");
	static assert(typeToParameterTypeName!(double) == "Float!");
	static assert(typeToParameterTypeName!(Nullable!double) == "Float");
	static assert(typeToParameterTypeName!(double[]) == "[Float!]!");
	static assert(typeToParameterTypeName!(Nullable!(double)[]) == "[Float]!");
	static assert(typeToParameterTypeName!(Nullable!(Nullable!(double)[])) ==
			"[Float]");
	static assert(typeToParameterTypeName!(GQLDCustomLeaf!(Date,tS,fS))
			== "Date!");
}

unittest {
	enum AEnum {
		one,
		two,
		three
	}
	static assert(typeToParameterTypeName!(AEnum) == "AEnum!");
	static assert(typeToParameterTypeName!(Nullable!AEnum) == "AEnum");
	static assert(typeToParameterTypeName!(Nullable!(AEnum)[]) == "[AEnum]!");
	static assert(typeToParameterTypeName!(Nullable!(Nullable!(AEnum)[])) ==
			"[AEnum]");
}

template isScalarType(Type) {
	static if(is(Type == bool)) {
		enum isScalarType = true;
	} else static if(is(Type == GQLDCustomLeaf!Fs, Fs...)) {
		enum isScalarType = true;
	} else static if(isFloatingPoint!(Type)) {
		enum isScalarType = true;
	} else static if(isIntegral!(Type)) {
		enum isScalarType = true;
	} else static if(isSomeString!Type) {
		enum isScalarType = true;
	} else static if(is(Type == enum)) {
		enum isScalarType = true;
	} else {
		enum isScalarType = false;
	}
}

template typeToFieldType(Type) {
	static if(isArray!Type && !isSomeString!Type) {
		enum typeToFieldType = "__listType";
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToFieldType = F.stringof;
	} else static if(is(Type : NullableStore!F, F)) {
		enum typeToFieldType = Type.TypeValue.stringof;
	} else {
		enum typeToFieldType = "__nonNullType";
	}
}

Json typeFields(T)() {
	import graphql.uda;
	Json ret = Json.emptyArray();
	bool[string] fieldsAlreadyIn;
	alias TplusParents = AliasSeq!(T, InheritedClasses!T);
	static foreach(Type; TplusParents) {{
		static foreach(mem; __traits(allMembers, Type)) {{
			enum GQLDUdaData udaData = getUdaData!(Type, mem);
			static if(!canFind(memsToIgnore, mem)
					&& udaData.ignore != Ignore.yes)
			{
				if(mem !in fieldsAlreadyIn) {
					fieldsAlreadyIn[mem] = true;
					Json tmp = Json.emptyObject();
					tmp[Constants.name] = mem;
					// needed for interfacesForType
					tmp[Constants.__typename] = "__Field";
					tmp[Constants.description] =
						udaData.description.getText().empty
							? Json(null)
							: Json(udaData.description.getText());

					tmp[Constants.isDeprecated] =
						udaData.deprecationInfo.isDeprecated == IsDeprecated.yes
							? true
							: false;

					tmp[Constants.deprecationReason] =
						udaData.deprecationInfo.isDeprecated == IsDeprecated.yes
							? Json(udaData.deprecationInfo.deprecationReason)
							: Json(null);

					tmp[Constants.args] = Json.emptyArray();
					static if(isCallable!(__traits(getMember, Type, mem))) {
						alias RT = ReturnType!(__traits(getMember, Type, mem));
						alias RTS = stripArrayAndNullable!RT;
						//tmp[Constants.typenameOrig] = typeToTypeName!(RT);
						tmp[Constants.typenameOrig] = typeToParameterTypeName!(RT);

						// InputValue
						alias paraNames = ParameterIdentifierTuple!(
								__traits(getMember, Type, mem)
							);
						alias paraTypes = Parameters!(
								__traits(getMember, Type, mem)
							);
						alias paraDefs = ParameterDefaults!(
								__traits(getMember, Type, mem)
							);
						static foreach(idx; 0 .. paraNames.length) {{
							Json iv = Json.emptyObject();
							iv[Constants.name] = paraNames[idx];
							// needed for interfacesForType
							iv[Constants.__typename] = Constants.__InputValue;
							iv[Constants.description] = Json(null);
							static if(__traits(compiles, __traits(getAttributes,
									Parameters!(__traits(getMember, Type,
										mem))[idx ..  idx + 1])))
							{
								iv[Constants.description] = Json(null);
								alias udad = __traits(getAttributes,
										Parameters!(__traits(getMember, Type,
											mem))[idx ..  idx + 1]);
								static if(udad.length == 1) {
									enum F = udad[0];
									static if(is(typeof(F) == GQLDUdaData)) {
										iv[Constants.description] =
											F.description.text;
									}
								}
							}
							iv[Constants.typenameOrig] =
								typeToParameterTypeName!(paraTypes[idx]);
							static if(!is(paraDefs[idx] == void)) {
								iv[Constants.defaultValue] = serializeToJson(
										paraDefs[idx]
									)
									.toString();
							} else {
								iv[Constants.defaultValue] = Json(null);
							}
							tmp[Constants.args] ~= iv;
						}}
					} else {
						static if(!isType!(__traits(getMember, Type, mem))) {
							tmp[Constants.typenameOrig] =
								typeToParameterTypeName!(
								//typeToTypeName!(
									typeof(__traits(getMember, Type, mem))
								);
						}
					}
					ret ~= tmp;
				}
			}
		}}
	}}
	//writefln("%s %s", __LINE__, ret.toPrettyString());
	return ret;
}

Json inputFields(Type)() {
	Json ret = Json.emptyArray();
	alias types = FieldTypeTuple!Type;
	alias names = FieldNameTuple!Type;
	static foreach(idx; 0 .. types.length) {{
		enum GQLDUdaData udaData = getUdaData!(types[idx]);
		Json tmp = Json.emptyObject();
		tmp[Constants.name] = names[idx];
		tmp[Constants.description] = udaData.description.getText().empty
				? Json(null)
				: Json(udaData.description.getText());

		// needed for interfacesForType
		tmp[Constants.__typename] = Constants.__InputValue;

		//tmp[Constants.typenameOrig] = typeToTypeName!(types[idx]);
		tmp[Constants.typenameOrig] = typeToParameterTypeName!(types[idx]);
		auto t = __traits(getMember, Type.init, names[idx]);
		tmp[Constants.defaultValue] = serializeToJson(t);
		ret ~= tmp;
	}}
	return ret;
}

Json emptyType() {
	Json ret = Json.emptyObject();
	ret[Constants.name] = Json(null);
	ret[Constants.description] = Json(null);
	ret[Constants.fields] = Json(null);
	ret[Constants.interfacesNames] = Json(null);
	ret[Constants.possibleTypesNames] = Json(null);
	ret[Constants.enumValues] = Json(null);
	ret["ofType"] = Json(null);
	return ret;
}

Json removeNonNullAndList(Json j) {
	immutable string t = j["kind"].get!string();
	if(t == "NON_NULL" || t == "LIST") {
		return removeNonNullAndList(j["ofType"]);
	} else {
		return j;
	}
}

// remove the top nullable to find out if we have a NON_NULL or not
Json typeToJson(Type,Schema)(Schema schema) {
	static if(is(Type : Nullable!F, F)) {
		return typeToJson1!(F,Schema,Type)(schema);
	} else static if(is(Type : NullableStore!F, F)) {
		return typeToJson1!(Type.TypeValue,Schema,Type)(schema);
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJson1!(Type,Schema,Type)(schema);
		return ret;
	}
}

// remove the array is present
Json typeToJson1(Type,Schema,Orig)(Schema schema) {
	static if(isArray!Type && !isSomeString!Type && !is(Type == enum)) {
		Json ret = emptyType();
		ret["kind"] = "LIST";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJson2!(ElementEncodingType!Type, Schema, Orig)();
		return ret;
	} else {
		return typeToJsonImpl!(Type, Schema, Orig)(schema);
	}
}

// remove another nullable
Json typeToJson2(Type,Schema,Orig)(Schema schema) {
	static if(is(Type : Nullable!F, F)) {
		return typeToJsonImpl!(F, Schema, Orig)(schema);
	} else static if(is(Type : NullableStore!F, F)) {
		return typeToJsonImpl!(Type.TypeValue, Schema, Orig)(schema);
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJsonImpl!(Type, Schema, Orig)(schema);
		return ret;
	}
}

template notNullOrArray(T,S) {
	static if(is(Nullable!F : T, F)) {
		alias notNullOrArray = S;
	} else static if(isArray!T) {
		alias notNullOrArray = S;
	} else {
		alias notNullOrArray = T;
	}
}

Json typeToJsonImpl(Type,Schema,Orig)(Schema schema) {
	Json ret = Json.emptyObject();
	enum string kind = typeToTypeEnum!(stripArrayAndNullable!Type);
	ret["kind"] = kind;
	ret[Constants.__typename] = "__Type";
	ret[Constants.name] = typeToTypeName!Type;

	alias TypeOrig = notNullOrArray!(Type,Orig);
	enum GQLDUdaData udaData = getUdaData!(TypeOrig);
	enum des = udaData.description.text;
	ret[Constants.description] = des.empty
			? Json(null)
			: Json(des);

	ret[Constants.isDeprecated] =
		udaData.deprecationInfo.isDeprecated == IsDeprecated.yes
			? true
			: false;

	ret[Constants.deprecationReason] =
		udaData.deprecationInfo.isDeprecated == IsDeprecated.yes
			? Json(udaData.deprecationInfo.deprecationReason)
			: Json(null);

	// fields
	static if((is(Type == class) || is(Type == interface) || is(Type == struct))
			&& !is(Type : Nullable!K, K) && !is(Type : NullableStore!K, K)
			&& !is(Type : GQLDCustomLeaf!Ks, Ks...))
	{
		ret[Constants.fields] = typeFields!Type();
	} else {
		ret[Constants.fields] = Json(null);
	}

	// inputFields
	static if(kind == Constants.INPUT_OBJECT) {
		ret[Constants.inputFields] = inputFields!Type();
	} else {
		ret[Constants.inputFields] = Json(null);
	}

	// needed to resolve interfaces
	static if(is(Type == class) || is(Type == interface)) {
		ret[Constants.interfacesNames] = Json.emptyArray();
		static foreach(interfaces; InheritedClasses!Type) {{
			ret[Constants.interfacesNames] ~= interfaces.stringof;
		}}
	} else {
		ret[Constants.interfacesNames] = Json(null);
	}

	// needed to resolve possibleTypes
	static if(is(Type == class) || is(Type == union) || is(Type == interface)) {
		static if(is(Type == union)) {
			ret[Constants.possibleTypesNames] = Json.emptyArray();
			static foreach(pt; Filter!(isAggregateType, FieldTypeTuple!Type)) {
				ret[Constants.possibleTypesNames] ~= pt.stringof;
			}
		} else {
			import graphql.reflection;
			// need to search for all types that we support that are derived
			// from this type
			ret[Constants.possibleTypesNames] = Json.emptyArray();
			if(schema !is null) {
				if(GQLDType gqldT = Type.stringof in schema.types) {
					if(GQLDMap gqldM = toMap(gqldT)) {
						ret[Constants.possibleTypesNames] =
							gqldM.derivatives.map!(it => it.name.Json)
							.array
							.Json;
					}
				}

			}
			/*
			foreach(tname;
					SchemaReflection!Schema.instance.derivatives.get(typeid(Type),
																	 null))
			{
				ret[Constants.possibleTypesNames] ~= tname;
			}
			*/
		}
	} else {
		ret[Constants.possibleTypesNames] = Json(null);
	}

	// enumValues
	static if(is(Type == enum)) {
		ret[Constants.enumValues] = Json.emptyArray();
		static foreach(mem; EnumMembers!Type) {{
			enum memUdaData = getUdaData!(Type, to!string(mem));
			Json tmp = Json.emptyObject();
			tmp[Constants.__TypeKind] = Constants.__EnumValue;
			tmp[Constants.name] = Json(to!string(mem));
			tmp[Constants.description] = memUdaData.description.text;
			tmp[Constants.isDeprecated] = (memUdaData.deprecationInfo.isDeprecated == IsDeprecated.yes);
			tmp[Constants.deprecationReason] = (memUdaData.deprecationInfo.isDeprecated == IsDeprecated.yes)
							? Json(memUdaData.deprecationInfo.deprecationReason)
							: Json(null);
			ret[Constants.enumValues] ~= tmp;
		}}
	} else {
		ret[Constants.enumValues] = Json(null);
	}

	// needed to resolve ofType
	static if(is(Type : Nullable!F, F)) {
		ret[Constants.ofTypeName] = F.stringof;
	} else static if(is(Type : NullableStore!F, F)) {
		ret[Constants.ofTypeName] = F.stringof;
	} else static if(is(Type : GQLDCustomLeaf!Fs, Fs...)) {
		ret[Constants.ofTypeName] = Fs[0].stringof;
	} else static if(isArray!Type) {
		ret[Constants.ofTypeName] = ElementEncodingType!(Type).stringof;
	}

	return ret;
}

@safe unittest {
	import std.format : format;
	Json r = typeToJson!(string)(null);
	Json e = parseJsonString(`
		{
			"__typename": "__Type",
			"possibleTypesNames": null,
			"enumValues": null,
			"interfacesNames": null,
			"kind": "NON_NULL",
			"name": null,
			"ofType": {
				"__typename": "__Type",
				"possibleTypesNames": null,
				"enumValues": null,
				"interfacesNames": null,
				"kind": "SCALAR",
				"isDeprecated": false,
				"deprecationReason": null,
				"name": "String",
				"description": null,
				"inputFields": null,
				"ofTypeName": "immutable(char)",
				"fields": null
			},
			"description": null,
			"fields": null
		}
		`);
	assert(r == e, format("exp:\n%s\ngot:\n%s", e.toPrettyString(),
				r.toPrettyString()));
}

@safe unittest {
	enum FooBar {
		@GQLDUda(GQLDDescription("important"))
		foo,
		@GQLDUda(
			GQLDDeprecated(IsDeprecated.yes, "not foo enough"),
			GQLDDescription("unimportant")
		)
		bar
	}

	import std.format : format;
	Json r = typeToJson!(FooBar)(null);
	Json e = parseJsonString(`
{
	"__typename": "__Type",
	"possibleTypesNames": null,
	"enumValues": null,
	"interfacesNames": null,
	"kind": "NON_NULL",
	"name": null,
	"ofType": {
		"__typename": "__Type",
		"possibleTypesNames": null,
		"enumValues": [
			{
				"description": "important",
				"deprecationReason": null,
				"__TypeKind": "__EnumValue",
				"isDeprecated": false,
				"name": "foo"
			},
			{
				"description": "unimportant",
				"deprecationReason": "not foo enough",
				"__TypeKind": "__EnumValue",
				"isDeprecated": true,
				"name": "bar"
			}
		],
		"interfacesNames": null,
		"kind": "ENUM",
		"isDeprecated": false,
		"deprecationReason": null,
		"name": "FooBar",
		"description": null,
		"inputFields": null,
		"fields": null
	},
	"description": null,
	"fields": null
}
		`);
	assert(r == e, format("exp:\n%s\ngot:\n%s", e.toPrettyString(),
				r.toPrettyString()));
}
@safe unittest {
	import std.format : format;
	Json r = typeToJson!(Nullable!string)(null);
	Json e = parseJsonString(`
		{
			"__typename": "__Type",
			"possibleTypesNames": null,
			"enumValues": null,
			"interfacesNames": null,
			"kind": "SCALAR",
			"isDeprecated": false,
			"deprecationReason": null,
			"name": "String",
			"description": null,
			"inputFields": null,
			"ofTypeName": "immutable(char)",
			"fields": null
		}
		`);
	assert(r == e, format("exp:\n%s\ngot:\n%s", e.toPrettyString(),
				r.toPrettyString()));
}

@safe unittest {
	import std.format : format;
	Json r = typeToJson!(Nullable!string)(null);
	Json e = parseJsonString(`
		{
			"__typename": "__Type",
			"possibleTypesNames": null,
			"enumValues": null,
			"interfacesNames": null,
			"kind": "SCALAR",
			"isDeprecated": false,
			"deprecationReason": null,
			"name": "String",
			"description": null,
			"inputFields": null,
			"ofTypeName": "immutable(char)",
			"fields": null
		}
		`);
	assert(r == e, format("exp:\n%s\ngot:\n%s", e.toPrettyString(),
				r.toPrettyString()));
}

Json directivesToJson(Directives)() {
	import std.string : stripLeft;
	Json ret = Json.emptyArray();
	alias TplusParents = AliasSeq!(Directives, InheritedClasses!Directives);
	static foreach(Type; TplusParents) {{
		static foreach(mem; __traits(allMembers, Type)) {{
			static if(!canFind(memsToIgnore, mem)) {
				Json tmp = Json.emptyObject();
				enum GQLDUdaData udaData = getUdaData!(Type, mem);
				tmp[Constants.name] = mem;
				// needed for interfacesForType
				tmp[Constants.__typename] = Constants.__Directive;
				tmp[Constants.description] = udaData.description.getText().empty
						? Json(null)
						: Json(udaData.description.text);

				tmp[Constants.isDeprecated] =
					udaData.deprecationInfo.isDeprecated == IsDeprecated.yes
						? true
						: false;

				tmp[Constants.deprecationReason] =
					udaData.deprecationInfo.isDeprecated == IsDeprecated.yes
						? Json(udaData.deprecationInfo.deprecationReason)
						: Json(null);

				//tmp[Constants.description] = Json(null);
				tmp[Constants.locations] = Json.emptyArray();
				tmp[Constants.args] = Json.emptyArray();
				static if(isCallable!(__traits(getMember, Type, mem))) {
					// InputValue
					alias paraNames = ParameterIdentifierTuple!(
							__traits(getMember, Type, mem)
						);
					alias paraTypes = Parameters!(
							__traits(getMember, Type, mem)
						);
					alias paraDefs = ParameterDefaults!(
							__traits(getMember, Type, mem)
						);
					static foreach(idx; 0 .. paraNames.length) {{
						Json iv = Json.emptyObject();
						// TODO remove the strip left. Its in because the
						// two default directives of GraphQL skip and include
						// both have one parameter named "if".
						iv[Constants.name] = stripLeft(paraNames[idx], "_");
						iv[Constants.description] = Json(null);
						// needed for interfacesForType
						iv[Constants.__typename] = Constants.__InputValue;
						iv[Constants.typenameOrig] = typeToTypeName!(paraTypes[idx]);
						//iv[Constants.typenameOrig] = typeToParameterTypeName!(paraTypes[idx]);
						static if(!is(paraDefs[idx] == void)) {
							iv[Constants.defaultValue] = serializeToJson(paraDefs[idx])
								.toString();
						} else {
							iv[Constants.defaultValue] = Json(null);
						}
						tmp[Constants.args] ~= iv;
					}}
				}
				ret ~= tmp;
			}
		}}
	}}
	return ret;
}

Json getField(Json j, string name) {
	import graphql.constants;

	if(j.type != Json.Type.object || Constants.fields !in j
			|| j[Constants.fields].type != Json.Type.array)
	{
		return Json.init;
	}

	foreach(it; j[Constants.fields].byValue) {
		immutable string itName = it[Constants.name].get!string();
		if(itName == name) {
			return it;
		}
	}
	return Json.init;
}

string getIntrospectionFieldGQLD(string name) {
	return name == Constants.__typename
		? "String"
		: name == Constants.__schema
			? "__Schema"
			: name == Constants.__type
				? "__Type"
				: format("Not known introspection name '%s'", name);
}

Json getIntrospectionField(string name) {
	Json ret = Json.emptyObject();
	ret[Constants.typenameOrig] = name == Constants.__typename
		? "String"
		: name == Constants.__schema
			? "__Schema"
			: name == Constants.__type
				? "__Type"
				: format("Not known introspection name '%s'", name);
	return ret;
}
