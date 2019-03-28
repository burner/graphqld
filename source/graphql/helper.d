module graphql.helper;

import std.algorithm.searching : canFind;
import std.algorithm.iteration : splitter;
import std.format : format;
import std.exception : enforce;
import std.experimental.logger;

import vibe.data.json;

@safe:

enum d = "data";
enum e = "error";

string firstCharUpperCase(string input) {
	import std.conv : to;
	import std.uni : isUpper, toUpper;
	import std.array : front, popFront;
	if(isUpper(input.front)) {
		return input;
	}

	const f = input.front;
	input.popFront();

	return to!string(toUpper(f)) ~ input;
}

Json returnTemplate() {
	Json ret = Json.emptyObject();
	ret["data"] = Json.emptyObject();
	ret["error"] = Json.emptyArray();
	return ret;
}

void insertError(T)(ref Json result, T t) {
	Json err = serializeToJson(t);
	if(e !in result) {
		result[e] = Json.emptyArray();
	}
	enforce(result[e].type == Json.Type.array);
	if(!canFind(result[e].byValue(), err)) {
		result[e] ~= err;
	}
}

void insertPayload(ref Json result, string field, Json data) {
	if(d in data) {
		if(d !in result) {
			result[d] = Json.emptyObject();
		}
		enforce(result[d].type == Json.Type.object);
		result[d][field] = data[d];
	}
	if(e in data) {
		if(e !in result) {
			result[e] = Json.emptyArray();
		}
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
		return true;
	} else if(data.type == Json.Type.null_
			|| data.type == Json.Type.undefined
		)
	{
		return true;
	} else if(data.type == Json.Type.array) {
		return data.length == 0;
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

bool dataIsNull(ref const(Json) data) {
	import std.format : format;
	enforce(data.type == Json.Type.object, format("%s", data));
	if(const(Json)* d = "data" in data) {
		return d.type == Json.Type.null_;
	}
	return false;
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
	const c = joinJson(b, a);
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
	static if(is(T == Json)) {
		ret = data;
		return true;
	} else {
		if(data.type == TT) {
			ret = data.to!T();
			return true;
		}
		return false;
	}
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
	const r = d.getWithDefault!string("data.__typename");
	assert(r == "Starship", r);
}

unittest {
	Json d = parseJsonString(`{"commanderId":8,
			"__typename":"Starship","series":["DeepSpaceNine",
			"TheOriginalSeries"],"id":43,"name":"Defiant","size":130,
			"crewIds":[9,10,11,1,12,13,8],"designation":"NX-74205"}`);
	const r = d.getWithDefault!string("data.__typename", "__typename");
	assert(r == "Starship", r);
}

unittest {
	Json d = parseJsonString(`{"commanderId":8,
			"__typename":"Starship","series":["DeepSpaceNine",
			"TheOriginalSeries"],"id":43,"name":"Defiant","size":130,
			"crewIds":[9,10,11,1,12,13,8],"designation":"NX-74205"}`);
	const r = d.getWithDefault!string("__typename");
	assert(r == "Starship", r);
}

// TODO should return ref
auto accessNN(string[] tokens,T)(T tmp0) {
	import std.array : back;
	import std.format : format;
	if(tmp0 !is null) {
		static foreach(idx, token; tokens) {
			mixin(format!
				`if(tmp%d is null) return null;
				auto tmp%d = tmp%d.%s;`(idx, idx+1, idx, token)
			);
		}
		return mixin(format("tmp%d", tokens.length));
	}
	return null;
}

unittest {
	class A {
		int a;
	}

	class B {
		A a;
	}

	class C {
		B b;
	}

	auto c1 = new C;
	assert(c1.accessNN!(["b", "a"]) is null);

	c1.b = new B;
	assert(c1.accessNN!(["b"]) !is null);

	assert(c1.accessNN!(["b", "a"]) is null);
	// TODO not sure why this is not a lvalue
	//c1.accessNN!(["b", "a"]) = new A;
	c1.b.a = new A;
	assert(c1.accessNN!(["b", "a"]) !is null);
}

T extract(T)(Json data, string name) {
	enforce(data.type == Json.Type.object, format!
			"Trying to get a '%s' by name '%s' but passed Json is not an object"
			(T.stringof, name)
		);

	Json* item = name in data;

	enforce(item !is null, format!(
			"Trying to get a '%s' by name '%s' which is not present in passed "
			~ "object"
			)(T.stringof, name)
		);

	return (*item).to!T();
}

unittest {
	import std.exception : assertThrown;
	Json j = parseJsonString(`{ "foo": 1337 }`);
	auto foo = j.extract!int("foo");

	assertThrown(Json.emptyObject().extract!float("Hello"));
	assertThrown(j.extract!string("Hello"));
}
