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
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToTypeEnum = "NULLABLE";
	} else static if(isArray!Type) {
		enum typeToTypeEnum = "LIST";
	} else static if(isAggregateType!Type) {
		enum typeToTypeEnum = "OBJECT";
	} else {
		static assert(false, T.stringof ~ " not handled");
	}
}

unittest {
	static assert(typeToTypeEnum!(int[]) == "LIST");
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
	} else static if(isArray!Type) {
		enum typeToTypeName = "__listType";
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToTypeName = "__nullType";
	} else {
		enum typeToTypeName = Type.stringof;
	}
}

unittest {
	static assert(typeToTypeName!(Nullable!int) == "__nullType");
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

Json typeToField(T, string name)() {
	alias Ts = stripArrayAndNullable!T;
	Json ret = Json.emptyObject();
	ret["name"] = name;
	ret["typename"] = typeToTypeName!(Ts);
	ret["typenameOrig"] = typeToFieldType!(T);
	ret["description"] = "TODO";
	ret["isDeprecated"] = false;
	ret["deprecationReason"] = "TODO";
	return ret;
}

/*Json typeFields(T)() {
	import std.algorithm.searching : startsWith;
	import std.traits : FieldTypeTuple, FieldNameTuple;
	Json ret = Json.emptyArray();

	alias manyTypes = EraseAll!(Object, AliasSeq!(T, InheritedClasses!T));
	pragma(msg, "775 ", T.stringof, " ", manyTypes);
	static foreach(Type; manyTypes) {{
		static if(is(Type : Nullable!F, F)) {
			alias FT = F;
		} else {
			alias FT = Type;
		}
		pragma(msg, FT);
		Json tmp = Json.emptyObject();
		tmp["description"] = "TODO";
		tmp["isDeprecated"] = false;
		tmp["deprecationReason"] = "TODO";
		static if(isBasicType!FT) {
		} else {
			tmp["name"] = mem;
			static foreach(mem; __traits(allMembers, FT)) {{
				alias MemType = typeof(__traits(getMember, FT, mem));
				static if(isCallable!(__traits(getMember, FT, mem))) {
					alias RT = ReturnType!(__traits(getMember, FT, mem));
					alias RTS = stripArrayAndNullable!RT;
					tmp["typename"] = typeToTypeName!(RTS);
					tmp["typenameOrig"] = typeToTypeName!(RT);
				}
			}}
		}
		ret ~= tmp;
		//alias fieldTypes = FieldTypeTuple!Type;
		//alias fieldNames = FieldNameTuple!Type;
		//static foreach(idx; 0 .. fieldTypes.length) {{
		//	static if(!fieldNames[idx].empty
		//			&& !startsWith(fieldNames[idx], "_"))
		//	{
		//		ret ~= typeToField!(fieldTypes[idx], fieldNames[idx]);
		//	}
		//}}
	}}
	return ret;
}*/

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
				tmp["__TypeKind"] = "__Field";
				tmp["name"] = mem;
				tmp["description"] = "";
				tmp["isDeprecated"] = false;
				tmp["deprecationReason"] = "";
				tmp["args"] = Json.emptyArray();
				pragma(msg, "\t749 ", mem);
				static if(isCallable!(__traits(getMember, Type, mem))) {
					pragma(msg, "\t\tcallable");
					alias RT = ReturnType!(__traits(getMember, Type, mem));
					alias RTS = stripArrayAndNullable!RT;
					tmp["__typename"] = "__Field";
					tmp["typename"] = typeToTypeName!RTS;
					tmp["typenameOrg"] = typeToTypeName!RT;

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
						iv["__TypeKind"] = "__InputValue";
						iv["name"] = paraNames[idx];
						iv["typename"] = typeToTypeName!(paraTypes[idx]);
						alias Ts = stripArrayAndNullable!(paraTypes[idx]);
						iv["typenameOrig"] = typeToFieldType!(Ts);
						static if(!is(paraDefs[idx] == void)) {
							iv["defaultValue"] = serializeToJson(paraDefs[idx])
								.toString();
						}
						tmp["args"] ~= iv;
					}}
				} else {
					pragma(msg, "\t\tfield");
					alias Ts = stripArrayAndNullable!(
							typeof(__traits(getMember, Type, mem))
						);
					tmp["typename"] = typeToTypeName!Ts;
					tmp["typenameOrg"] = typeToTypeName!(
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
	ret["kind"] = "";
	ret["name"] = Json(null);
	ret["__typename"] = Json(null);
	ret["description"] = Json(null);
	ret["fields"] = Json(null);
	ret["interfacesNames"] = Json(null);
	ret["possibleTypesNames"] = Json(null);
	ret["ofTypeName"] = Json(null);
	ret["enumValues"] = Json(null);
	return ret;
}

Json typeToJson(Type)() {
	Json ret = Json.emptyObject();
	ret["__TypeKind"] = "__Type";
	ret["kind"] = typeToTypeEnum!Type;
	ret["name"] = typeToTypeName!Type;
	ret["__typename"] = "__Type";
	ret["description"] = "TODO";

	// fields
	static if(
			(is(Type == class) || is(Type == interface) || is(Type == struct))
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
	static if(!isSomeString!Type && isArray!Type) {
		ret["ofTypeName"] = ElementEncodingType!(Type).stringof;
	} else static if(is(Type : Nullable!F, F)) {
		ret["ofTypeName"] = F.stringof;
	} else {
		ret["ofTypeName"] = Type.stringof;
	}

	return ret;
}
