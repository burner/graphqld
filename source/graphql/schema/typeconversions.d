module graphql.schema.typeconversions;

import std.array : empty;
import std.algorithm.searching : canFind;
import std.conv : to;
import std.stdio;
import std.traits;
import std.meta;
import std.typecons : Nullable, nullable;
import std.range : ElementEncodingType;

import vibe.data.json;

import nullablestore;

import graphql.schema.types;
import graphql.traits;
import graphql.uda;
import graphql.constants;

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
	} else static if(is(Type : GQLDCustomLeaf!F, F)) {
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
	static assert(typeToTypeName!(GQLDCustomLeaf!Date) == "Date");
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
	static assert(typeToParameterTypeName!(int) == "Int!");
	static assert(typeToParameterTypeName!(Nullable!int) == "Int");
	static assert(typeToParameterTypeName!(double) == "Float!");
	static assert(typeToParameterTypeName!(Nullable!double) == "Float");
	static assert(typeToParameterTypeName!(double[]) == "[Float!]!");
	static assert(typeToParameterTypeName!(Nullable!(double)[]) == "[Float]!");
	static assert(typeToParameterTypeName!(Nullable!(Nullable!(double)[])) ==
			"[Float]");
	static assert(typeToParameterTypeName!(GQLDCustomLeaf!Date) == "Date!");
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
	static enum memsToIgnore = ["__ctor", "toString", "toHash", "opCmp",
			"opEquals", "Monitor", "factory"];
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
						tmp[Constants.typenameOrig] =
							typeToParameterTypeName!(
							//typeToTypeName!(
								typeof(__traits(getMember, Type, mem))
							);
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
	string t = j["kind"].get!string();
	if(t == "NON_NULL" || t == "LIST") {
		return removeNonNullAndList(j["ofType"]);
	} else {
		return j;
	}
}

// remove the top nullable to find out if we have a NON_NULL or not
Json typeToJson(Type,Schema)() {
	static if(is(Type : Nullable!F, F)) {
		return typeToJson1!(F,Schema,Type)();
	} else static if(is(Type : NullableStore!F, F)) {
		return typeToJson1!(Type.TypeValue,Schema,Type)();
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJson1!(Type,Schema,Type)();
		return ret;
	}
}

// remove the array is present
Json typeToJson1(Type,Schema,Orig)() {
	static if(isArray!Type && !isSomeString!Type && !is(Type == enum)) {
		Json ret = emptyType();
		ret["kind"] = "LIST";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJson2!(ElementEncodingType!Type, Schema, Orig)();
		return ret;
	} else {
		return typeToJsonImpl!(Type, Schema, Orig)();
	}
}

// remove another nullable
Json typeToJson2(Type,Schema,Orig)() {
	static if(is(Type : Nullable!F, F)) {
		return typeToJsonImpl!(F, Schema, Orig)();
	} else static if(is(Type : NullableStore!F, F)) {
		return typeToJsonImpl!(Type.TypeValue, Schema, Orig)();
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJsonImpl!(Type, Schema, Orig)();
		return ret;
	}
}

Json typeToJsonImpl(Type,Schema,Orig)() {
	Json ret = Json.emptyObject();
	enum string kind = typeToTypeEnum!(stripArrayAndNullable!Type);
	ret["kind"] = kind;
	ret[Constants.__typename] = "__Type";
	ret[Constants.name] = typeToTypeName!Type;

	enum GQLDUdaData udaData = getUdaData!(Orig);
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
			foreach(tname;
					SchemaReflection!Schema.instance.derivatives.get(typeid(Type),
																	 null))
			{
				ret[Constants.possibleTypesNames] ~= tname;
			}
		}
	} else {
		ret[Constants.possibleTypesNames] = Json(null);
	}

	// enumValues
	static if(is(Type == enum)) {
		ret[Constants.enumValues] = Json.emptyArray();
		static foreach(mem; EnumMembers!Type) {{
			Json tmp = Json.emptyObject();
			tmp[Constants.__TypeKind] = Constants.__EnumValue;
			tmp[Constants.name] = Json(to!string(mem));
			tmp[Constants.description] = "ENUM_DESCRIPTION_TODO";
			tmp[Constants.isDeprecated] = false;
			tmp[Constants.deprecationReason] = "ENUM_DEPRECATIONREASON_TODO";
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
	Json r = typeToJson!(string,void)();
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
		foo,
		bar
	}

	import std.format : format;
	Json r = typeToJson!(FooBar,void)();
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
				"description": "ENUM_DESCRIPTION_TODO",
				"deprecationReason": "ENUM_DEPRECATIONREASON_TODO",
				"__TypeKind": "__EnumValue",
				"isDeprecated": false,
				"name": "foo"
			},
			{
				"description": "ENUM_DESCRIPTION_TODO",
				"deprecationReason": "ENUM_DEPRECATIONREASON_TODO",
				"__TypeKind": "__EnumValue",
				"isDeprecated": false,
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
	Json r = typeToJson!(Nullable!string,void)();
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
	Json r = typeToJson!(Nullable!string,void)();
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
	static enum memsToIgnore = ["__ctor", "toString", "toHash", "opCmp",
			"opEquals", "Monitor", "factory"];
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
		string itName = it[Constants.name].get!string();
		if(itName == name) {
			return it;
		}
	}
	return Json.init;
}

Json getIntrospectionField(string name) {
	import std.format : format;
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
