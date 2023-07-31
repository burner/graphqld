module graphql.helper;

import std.array : array, assocArray, empty;
import std.algorithm.iteration : each, map, splitter;
import std.algorithm.searching : startsWith, endsWith, canFind;
import std.conv : to;
import std.datetime : DateTime, Date;
import std.exception : enforce, assertThrown;
import std.format : format;
import std.stdio;
import std.traits;
import std.string : capitalize, indexOf, strip;
import std.typecons : nullable, tuple, Nullable;

import vibe.data.json;

import graphql.ast;
import graphql.uda;
import graphql.constants;
import graphql.exception;
import graphql.schema.types;

@safe:

/** dmd and ldc have problems with generation all functions
This functions call functions that were undefined.
*/
private void undefinedFunctions() @trusted {
	static import core.internal.hash;
	static import graphql.schema.introspectiontypes;

	const(graphql.schema.introspectiontypes.__Type)[] tmp;
	core.internal.hash.hashOf!(const(graphql.schema.introspectiontypes.__Type)[])
		(tmp, 0);
}

enum d = "data";
enum e = Constants.errors;

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
	ret[Constants.errors] = Json.emptyArray();
	return ret;
}

void insertError(T)(ref Json result, T t) {
	insertError(result, t, []);
}

void insertError(T)(ref Json result, T t, PathElement[] path) {
	Json tmp = Json.emptyObject();
	tmp["message"] = serializeToJson(t);
	if(!path.empty) {
		tmp["path"] = Json.emptyArray();
		foreach(it; path) {
			tmp["path"] ~= it.toJson();
		}
	}
	if(e !in result) {
		result[e] = Json.emptyArray();
	}
	enforce(result[e].type == Json.Type.array);
	result[e] ~= tmp;
}

void insertPayload(ref Json result, string field, Json data) {
	if(d in data) {
		if(d !in result) {
			result[d] = Json.emptyObject();
		}
		enforce(result[d].type == Json.Type.object, "Expected Json.Type.object"
				~ " got " ~ result[d].toPrettyString());
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

void insertPayload(ref Json result, Json data) @trusted {
	if(d in data) {
		if(d !in result) {
			result[d] = Json.emptyObject();
		}
		enforce(result[d].type == Json.Type.object);
		foreach(string key, ref Json value; data[d]) {
			Json* df = key in result[d];
			if(df) {
				result[d][key] = joinJson(*df, value);
			} else {
				result[d][key] = value;
			}
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
	if(data.type == Json.Type.object) {
		foreach(key, value; data.byKeyValue()) {
			if(key != Constants.errors && !value.dataIsEmpty()) {
			//if(key != Constants.errors) { // Issue #22 place to look at
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
	string t = `{ "errors" : {} }`;
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
	//enforce(data.type == Json.Type.object, format("%s", data));
	if(data.type == Json.Type.object) {
		if(const(Json)* d = "data" in data) {
			return d.type == Json.Type.null_;
		}
	}
	return false;
}

Json getWithPath(Json input, string path) {
	auto sp = path.splitter(".");
	foreach(s; sp) {
		Json* n = s in input;
		enforce(n !is null, "failed to traverse the input at " ~ s);
		input = *n;
	}
	return input;
}

unittest {
	string t =
`{
	"name" : {
		"foo" : 13
	}
}`;
	Json j = parseJsonString(t);
	Json f = j.getWithPath("name");
	assert("foo" in f);

	f = j.getWithPath("name.foo");
	enforce(f.to!int() == 13);

	assertThrown(j.getWithPath("doesnotexist"));
	assertThrown(j.getWithPath("name.alsoNotThere"));
}

Json getWithPath2(Json input, string path) {
	auto sp = path.splitter(".");
	foreach(s; sp) {
		Json* n = s in input;
        if(n is null || (*n).type == Json.Type.null_) {
            return Json(null);
        }
		input = *n;
	}
	return input;
}

unittest {
	string t =
`{
	"name" : {
		"foo" : 13
	}
}`;
	Json j = parseJsonString(t);
	Json f = j.getWithPath2("name");
	assert("foo" in f);

	f = j.getWithPath2("name.foo");
	enforce(f.to!int() == 13);

	Json h = j.getWithPath("doesnotexist");
	assert(h.type == Json.Type.null_);

	h = j.getWithPath("name.alsoNotThere");
	assert(h.type == Json.Type.null_);
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
					enforce(ap.type == value.type && *ap == value
						, format("Can not join '%s' and '%s' on key '%s'"
							, ap.type, value.type, key)
					);
				} else static if(jjp == JoinJsonPrecedence.a) {
				} else {
					ret[key] = value;
				}
			}
		}
		return ret;
	}
	if(a.type == Json.Type.array && b.type == Json.Type.array) {
		Json[] aArr = a.get!(Json[])();
		Json[] bArr = b.get!(Json[])();
		enforce(aArr.length == bArr.length, "a and b must be of same length"
				~ " got a: " ~ a.toPrettyString() ~ " and b: "
				~ b.toPrettyString());
		Json[] ret;
		foreach(idx; 0 .. aArr.length) {
			ret ~= joinJson!(jjp)(aArr[idx], bArr[idx]);
		}
		return Json(ret);
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
	immutable Json r = parseJsonString(`{"overSize":200, "underSize":-100}`);
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

unittest {
	Json d = parseJsonString(`{ "foo" : { "path" : "foo" } }`);
	Json ret;
	assert(hasPathTo!Json(d, "foo", ret));
	assert("path" in ret);
	assert(ret["path"].type == Json.Type.string);
	assert(ret["path"].get!string() == "foo");
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
	Json d = parseJsonString(`{"errors":[],"data":{"commanderId":8,
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
			mixin(format(
				`if(tmp%d is null) return null;
				auto tmp%d = tmp%d.%s;`, idx, idx+1, idx, token)
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

T jsonTo(T)(Json item) {
	static import std.conv;
	static if(is(T == enum)) {
		enforce!GQLDExecutionException(item.type == Json.Type.string,
			format("Enum '%s' must be passed as string not '%s'",
				T.stringof, item.type));

		string s = item.to!string();
		try {
			return std.conv.to!T(s);
		} catch(Exception c) {
			throw new GQLDExecutionException(c.msg);
		}
	} else static if(is(T == GQLDCustomLeaf!Fs, Fs...)) {
		enforce!GQLDExecutionException(item.type == Json.Type.string,
			format("%1$s '%1$s' must be passed as string not '%2$s'",
				T.stringof, item.type));

		string s = item.to!string();
		try {
			return T(Fs[2](s));
		} catch(Exception c) {
			throw new GQLDExecutionException(c.msg);
		}
	} else {
		try {
			return item.to!T();
		} catch(Exception c) {
			throw new GQLDExecutionException(c.msg);
		}
	}
}

T extract(T)(Json data, string name) {
	enforce!GQLDExecutionException(data.type == Json.Type.object, format(
			"Trying to get a '%s' by name '%s' but passed Json is not an object"
			, T.stringof, name)
		);

	Json* item = name in data;

	enforce!GQLDExecutionException(item !is null, format(
			"Trying to get a '%s' by name '%s' which is not present in passed "
			~ "object '%s'"
			, T.stringof, name, data)
		);

	return jsonTo!(T)(*item);
}

unittest {
	import std.exception : assertThrown;
	Json j = parseJsonString(`null`);
	assertThrown(j.extract!string("Hello"));
}

unittest {
	enum E {
		no,
		yes
	}
	import std.exception : assertThrown;
	Json j = parseJsonString(`{ "foo": 1337 }`);

	assertThrown(j.extract!E("foo"));

	j = parseJsonString(`{ "foo": "str" }`);
	assertThrown(j.extract!E("foo"));

	j = parseJsonString(`{ "foo": "yes" }`);
	assert(j.extract!E("foo") == E.yes);
}

unittest {
	import std.exception : assertThrown;
	Json j = parseJsonString(`{ "foo": 1337 }`);
	immutable auto foo = j.extract!int("foo");

	assertThrown(Json.emptyObject().extract!float("Hello"));
	assertThrown(j.extract!string("Hello"));
}

unittest {
	import std.exception : assertThrown;
	enum FooEn {
		a,
		b
	}
	Json j = parseJsonString(`{ "foo": "a" }`);
	immutable auto foo = j.extract!FooEn("foo");
	assert(foo == FooEn.a);

	assertThrown(Json.emptyObject().extract!float("Hello"));
	assertThrown(j.extract!string("Hello"));
	assert(j["foo"].jsonTo!FooEn() == FooEn.a);

	Json k = parseJsonString(`{ "foo": "b" }`);
	assert(k["foo"].jsonTo!FooEn() == FooEn.b);
}

const(Document) lexAndParse(string s) {
	import graphql.lexer;
	import graphql.parser;
	auto l = Lexer(s, QueryParser.no);
	auto p = Parser(l);
	const(Document) doc = p.parseDocument();
	return doc;
}

struct StringTypeStrip {
	string input;
	string str;
	bool outerNotNull;
	bool arr;
	bool innerNotNull;

	string toString() const {
		import std.format : format;
		return format("StringTypeStrip(input:'%s', str:'%s', "
			   ~ "arr:'%s', outerNotNull:'%s', innerNotNull:'%s')",
			   this.input, this.str, this.arr, this.outerNotNull,
			   this.innerNotNull);
	}
}

StringTypeStrip stringTypeStrip(string str) {
	Nullable!StringTypeStrip gqld = gqldStringTypeStrip(str);
	return gqld.get();
	//return gqld.isNull()
	//	? dlangStringTypeStrip(str)
	//	: gqld.get();
}

private Nullable!StringTypeStrip gqldStringTypeStrip(string str) {
	StringTypeStrip ret;
	ret.input = str;
	immutable string old = str;
	bool firstBang;
	if(str.endsWith('!')) {
		firstBang = true;
		str = str[0 .. $ - 1];
	}

	bool arr;
	if(str.startsWith('[') && str.endsWith(']')) {
		arr = true;
		str = str[1 .. $ - 1];
	}

	bool secondBang;
	if(str.endsWith('!')) {
		secondBang = true;
		str = str[0 .. $ - 1];
	}

	if(arr) {
		ret.innerNotNull = secondBang;
		ret.outerNotNull = firstBang;
	} else {
		ret.innerNotNull = firstBang;
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

	ret.arr = arr;

	ret.str = str;
	//writefln("%s %s", __LINE__, ret);

	//return old == str ? Nullable!(StringTypeStrip).init : nullable(ret);
	return nullable(ret);
}

unittest {
	auto a = gqldStringTypeStrip("String");
	assert(!a.isNull());

	a = gqldStringTypeStrip("String!");
	assert(!a.isNull());
	assert(a.get().str == "String");
	assert(a.get().innerNotNull, format("%s", a.get()));

	a = gqldStringTypeStrip("[String!]");
	assert(!a.isNull());
	assert(a.get().str == "String");
	assert(a.get().arr, format("%s", a.get()));
	assert(a.get().innerNotNull, format("%s", a.get()));

	a = gqldStringTypeStrip("[String]!");
	assert(!a.isNull());
	assert(a.get().str == "String");
	assert(a.get().arr, format("%s", a.get()));
	assert(!a.get().innerNotNull, format("%s", a.get()));
	assert(a.get().outerNotNull, format("%s", a.get()));

	a = gqldStringTypeStrip("[String!]!");
	assert(!a.isNull());
	assert(a.get().str == "String");
	assert(a.get().arr, format("%s", a.get()));
	assert(a.get().innerNotNull, format("%s", a.get()));
	assert(a.get().outerNotNull, format("%s", a.get()));
}

private StringTypeStrip dlangStringTypeStrip(string str) {
	StringTypeStrip ret;
	ret.outerNotNull = true;
	ret.innerNotNull = true;
	ret.input = str;

	immutable ns = "NullableStore!";
	immutable ns1 = "NullableStore!(";
	immutable leaf = "GQLDCustomLeaf!";
	immutable leaf1 = "GQLDCustomLeaf!(";
	immutable nll = "Nullable!";
	immutable nll1 = "Nullable!(";

	// NullableStore!( .... )
	if(str.startsWith(ns1) && str.endsWith(")")) {
		str = str[ns1.length .. $ - 1];
	}

	// NullableStore!....
	if(str.startsWith(ns)) {
		str = str[ns.length .. $];
	}

	// GQLDCustomLeaf!( .... )
	if(str.startsWith(leaf1) && str.endsWith(")")) {
		str = str[leaf1.length .. $ - 1];
	}

	bool firstNull;

	// Nullable!( .... )
	if(str.startsWith(nll1) && str.endsWith(")")) {
		firstNull = true;
		str = str[nll1.length .. $ - 1];
	}

	// NullableStore!( .... )
	if(str.startsWith(ns1) && str.endsWith(")")) {
		str = str[ns1.length .. $ - 1];
	}

	// NullableStore!....
	if(str.startsWith(ns)) {
		str = str[ns.length .. $];
	}

	if(str.endsWith("!")) {
		str = str[0 .. $ - 1];
	}

	// xxxxxxx[]
	if(str.endsWith("[]")) {
		ret.arr = true;
		str = str[0 .. $ - 2];
	}

	bool secondNull;

	// Nullable!( .... )
	if(str.startsWith(nll1) && str.endsWith(")")) {
		secondNull = true;
		str = str[nll1.length .. $ - 1];
	}

	if(str.endsWith("!")) {
		str = str[0 .. $ - 1];
	}

	// Nullable! ....
	if(str.startsWith(nll)) {
		secondNull = true;
		str = str[nll.length .. $];
	}

	// NullableStore!( .... )
	if(str.startsWith(ns1) && str.endsWith(")")) {
		str = str[ns1.length .. $ - 1];
	}

	// NullableStore!....
	if(str.startsWith(ns)) {
		str = str[ns.length .. $];
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

	//writefln("firstNull %s, secondNull %s, arr %s", firstNull, secondNull,
	//		ret.arr);

	if(ret.arr) {
		ret.innerNotNull = !secondNull;
		ret.outerNotNull = !firstNull;
	} else {
		ret.innerNotNull = !secondNull;
	}

	ret.str = str;
	return ret;
}

unittest {
	string t = "Nullable!string";
	StringTypeStrip r = t.dlangStringTypeStrip();
	assert(r.str == "String", to!string(r));
	assert(!r.arr, to!string(r));
	assert(!r.innerNotNull, to!string(r));
	assert(r.outerNotNull, to!string(r));

	t = "Nullable!(string[])";
	r = t.dlangStringTypeStrip();
	assert(r.str == "String", to!string(r));
	assert(r.arr, to!string(r));
	assert(r.innerNotNull, to!string(r));
	assert(!r.outerNotNull, to!string(r));
}

unittest {
	string t = "Nullable!__type";
	StringTypeStrip r = t.dlangStringTypeStrip();
	assert(r.str == "__Type", to!string(r));
	assert(!r.innerNotNull, to!string(r));
	assert(r.outerNotNull, to!string(r));
	assert(!r.arr, to!string(r));

	t = "Nullable!(__type[])";
	r = t.dlangStringTypeStrip();
	assert(r.str == "__Type", to!string(r));
	assert(r.innerNotNull, to!string(r));
	assert(!r.outerNotNull, to!string(r));
	assert(r.arr, to!string(r));
}

template isClass(T) {
	enum isClass = is(T == class);
}

unittest {
	static assert(!isClass!int);
	static assert( isClass!Object);
}

template isNotInTypeSet(T, R...) {
	import std.meta : staticIndexOf;
	enum isNotInTypeSet = staticIndexOf!(T, R) == -1;
}

string getTypename(Schema,T)(auto ref T input, Schema schema) @trusted {
	return T.stringof;
}

Json toGraphqlJson(Schema,T)(auto ref T input, Schema schema) {
	import std.array : empty;
	import std.conv : to;
	import std.typecons : Nullable;
	import std.traits : isArray, isAggregateType, isBasicType, isSomeString,
		   isScalarType, isSomeString, FieldNameTuple, FieldTypeTuple;

	import nullablestore;

	static if(isArray!T && !isSomeString!T) {
		Json ret = Json.emptyArray();
		foreach(ref it; input) {
			ret ~= toGraphqlJson(it, schema);
		}
		return ret;
	} else static if(is(T : GQLDCustomLeaf!Type, Type...)) {
		return Json(Type[1](input));
	} else static if(is(T : Nullable!Type, Type)) {
		return input.isNull() ? Json(null) : toGraphqlJson(input.get(), schema);
	} else static if(is(T == enum)) {
		return Json(to!string(input));
	} else static if(isBasicType!T || isScalarType!T || isSomeString!T) {
		return serializeToJson(input);
	} else static if(isAggregateType!T) {
		Json ret = Json.emptyObject();

		// the important bit is the setting of the __typename field
		ret["__typename"] = getTypename!(Schema)(input, schema);
		alias names = __traits(allMembers, T);
		static foreach(idx; 0 .. names.length) {{
			static if(!__traits(hasMember, Object, names[idx])) {
				static if(__traits(compiles, typeof(__traits(getMember, input,
									names[idx]))))
				{
					alias IdxType = typeof(__traits(getMember, input, names[idx]));
					enum bool keep = true;
				} else {
					alias IdxType = __traits(getMember, input, names[idx]); // alias
					enum bool keep = false;
				}
				static if(keep && !names[idx].empty && !isNameSpecial(names[idx])
						&& getUdaData!(T, names[idx]).ignore != Ignore.yes
						&& !is(IdxType : NullableStore!Type, Type))
				{
					static if(is(IdxType == enum)) {
						ret[names[idx]] =
							to!string(__traits(getMember, input, names[idx]));
					} else static if(!isCallable!IdxType) {
						ret[names[idx]] = toGraphqlJson(
								__traits(getMember, input, names[idx])
								, schema
							);
					}
				}
			}
		}}
		return ret;
	} else {
		static assert(false, T.stringof ~ " not supported");
	}
}

string dtToString(DateTime dt) {
	return dt.toISOExtString();
}

DateTime stringToDT(string s) {
	return DateTime.fromISOExtString(s);
}

string dToString(Date dt) {
	return dt.toISOExtString();
}

unittest {
	import std.typecons : nullable, Nullable;
	import nullablestore;

	struct Foo {
		int a;
		Nullable!int b;
		NullableStore!float c;
		GQLDCustomLeaf!(DateTime, dtToString, stringToDT) dt2;
		Nullable!(GQLDCustomLeaf!(DateTime, dtToString, stringToDT)) dt;
	}

	DateTime dt = DateTime(1337, 7, 1, 1, 1, 1);
	DateTime dt2 = DateTime(2337, 7, 1, 1, 1, 3);

	alias DT = GQLDCustomLeaf!(DateTime, dtToString, stringToDT);

	Foo foo;
	foo.dt2 = DT(dt2);
	foo.dt = nullable(DT(dt));
	Json j = toGraphqlJson(foo, null);
	assert(j["a"].to!int() == 0);
	assert(j["b"].type == Json.Type.null_);
	assert(j["dt"].type == Json.Type.string, format("%s\n%s", j["dt"].type,
				j.toPrettyString()
			)
		);
	immutable string exp = j["dt"].to!string();
	assert(exp == "1337-07-01T01:01:01", exp);
	immutable string exp2 = j["dt2"].to!string();
	assert(exp2 == "2337-07-01T01:01:03", exp2);

	immutable DT back = extract!DT(j, "dt");
	assert(back.value == dt);

	immutable DT back2 = extract!DT(j, "dt2");
	assert(back2.value == dt2);
}

struct PathElement {
	string str;
	size_t idx;

	static PathElement opCall(string s) {
		PathElement ret;
		ret.str = s;
		return ret;
	}

	static PathElement opCall(size_t s) {
		PathElement ret;
		ret.idx = s;
		return ret;
	}

	Json toJson() {
		return this.str.empty ? Json(this.idx) : Json(this.str);
	}
}

struct JsonCompareResult {
	bool okay;
	string[] path;
	string message;
	long onLine;
}

JsonCompareResult compareJson(Json a, Json b, string path
		, bool allowArrayReorder, bool trace = false)
{
	import std.algorithm.comparison : min;
	import std.algorithm.setops : setDifference;
	import std.algorithm.sorting : sort;
	import std.math : isClose;

	if(trace) {
		writefln("\na: %s\nb: %s", a, b);
	}

	if(a.type != b.type) {
		return JsonCompareResult(false, [path], format("a.type %s != b.type %s"
					, a.type, b.type), __LINE__);
	}

	if(a.type == Json.Type.null_) {
		return JsonCompareResult(true, [path], "", __LINE__);
	} else if(a.type == Json.Type.array) {
		Json[] aArray = a.get!(Json[])();
		Json[] bArray = b.get!(Json[])();

		size_t minLength = min(aArray.length, bArray.length);
		if(allowArrayReorder) {
			outer: foreach(idx, it; aArray) {
				foreach(jt; bArray) {
					JsonCompareResult idxRslt = compareJson(it, jt
							, format("[%s]", idx), allowArrayReorder, trace);
					if(idxRslt.okay) {
						continue outer;
					}
				}
				return JsonCompareResult(false, [ format("[%s]", idx) ]
						, format("No array element of 'b' matches %s", it)
						, __LINE__);
			}
		} else {
			foreach(idx; 0 .. minLength) {
				JsonCompareResult idxRslt = compareJson(aArray[idx]
						, bArray[idx], format("[%s]", idx), allowArrayReorder
						, trace);
				if(!idxRslt.okay) {
					return JsonCompareResult(false, [path] ~ idxRslt.path,
							idxRslt.message, __LINE__);
				}
			}
		}

		if(aArray.length != bArray.length) {
			return JsonCompareResult(false, [path]
					, format("a.length %s != b.length %s", aArray.length
						, bArray.length), __LINE__);
		}

		return JsonCompareResult(true, [path], "");
	} else if(a.type == Json.Type.object) {
		Json[string] aObj = a.get!(Json[string])();
		Json[string] bObj = b.get!(Json[string])();

		foreach(key, value; aObj) {
			Json* bVal = key in bObj;
			if(bVal is null) {
				return JsonCompareResult(false, [path]
						, format("a[\"%s\"] not in b", key), __LINE__);
			} else {
				JsonCompareResult keyRslt = compareJson(value
						, *bVal, format("[\"%s\"]", key), allowArrayReorder
						, trace);
				if(!keyRslt.okay) {
					return JsonCompareResult(false, [path] ~ keyRslt.path,
							keyRslt.message, __LINE__);
				}
			}
		}
		auto aKeys = aObj.keys.sort;
		auto bKeys = bObj.keys.sort;

		auto aMinusB = setDifference(aKeys, bKeys);
		auto bMinusA = setDifference(bKeys, aKeys);

		if(!aMinusB.empty && !bMinusA.empty) {
			return JsonCompareResult(false, [path]
					, format("keys present in 'a' but not in 'b' %s, keys "
						~ "present in 'b' but not in 'a' %s", aMinusB
						, bMinusA), __LINE__);
		} else if(aMinusB.empty && !bMinusA.empty) {
			return JsonCompareResult(false, [path]
					, format("keys present in 'b' but not in 'a' %s", bMinusA)
					, __LINE__);
		} else if(!aMinusB.empty && bMinusA.empty) {
			return JsonCompareResult(false, [path]
					, format("keys present in 'a' but not in 'b' %s", aMinusB)
					, __LINE__);
		}

		return JsonCompareResult(true, [path], "");
	} else if(a.type == Json.Type.Bool) {
		const aBool = a.get!bool();
		const bBool = b.get!bool();
		return JsonCompareResult(aBool == bBool, [path], format("%s != %s", aBool
					, bBool), __LINE__);
	} else if(a.type == Json.Type.Int) {
		const aLong = a.get!long();
		const bLong = b.get!long();
		return JsonCompareResult(aLong == bLong, [path], format("%s != %s", aLong
					, bLong), __LINE__);
	} else if(a.type == Json.Type.string) {
		const aStr = a.get!string();
		const bStr = b.get!string();
		return JsonCompareResult(aStr == bStr, [path], format("%s != %s", aStr
					, bStr), __LINE__);
	} else if(a.type == Json.Type.Float) {
		const aFloat = a.get!double();
		const bFloat = b.get!double();
		return JsonCompareResult(isClose(aFloat, bFloat), [path]
				, format("%s != %s", aFloat, bFloat), __LINE__);
	}
	return JsonCompareResult(false, [path], "", __LINE__);
}

bool isNameSpecial(string s) {
	// takes care of gql buildins (__Type, __TypeKind, etc.), as well as
	// some unuseful pieces from the d side (__ctor, opCmp, etc.)
	return s.startsWith("__") || s.startsWith("op") || ["factory", "toHash", "toString"].canFind(s);
}

// all members of o, including derived ones
GQLDType[string] allMember(GQLDMap m) @safe {
	import std.algorithm;
	GQLDType[string] ret;

	void process(GQLDMap m) {
		foreach(k, v; m.member) {
			ret.require(k,v);
		}

		if(auto o = cast(GQLDObject)m) {
			if(o.base) {
				process(o.base);
			}
		}
	}

	// inout(V)[K].require is broken
	process(m);
	return ret;
}
