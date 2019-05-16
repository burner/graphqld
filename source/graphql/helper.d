module graphql.helper;

import std.algorithm.searching : canFind;
import std.algorithm.iteration : splitter;
import std.format : format;
import std.exception : enforce, assertThrown;
import std.experimental.logger;

import vibe.data.json;

import graphql.ast;

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
		Json* df = field in result[d];
		if(df) {
			result[d][field] = joinJson(*df, data[d]);
		} else {
			result[d][field] = data[d];
		}
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

unittest {
	Json old = returnTemplate();
	old["data"]["foo"] = Json.emptyObject();
	old["data"]["foo"]["a"] = 1337;

	Json n = returnTemplate();
	n["data"] = Json.emptyObject();
	n["data"]["b"] = 1338;

	old.insertPayload("foo", n);
	assert(old["data"]["foo"].length == 2, format("%s %s",
			old["data"]["foo"].length, old.toPrettyString())
		);
	assert("a" in old["data"]["foo"]);
	assert("b" in old["data"]["foo"]);
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
			//if(key != "error") { // Issue #22 place to look at
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
	string t = `{ "error": {} }`;
	Json j = parseJsonString(t);
	assert(j.dataIsEmpty());
}

unittest {
	string t = `{ "kind": {}, "fields": null, "name": {} }`;
	Json j = parseJsonString(t);
	//assert(!j.dataIsEmpty()); // Enable if you don't want to trim. Issue #22
	assert(j.dataIsEmpty());
}

unittest {
	string t =
`{
	"name" : {
		"foo" : null
	}
}`;
	Json j = parseJsonString(t);
	//assert(!j.dataIsEmpty()); // Enable if you don't want to trim. Issue #22
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

enum JoinJsonPrecedence {
	none,
	a,
	b
}

/** Merge two Json objects.
Values in a take precedence over values in b.
*/
Json joinJson(JoinJsonPrecedence jjp = JoinJsonPrecedence.none)(Json a, Json b)
{
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
			Json* ap = key in ret;
			if(ap is null) {
				ret[key] = value;
			} else if(ap.type == Json.Type.object
					&& value.type == Json.Type.object)
			{
				ret[key] = joinJson(*ap, value);
			} else {
				static if(jjp == JoinJsonPrecedence.none) {
					throw new Exception(format(
							"Can not join '%s' and '%s' on key '%s'",
							ap.type, value.type, key));
				} else static if(jjp == JoinJsonPrecedence.a) {
				} else {
					ret[key] = value;
				}
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

	b = parseJsonString(`{"underSize":-100}`);
	const d = joinJson(b, a);
	Json r = parseJsonString(`{"overSize":200, "underSize":-100}`);
	assert(d == r);
}

unittest {
	Json j = joinJson(parseJsonString(`{"underSize": {"a": -100}}`),
			parseJsonString(`{"underSize": {"b": 100}}`)
		);

	Json r = parseJsonString(`{"underSize": {"a": -100, "b": 100}}`);
	assert(j == r, format("%s\n\n%s", j.toPrettyString(), r.toPrettyString()));
}

unittest {
	assertThrown(joinJson(parseJsonString(`{"underSize": {"a": -100}}`),
			parseJsonString(`{"underSize": {"a": 100}}`)
		));
}

unittest {
	assertThrown(joinJson(parseJsonString(`{"underSize": -100}`),
			parseJsonString(`{"underSize": {"a": 100}}`)
		));
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

const(Document) lexAndParse(string s) {
	import graphql.lexer;
	import graphql.parser;
	auto l = Lexer(s, QueryParser.no);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();
	return doc;
}

string stringTypeStrip(string str) {
	import std.algorithm.searching : startsWith, endsWith, canFind;
	import std.string : capitalize;
	immutable fs = ["Nullable!", "NullableStore!", "GQLDCustomLeaf!"];
	immutable arr = "[]";
	outer: while(true) {
		foreach(f; fs) {
			if(str.startsWith(f)) {
				str = str[f.length .. $];
				continue outer;
			}
		}
		if(str.endsWith(arr)) {
			str = str[0 .. str.length - arr.length];
			continue;
		} else if(str.startsWith("[")) {
			str = str[1 .. $];
			continue;
		} else if(str.endsWith("]")) {
			str = str[0 .. $ - 1];
			continue;
		} else if(str.startsWith("(")) {
			str = str[1 .. $];
			continue;
		} else if(str.endsWith(")")) {
			str = str[0 .. $ - 1];
			continue;
		} else if(str.endsWith("'")) {
			str = str[0 .. $ - 1];
			continue;
		}
		break;
	}

	str = canFind(["ubyte", "byte", "ushort", "short", "long", "ulong"], str)
		? "Int"
		: str;

	str = canFind(["string", "int", "float", "bool"], str)
		? capitalize(str)
		: str;

	str = str == "__type" ? "__Type" : str;
	str = str == "__schema" ? "__Schema" : str;
	str = str == "__inputvalue" ? "__InputValue" : str;
	str = str == "__directive" ? "__Directive" : str;
	str = str == "__field" ? "__Field" : str;

	return str;
}

unittest {
	string t = "Nullable!string";
	string r = t.stringTypeStrip();
	assert(r == "String", r);

	t = "Nullable!(string[])";
	r = t.stringTypeStrip();
	assert(r == "String", r);
}

unittest {
	string t = "Nullable!__type";
	string r = t.stringTypeStrip();
	assert(r == "__Type", r);

	t = "Nullable!(__type[])";
	r = t.stringTypeStrip();
	assert(r == "__Type", r);
}

Json toGraphqlJson(T)(auto ref T obj) {
	import std.traits : isArray, FieldNameTuple, FieldTypeTuple;
	import std.array : empty;
	import std.typecons : Nullable;
	import nullablestore;

	alias names = FieldNameTuple!(T);
	alias types = FieldTypeTuple!(T);

	static if(isArray!T) {
		Json ret = Json.emptyArray();
		foreach(ref it; obj) {
			ret ~= toGraphqlJson(it);
		}
	} else {
		Json ret = Json.emptyObject();

		// the important bit is the setting of the __typename field
		ret["__typename"] = T.stringof;

		static foreach(idx; 0 .. names.length) {{
			static if(!names[idx].empty) {
				//writefln("%s %s", __LINE__, names[idx]);
				static if(is(types[idx] : Nullable!Type, Type)) {
					if(__traits(getMember, obj, names[idx]).isNull()) {
						ret[names[idx]] = Json(null);
					} else {
						ret[names[idx]] = serializeToJson(
								__traits(getMember, obj, names[idx])
							);
					}
				} else static if(is(types[idx] : NullableStore!Type, Type)) {
				} else {
					ret[names[idx]] = serializeToJson(
							__traits(getMember, obj, names[idx])
						);
				}
			}
		}}
	}
	return ret;
}

unittest {
	import std.typecons : Nullable;
	import nullablestore;

	struct Foo {
		int a;
		Nullable!int b;
		NullableStore!float c;
	}

	Foo foo;
	Json j = toGraphqlJson(foo);
	assert(j["a"].to!int() == 0);
	assert(j["b"].type == Json.Type.null_);
}
