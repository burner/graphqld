module schema;

import std.stdio;
import std.format;
import std.traits;
import std.typecons;
import std.range;
import vibe.data.json;

template buildInToGraphql(Type) {
	static if(is(Type == bool)) {
		enum buildInToGraphql = "Boolean";
	} else static if(isIntegral!Type) {
		enum buildInToGraphql = "Int";
	} else static if(isFloatingPoint!Type) {
		enum buildInToGraphql = "Float";
	} else static if(isSomeString!Type) {
		enum buildInToGraphql = "String";
	} else {
		static assert(false, Type.stringof);
	}
}

void dtypeToGraphql(T)(ref Json toStoreNewTypes) {
	Json ret = Json.emptyObject;
	static if(isBuiltinType!(T)) {
		ret["name"] = buildInToGraphql!(T);
	} else {
		//toStoreNewTypes["types"][T.stringof] = Json.emptyObject();
		toStoreNewTypes[T.stringof] = Json.emptyObject();
		ret["name"] = T.stringof;
		ret["members"] = Json.emptyObject;
		enum fieldNames = FieldNameTuple!(T);
		static foreach(idx, field; Fields!(T)) {{
			Json t = Json.emptyObject();
			t["name"] = fieldNames[idx];
			t["type"] = typeToJson!(field)(toStoreNewTypes);
			ret["members"][fieldNames[idx]] = t;
		}}
	}

	//toStoreNewTypes["types"][T.stringof] = ret;
	toStoreNewTypes[T.stringof] = ret;
}

template StrippedType(T) {
    static if(is(T : Nullable!F, F)) {
		alias StrippedType = StrippedType!F;
	} else static if(isArray!(T) && !isSomeString!(T)) {
		alias StrippedType = StrippedType!(ElementEncodingType!(F));
	} else {
		alias StrippedType = T;
	}
}

Json typeToJson(T)(ref Json toStoreNewTypes) {
    static if(is(T : Nullable!F, F)) {
		alias NNArray = F;
		bool firstNull = true;
	} else {
		alias NNArray = T;
		bool firstNull = false;
	}
	enum bool isArr = isArray!(NNArray) && !isSomeString!(NNArray);
	static if(isArr) {
		alias Elem = ElementEncodingType!(NNArray);
	} else {
		alias Elem = NNArray;
	}
    static if(is(Elem : Nullable!G, G)) {
		alias ElemT = G;
		bool secondNull = true;
	} else {
		alias ElemT = Elem;
		bool secondNull = false;
	}

	Json ret = Json.emptyObject();
	ret["name"] = ElemT.stringof;
	ret["isArray"] = isArr;
	ret["nullableArray"] = firstNull;
	ret["nullableElement"] = secondNull;
	ret["isBasicType"] = isBasicType!ElemT;

	//if(!isBasicType!ElemT && ElemT.stringof !in toStoreNewTypes["types"]) {
	if(!isBasicType!ElemT && ElemT.stringof !in toStoreNewTypes) {
		dtypeToGraphql!ElemT(toStoreNewTypes);
	}
	return ret;
}

string jsonTypeToString(Json json) {
	foreach(k; typeKeys) {
		if(k !in json) {
			return json["name"].get!string();
		}
	}
	string f;
	if(json["nullableArray"].get!bool()) {
		f = "[%s%s]";
	} else if(json["isArray"].get!bool()) {
		f = "[%s%s]!";
	} else {
		f = "%s%s";
	}
	return format(f, json["name"].get!string(),
			json["nullableElement"].get!bool() ? "" : "!");
}

enum typeKeys = ["name", "isArray", "nullableArray",
		"nullableElement", "isBasicType"];

string typeName(Json j) {
	foreach(k; typeKeys) {
		assert(k in j, k);
	}
	assert(j["name"].type == Json.Type.string);
	return j["name"].get!string();
}

Json removeNullable(Json j) {
	Json ret = j.clone();
	ret["nullableArray"] = false;
	ret["nullableElement"] = false;
	return ret;
}

bool isList(Json type) {
	foreach(k; ["isArray", "nullableArray"]) {
		if(k !in type) {
			return false;
		}
	}
	return type["isArray"].get!bool() || type["nullableArray"].get!bool();
}

bool isNullable(Json type) {
	foreach(k; typeKeys) {
		assert(k in type, k);
	}
	return type["nullableElement"].get!bool()
		|| type["nullableArray"].get!bool();
}


bool isObject(Json type) {
	return cast(bool)("members" in type);
}

bool isScalar(Json type) {
	foreach(k; typeKeys) {
		assert(k in type, k);
	}
	return !type["isArray"].get!bool() && !type["nullableArray"].get!bool();
}

bool isLeaf(Json type) {
	foreach(k; typeKeys) {
		assert(k in type, k);
	}

	return type["isBasicType"].get!bool();
		//|| type["isEnum"].get!bool();
}

Json getTypeByName(Json schema, string name) {
	//assert("types" in schema);
	//assert(name in schema["types"]);
	//return schema["types"][name];
	assert(name in schema);
	return schema[name];
}

Json funcParams(Type, string mem)(ref Json toStoreNewTypes) {
	Json op = Json.emptyArray();
	enum pIds = ParameterIdentifierTuple!(__traits(getMember, Type, mem));
    alias ps = Parameters!(__traits(getMember, Type, mem));
    static foreach(idx, p; ps) {{
		assert(!pIds[idx].empty,
			format("%s [%(%s,%)] %s", Type.stringof, pIds,
				ps.length)
		);
		Json args = Json.emptyObject();
		args["name"] = pIds[idx];
		args["type"] = typeToJson!(p)(toStoreNewTypes);
		op ~= args;
    }}
	return op;
}

Json toSchema(Type)() {
	Json ret = Json.emptyObject();
	//ret["types"] = Json.emptyObject();

	pragma(msg, __traits(allMembers, Type));
	static foreach(qms; ["query", "mutation", "subscription"]) {{
		static assert(__traits(hasMember, Type, qms));
		alias QMSType = typeof(__traits(getMember, Type, qms));
		Json tmp = Json.emptyObject();
		tmp["name"] = qms;
		tmp["type"] = "operation";
		tmp["members"] = Json.emptyObject();
		static foreach(mem; __traits(allMembers, QMSType)) {{
			alias MemType = typeof(__traits(getMember, QMSType, mem));
			static if(isCallable!(MemType)) {{
				Json op = Json.emptyObject();
				op["name"] = mem;
				op["type"] = typeToJson!(ReturnType!(MemType))(ret);
				op["arguments"] = funcParams!(QMSType, mem)(ret);
				tmp["members"][mem] = op;
			}}
		}}
		ret[qms] = tmp;
	}}
	return ret;
}
