module helper;

import std.algorithm.iteration : splitter;
import std.exception : enforce;
import std.experimental.logger;

import vibe.data.json;

@safe:

string firstCharUpperCase(string input) {
	import std.conv : to;
	import std.uni : isUpper, toUpper;
	import std.array : front, popFront;
	if(isUpper(input.front)) {
		return input;
	}

	dchar f = input.front;
	input.popFront();

	return to!string(toUpper(f)) ~ input;
}

Json returnTemplate() {
	Json ret = Json.emptyObject();
	ret["data"] = Json.emptyObject();
	ret["error"] = Json.emptyArray();
	return ret;
}

void insertPayload(ref Json result, string field, Json data) {
	import std.algorithm.searching : canFind;
	import std.exception : enforce;
	enum d = "data";
	enum e = "error";
	if(d in data) {
		enforce(result[d].type == Json.Type.object);
		result[d][field] = data[d];
	}
	if(e in data) {
		enforce(result[e].type == Json.Type.array);
		if(!canFind(result[e].byValue(), data[e])) {
			result[e] ~= data[e];
		}
	}
}

bool isScalar(ref const(Json) data) {
	return data.type == Json.Type.bigInt
			|| data.type == Json.Type.bool_
			|| data.type == Json.Type.float_
			|| data.type == Json.Type.int_
			|| data.type == Json.Type.string;
}

bool dataIsEmpty(ref const(Json) data) {
	import std.experimental.logger;
	if(data.type == Json.Type.object) {
		foreach(key, value; data.byKeyValue()) {
			if(key != "error" && !value.dataIsEmpty()) {
				return false;
			}
		}
	} else if(data.type == Json.Type.null_
			|| data.type == Json.Type.undefined
		)
	{
		return true;
	} else if(data.type == Json.Type.array) {
		return false;
	} else if(data.type == Json.Type.bigInt
			|| data.type == Json.Type.bool_
			|| data.type == Json.Type.float_
			|| data.type == Json.Type.int_
			|| data.type == Json.Type.string
		)
	{
		return false;
	}

	return true;
}

unittest {
	string t = `{
              "kind": {},
              "fields": null,
              "name": {}
            }`;
	Json j = parseJsonString(t);
	assert(j.dataIsEmpty());
}

/** Merge two Json objects.
Values in a take precedence over values in b.
*/
Json joinJson(Json a, Json b) {
	// we can not merge null or undefined values
	if(a.type == Json.Type.null_ || a.type == Json.Type.undefined) {
		return b;
	}
	if(b.type == Json.Type.null_ || b.type == Json.Type.undefined) {
		return a;
	}

	// we need objects to merge
	if(a.type == Json.Type.object && b.type == Json.Type.object) {
		Json ret = a.clone();
		foreach(key, value; b.byKeyValue()) {
			if(key !in ret) {
				ret[key] = value;
			}
		}
		return ret;
	}
	return a;
}

unittest {
	Json a = parseJsonString(`{"overSize":200}`);
	Json b = parseJsonString(`{}`);
	Json c = joinJson(b, a);
	assert(c == a);
}

template toType(T) {
	import std.bigint : BigInt;
	import std.traits : isArray, isIntegral, isAggregateType, isFloatingPoint,
		   isSomeString;
	static if(is(T == bool)) {
		enum toType = Json.Type.bool_;
	} else static if(isIntegral!(T)) {
		enum toType = Json.Type.int_;
	} else static if(isFloatingPoint!(T)) {
		enum toType = Json.Type.float_;
	} else static if(isSomeString!(T)) {
		enum toType = Json.Type.string;
	} else static if(isArray!(T)) {
		enum toType = Json.Type.array;
	} else static if(isAggregateType!(T)) {
		enum toType = Json.Type.object;
	} else static if(is(T == BigInt)) {
		enum toType = Json.Type.bigint;
	} else {
		enum toType = Json.Type.undefined;
	}
}

bool hasPathTo(T)(Json data, string path, ref T ret) {
	enum TT = toType!T;
	auto sp = path.splitter(".");
	string f;
	while(!sp.empty) {
		f = sp.front;
		sp.popFront();
		if(data.type != Json.Type.object || f !in data) {
			return false;
		} else {
			data = data[f];
		}
	}
	if(data.type == TT) {
		ret = data.to!T();
		return true;
	}
	return false;
}

/**
params:
	path = A "." seperated path
*/
T getWithDefault(T)(Json data, string[] paths...) {
	enum TT = toType!T;
	T ret = T.init;
	foreach(string path; paths) {
		if(hasPathTo!T(data, path, ret)) {
			return ret;
		}
	}
	return ret;
}

unittest {
	Json d = parseJsonString(`{"error":[],"data":{"commanderId":8,
			"__typename":"Starship","series":["DeepSpaceNine",
			"TheOriginalSeries"],"id":43,"name":"Defiant","size":130,
			"crewIds":[9,10,11,1,12,13,8],"designation":"NX-74205"}}`);
	string r = d.getWithDefault!string("data.__typename");
	assert(r == "Starship", r);
}

unittest {
	Json d = parseJsonString(`{"commanderId":8,
			"__typename":"Starship","series":["DeepSpaceNine",
			"TheOriginalSeries"],"id":43,"name":"Defiant","size":130,
			"crewIds":[9,10,11,1,12,13,8],"designation":"NX-74205"}`);
	string r = d.getWithDefault!string("data.__typename", "__typename");
	assert(r == "Starship", r);
}

unittest {
	Json d = parseJsonString(`{"commanderId":8,
			"__typename":"Starship","series":["DeepSpaceNine",
			"TheOriginalSeries"],"id":43,"name":"Defiant","size":130,
			"crewIds":[9,10,11,1,12,13,8],"designation":"NX-74205"}`);
	string r = d.getWithDefault!string("__typename");
	assert(r == "Starship", r);
}
