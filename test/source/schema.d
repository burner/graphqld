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
		toStoreNewTypes["types"][T.stringof] = Json.emptyObject();
		writeln(T.stringof);
		ret["name"] = T.stringof;
		ret["members"] = Json.emptyArray;
		enum fieldNames = FieldNameTuple!(T);
		static foreach(idx, field; Fields!(T)) {{
			Json t = Json.emptyObject();
			t["name"] = fieldNames[idx];
			t["type"] = typeToJson!(field)(toStoreNewTypes);
			ret["members"] ~= t;
		}}
	}

	toStoreNewTypes["types"][T.stringof] = ret;
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

	if(!isBasicType!ElemT && ElemT.stringof !in toStoreNewTypes["types"]) {
		dtypeToGraphql!ElemT(toStoreNewTypes);
	}
	return ret;
}

Json funcParams(Type, string mem)(ref Json toStoreNewTypes) {
	Json op = Json.emptyArray();
	enum pIds = ParameterIdentifierTuple!(__traits(getMember, Type, mem));
	writeln(pIds);
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
	ret["types"] = Json.emptyObject();

	pragma(msg, __traits(allMembers, Type));
	static foreach(qms; ["query", "mutation", "subscription"]) {{
		static assert(__traits(hasMember, Type, qms));
		alias QMSType = typeof(__traits(getMember, Type, qms));
		Json tmp = Json.emptyObject();
		tmp["name"] = qms;
		tmp["type"] = "operation";
		tmp["operations"] = Json.emptyArray();
		static foreach(mem; __traits(allMembers, QMSType)) {{
			alias MemType = typeof(__traits(getMember, QMSType, mem));
			static if(isCallable!(MemType)) {{
				Json op = Json.emptyObject();
				op["name"] = mem;
				op["returnType"] = typeToJson!(ReturnType!(MemType))(ret);
				op["arguments"] = funcParams!(QMSType, mem)(ret);
				tmp["opereations"] ~= op;
			}}
		}}
		ret[qms] = tmp;
	}}
	return ret;
}
