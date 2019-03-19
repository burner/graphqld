module schema.typeconversions;

import std.algorithm.searching : canFind;
import std.conv : to;
import std.stdio;
import std.traits;
import std.meta;
import std.typecons : Nullable, nullable;
import std.range : ElementEncodingType;

import vibe.data.json;

import schema.types;
import traits;
import uda;
import constants;

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
	static if(is(Type == enum)) {
		enum typeToTypeName = Type.stringof;
	} else static if(is(Type == bool)) {
		enum typeToTypeName = "Bool";
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

template isScalarType(Type) {
	static if(is(Type == bool)) {
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
	} else {
		enum typeToFieldType = "__nonNullType";
	}
}

Json typeFields(T)() {
	static enum memsToIgnore = ["__ctor", "toString", "toHash", "opCmp",
			"opEquals", "Monitor", "factory"];
	Json ret = Json.emptyArray();
	alias TplusParents = AliasSeq!(T, InheritedClasses!T);
	static foreach(Type; TplusParents) {{
		//pragma(msg, "746 ", Type.stringof);
		static foreach(mem; __traits(allMembers, Type)) {{
			static if(!canFind(memsToIgnore, mem)) {
				Json tmp = Json.emptyObject();
				tmp[Constants.name] = mem;
				tmp[Constants.__typename] = "__Field"; // needed for interfacesForType
				tmp[Constants.description] = Json(null);
				tmp[Constants.isDeprecated] = false;
				tmp[Constants.deprecationReason] = Json(null);
				tmp[Constants.args] = Json.emptyArray();
				//pragma(msg, "\t749 ", mem);
				static if(isCallable!(__traits(getMember, Type, mem))) {
					//pragma(msg, "\t\tcallable");
					alias RT = ReturnType!(__traits(getMember, Type, mem));
					alias RTS = stripArrayAndNullable!RT;
					tmp[Constants.typenameOrig] = typeToTypeName!(RT);

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
						iv[Constants.typenameOrig] = typeToTypeName!(paraTypes[idx]);
						static if(!is(paraDefs[idx] == void)) {
							iv[Constants.defaultValue] = serializeToJson(paraDefs[idx])
								.toString();
						}
						tmp[Constants.args] ~= iv;
					}}
				} else {
					//pragma(msg, "\t\tfield");
					tmp[Constants.typenameOrig] = typeToTypeName!(
							typeof(__traits(getMember, Type, mem))
						);
				}
				ret ~= tmp;
			}
		}}
	}}
	return ret;
}

Json inputFields(Type)() {
	Json ret = Json.emptyArray();
	alias types = FieldTypeTuple!Type;
	alias names = FieldNameTuple!Type;
	static foreach(idx; 0 .. types.length) {{
		Json tmp = Json.emptyObject();
		tmp[Constants.name] = names[idx];
		tmp[Constants.description] = Json(null);
		tmp[Constants.__typename] = Constants.__InputValue; // needed for interfacesForType
		tmp[Constants.typenameOrig] = typeToTypeName!(types[idx]);
		tmp[Constants.defaultValue] = serializeToJson(
				__traits(getMember, Type.init, names[idx])
			);
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

// remove the top nullable to find out if we have a NON_NULL or not
Json typeToJson(Type,Schema)() {
	static if(is(Type : Nullable!F, F)) {
		return typeToJson1!(F,Schema)();
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJson1!(Type,Schema)();
		return ret;
	}
}

// remove the array is present
Json typeToJson1(Type,Schema)() {
	static if(isArray!Type && !isSomeString!Type) {
		Json ret = emptyType();
		ret["kind"] = "LIST";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJson2!(ElementEncodingType!Type, Schema)();
		return ret;
	} else {
		return typeToJsonImpl!(Type, Schema)();
	}
}

// remove another nullable
Json typeToJson2(Type,Schema)() {
	static if(is(Type : Nullable!F, F)) {
		return typeToJsonImpl!(F,Schema)();
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret[Constants.__typename] = "__Type";
		ret["ofType"] = typeToJsonImpl!(Type, Schema)();
		return ret;
	}
}

Json typeToJsonImpl(Type,Schema)() {
	Json ret = Json.emptyObject();
	enum string kind = typeToTypeEnum!Type;
	ret["kind"] = kind;
	ret[Constants.__typename] = "__Type";
	ret[Constants.name] = typeToTypeName!Type;
	ret[Constants.description] = "TODO";

	// fields
	static if((is(Type == class) || is(Type == interface) || is(Type == struct))
			&& !is(Type : Nullable!K, K))
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
	static if(is(Type == class) || is(Type == union)
			|| is(Type == interface))
	{
		ret[Constants.possibleTypesNames] = Json.emptyArray();
		alias PT = PossibleTypes!(Type, Schema);
		static foreach(pt; PT) {
			ret[Constants.possibleTypesNames] ~= pt.stringof;
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
	} else static if(isArray!Type) {
		ret[Constants.ofTypeName] = ElementEncodingType!(Type).stringof;
	}

	return ret;
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
				tmp[Constants.name] = mem;
				// needed for interfacesForType
				tmp[Constants.__typename] = Constants.__Directive;
				tmp[Constants.description] = Json(null);
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
						// needed for interfacesForType
						iv[Constants.__typename] = Constants.__InputValue;
						iv[Constants.typenameOrig] = typeToTypeName!(paraTypes[idx]);
						static if(!is(paraDefs[idx] == void)) {
							iv[Constants.defaultValue] = serializeToJson(paraDefs[idx])
								.toString();
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
