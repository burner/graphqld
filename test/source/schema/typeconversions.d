module schema.typeconversions;

import std.algorithm.searching : canFind;
import std.conv : to;
import std.traits;
import std.meta;
import std.typecons : Nullable, nullable;
import std.range : ElementEncodingType;

import vibe.data.json;

import schema.types;
import traits;

@safe:

template typeToTypeEnum(Type) {
	static if(is(Type == enum)) {
		enum typeToTypeEnum = "ENUM";
	} else static if(is(Type == bool)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isFloatingPoint!(Type)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isIntegral!(Type)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isSomeString!Type) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(is(Type == union)) {
		enum typeToTypeEnum = "UNION";
	/*} else static if(is(Type : Nullable!F, F)) {
		enum typeToTypeEnum = "NULLABLE";
	} else static if(isArray!Type) {
		enum typeToTypeEnum = "LIST";*/
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
	/*} else static if(isArray!Type) {
		enum typeToTypeName = "__listType";
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToTypeName = "__nullType";
	*/
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
		pragma(msg, "746 ", Type.stringof);
		static foreach(mem; __traits(allMembers, Type)) {{
			static if(!canFind(memsToIgnore, mem)) {
				Json tmp = Json.emptyObject();
				tmp["name"] = mem;
				tmp["__typename"] = "__Field"; // needed for interfacesForType
				tmp["description"] = Json(null);
				tmp["isDeprecated"] = false;
				tmp["deprecationReason"] = Json(null);
				tmp["args"] = Json.emptyArray();
				pragma(msg, "\t749 ", mem);
				static if(isCallable!(__traits(getMember, Type, mem))) {
					pragma(msg, "\t\tcallable");
					alias RT = ReturnType!(__traits(getMember, Type, mem));
					alias RTS = stripArrayAndNullable!RT;
					tmp["typenameOrig"] = typeToTypeName!(RT);

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
						iv["name"] = paraNames[idx];
						// needed for interfacesForType
						iv["__typename"] = "__InputValue";
						iv["typenameOrig"] = typeToTypeName!(paraTypes[idx]);
						static if(!is(paraDefs[idx] == void)) {
							iv["defaultValue"] = serializeToJson(paraDefs[idx])
								.toString();
						}
						tmp["args"] ~= iv;
					}}
				} else {
					pragma(msg, "\t\tfield");
					tmp["typenameOrig"] = typeToTypeName!(
							typeof(__traits(getMember, Type, mem))
						);
				}
				ret ~= tmp;
			}
		}}
	}}
	return ret;
}

Json emptyType() {
	Json ret = Json.emptyObject();
	ret["name"] = Json(null);
	ret["description"] = Json(null);
	ret["fields"] = Json(null);
	ret["interfacesNames"] = Json(null);
	ret["possibleTypesNames"] = Json(null);
	ret["enumValues"] = Json(null);
	ret["ofType"] = Json(null);
	return ret;
}

// remove the top nullable to find out if we have a NON_NULL or not
Json typeToJson(Type)() {
	static if(is(Type : Nullable!F, F)) {
		return typeToJson1!F();
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret["__typename"] = "__Type";
		ret["ofType"] = typeToJson1!Type();
		return ret;
	}
}

// remove the array is present
Json typeToJson1(Type)() {
	static if(isArray!Type && !isSomeString!Type) {
		Json ret = emptyType();
		ret["kind"] = "LIST";
		ret["__typename"] = "__Type";
		ret["ofType"] = typeToJson2!(ElementEncodingType!Type)();
		return ret;
	} else {
		return typeToJsonImpl!Type();
	}
}

// remove another nullable
Json typeToJson2(Type)() {
	static if(is(Type : Nullable!F, F)) {
		return typeToJsonImpl!F();
	} else {
		Json ret = emptyType();
		ret["kind"] = "NON_NULL";
		ret["__typename"] = "__Type";
		ret["ofType"] = typeToJsonImpl!Type();
		return ret;
	}
}

Json typeToJsonImpl(Type)() {
	Json ret = Json.emptyObject();
	ret["kind"] = typeToTypeEnum!Type;
	ret["__typename"] = "__Type";
	ret["name"] = typeToTypeName!Type;
	ret["description"] = "TODO";

	// fields
	static if((is(Type == class) || is(Type == interface) || is(Type == struct))
			&& !is(Type : Nullable!K, K))
	{
		ret["fields"] = typeFields!Type();
	} else {
		ret["fields"] = Json(null);
	}

	// needed to resolve interfaces
	static if(is(Type == class)) {
		ret["interfacesNames"] = Json.emptyArray();
		static foreach(interfaces; InheritedClasses!Type) {{
			ret["interfacesNames"] ~= interfaces.stringof;
		}}
	} else {
		ret["interfacesNames"] = Json(null);
	}

	// needed to resolve possibleTypes
	static if(is(Type == class) || is(Type == union)
			|| is(Type == interface))
	{
		ret["possibleTypesNames"] = Json.emptyArray();
		static foreach(pt; AliasSeq!(Type, InheritedClasses!Type)) {
			ret["possibleTypesNames"] ~= pt.stringof;
		}
	} else {
		ret["possibleTypesNames"] = Json(null);
	}

	// enumValues
	static if(is(Type == enum)) {
		ret["enumValues"] = Json.emptyArray();
		static foreach(mem; EnumMembers!Type) {{
			Json tmp = Json.emptyObject();
			tmp["__TypeKind"] = "__EnumValue";
			tmp["name"] = Json(to!string(mem));
			tmp["description"] = "ENUM_DESCRIPTION_TODO";
			tmp["isDeprecated"] = false;
			tmp["deprecationReason"] = "ENUM_DEPRECATIONREASON_TODO";
			ret["enumValues"] ~= tmp;
		}}
	} else {
		ret["enumValues"] = Json(null);
	}

	// needed to resolve ofType
	static if(is(Type : Nullable!F, F)) {
		ret["ofTypeName"] = F.stringof;
	} else static if(isArray!Type) {
		ret["ofTypeName"] = ElementEncodingType!(Type).stringof;
	}

	return ret;
}
