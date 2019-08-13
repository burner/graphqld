module graphql.helper;

import std.algorithm.searching : canFind;
import std.algorithm.iteration : splitter;
import std.conv : to;
import std.format : format;
import std.exception : enforce, assertThrown;
import std.experimental.logger;
import std.stdio;
import std.datetime : DateTime;

import vibe.data.json;

import graphql.ast;
import graphql.constants;

@safe:

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
	Json tmp = Json.emptyObject();
	tmp["message"] = serializeToJson(t);
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
	import std.format : format;
	enforce(data.type == Json.Type.object, format("%s", data));
	if(const(Json)* d = "data" in data) {
		return d.type == Json.Type.null_;
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

unittest {
	Json d = parseJsonString(`{ "foo" : { "path" : "foo" } }`);
	Json ret;
	assert(hasPathTo!Json(d, "foo", ret));
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
			~ "object '%s'"
			)(T.stringof, name, data)
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

struct StringTypeStrip {
	string input;
	string str;
	bool outerNotNull;
	bool outerNull;
	bool arr;
	bool innerNotNull;
	bool innerNull;

	string toString() const {
		import std.format : format;
		return format("StringTypeStrip(input:'%s', str:'%s', outerNull:'%s', "
			   ~ "arr:'%s', innerNull:'%s')", this.input, this.str,
			   this.outerNull, this.arr, this.innerNull);
	}
}

StringTypeStrip stringTypeStrip(string str) {
	import std.algorithm.searching : startsWith, endsWith, canFind;
	import std.string : capitalize, indexOf, strip;

	StringTypeStrip ret;
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

	// Nullable!( .... )
	if(str.startsWith(nll1) && str.endsWith(")")) {
		ret.outerNull = true;
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

	// Nullable!( .... )
	if(str.startsWith(nll1) && str.endsWith(")")) {
		ret.innerNull = true;
		str = str[nll1.length .. $ - 1];
	}

	if(str.endsWith("!")) {
		str = str[0 .. $ - 1];
	}

	// Nullable! ....
	if(str.startsWith(nll)) {
		ret.innerNull = true;
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

	ret.str = str;
	return ret;
}

unittest {
	bool oNN;
	bool arr;
	bool iNN;
	string t = "Nullable!string";
	StringTypeStrip r = t.stringTypeStrip();
	assert(r.str == "String", to!string(r));
	assert(r.innerNull, to!string(r));

	t = "Nullable!(string[])";
	r = t.stringTypeStrip();
	assert(r.str == "String", to!string(r));
	assert(r.outerNull, to!string(r));
	assert(r.arr, to!string(r));
}

unittest {
	string t = "Nullable!__type";
	StringTypeStrip r = t.stringTypeStrip();
	assert(r.str == "__Type", to!string(r));

	t = "Nullable!(__type[])";
	r = t.stringTypeStrip();
	assert(r.str == "__Type", to!string(r));
	assert(r.outerNull);
	assert(r.arr);
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

string getTypename(Schema,T)(auto ref T input) @trusted {
	import std.meta : Filter, Erase, EraseAll;
	import std.traits : BaseTypeTuple, BaseClassesTuple;
	import std.stdio : writefln;
	import graphql.traits : collectTypes;
	//pragma(msg, T);
	//writefln("To %s", T.stringof);
	static if(!isClass!(T)) {
		return T.stringof;
	} else {
		alias BTT = BaseClassesTuple!T;
		alias All = collectTypes!(Schema);
		alias AllCls = Filter!(isClass, All);
		alias NoT = EraseAll!(T, AllCls);
		alias NoT2 = EraseAll!(Object, NoT);

		//pragma(msg, "\n" ~ T.stringof);
		//pragma(msg, NoT2);
		static foreach(Cls; NoT2) {
			static if(isNotInTypeSet!(Cls, BTT)) {{
				Cls t = cast(Cls)input;
				//writefln("Chk %s %s", Cls.stringof, t !is null);
				if(t !is null) {
					return Cls.stringof;
				}
			}}
		}
		return T.stringof;
	}
}

Json toGraphqlJson(Schema,T)(auto ref T input) {
	import std.array : empty;
	import std.conv : to;
	import std.typecons : Nullable;
	import std.traits : isArray, isAggregateType, isBasicType, isSomeString,
		   isScalarType, isSomeString, FieldNameTuple, FieldTypeTuple;

	import nullablestore;

	import graphql.uda : GQLDCustomLeaf;
	static if(isArray!T && !isSomeString!T) {
		Json ret = Json.emptyArray();
		foreach(ref it; input) {
			ret ~= toGraphqlJson!Schema(it);
		}
		return ret;
	} else static if(is(T : GQLDCustomLeaf!Type, Type...)) {
		return Json(Type[1](input));
	} else static if(is(T : Nullable!Type, Type)) {
		return input.isNull() ? Json(null) : toGraphqlJson!Schema(input.get());
	} else static if(is(T == enum)) {
		return Json(to!string(input));
	} else static if(isBasicType!T || isScalarType!T || isSomeString!T) {
		return serializeToJson(input);
	} else static if(isAggregateType!T) {
		Json ret = Json.emptyObject();

		// the important bit is the setting of the __typename field
		ret["__typename"] = getTypename!(Schema)(input);
		//writefln("Got %s", ret["__typename"].to!string());

		alias names = FieldNameTuple!(T);
		alias types = FieldTypeTuple!(T);
		static foreach(idx; 0 .. names.length) {{
			static if(!names[idx].empty) {
				static if(is(types[idx] : NullableStore!Type, Type)) {
				} else static if(is(types[idx] == enum)) {
					ret[names[idx]] =
						to!string(__traits(getMember, input, names[idx]));
				} else {
					ret[names[idx]] = toGraphqlJson!Schema(
							__traits(getMember, input, names[idx])
						);
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

unittest {
	import std.typecons : nullable, Nullable;
	import graphql.uda;
	import nullablestore;

	struct Foo {
		int a;
		Nullable!int b;
		NullableStore!float c;
		GQLDCustomLeaf!(DateTime, dtToString) dt2;
		Nullable!(GQLDCustomLeaf!(DateTime, dtToString)) dt;
	}

	DateTime dt = DateTime(1337, 7, 1, 1, 1, 1);
	DateTime dt2 = DateTime(2337, 7, 1, 1, 1, 3);

	Foo foo;
	foo.dt2 = GQLDCustomLeaf!(DateTime, dtToString)(dt2);
	foo.dt = nullable(GQLDCustomLeaf!(DateTime, dtToString)(dt));
	Json j = toGraphqlJson!int(foo);
	assert(j["a"].to!int() == 0);
	assert(j["b"].type == Json.Type.null_);
	assert(j["dt"].type == Json.Type.string, format("%s\n%s", j["dt"].type,
				j.toPrettyString()
			)
		);
	string exp = j["dt"].to!string();
	assert(exp == "1337-07-01T01:01:01", exp);
	string exp2 = j["dt2"].to!string();
	assert(exp2 == "2337-07-01T01:01:03", exp2);
}
