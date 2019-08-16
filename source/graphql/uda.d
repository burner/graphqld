module graphql.uda;

import std.array : empty;
import std.traits : isBuiltinType;

@safe:

enum TypeKind {
	UNDEFINED,
	SCALAR,
	OBJECT,
	INTERFACE,
	UNION,
	ENUM,
	INPUT_OBJECT,
	LIST,
	NON_NULL
}

struct GQLDUdaData {
	TypeKind typeKind;
	GQLDDeprecatedData deprecationInfo;
	GQLDDescription description;
	Ignore ignore;
	IgnoreForInput ignoreForInput;
	RequiredForInput requiredForInput;
}

enum IgnoreForInput {
	undefined,
	yes,
	no
}

enum RequiredForInput {
	undefined,
	yes,
	no
}

enum Ignore {
	undefined,
	yes,
	no
}

enum IsDeprecated {
	undefined,
	yes,
	no
}

string toStringImpl(T)(T t) {
	static if(__traits(hasMember, T, "toString")) {
		return t.toString();
	} else {
		import std.format : format;
		return format("%s", t);
	}
}

/* The wrapped
	T = the wrapped type
	SerializationFun = the function to use to serialize T
*/
struct GQLDCustomLeaf(T, alias SerializationFun = toStringImpl!T) {
	alias Type = T;
	Type value;
	alias value this;

	alias Fun = SerializationFun;

	this(Type value) {
		this.value = value;
	}

	void opAssign(Type value) {
		this.value = value;
	}
}

unittest {
	import std.datetime : DateTime;
	import vibe.data.json;

	Json fun(DateTime dt) {
		return Json(dt.toISOExtString());
	}

	auto f = GQLDCustomLeaf!DateTime();

	GQLDCustomLeaf!DateTime dt = DateTime(1337, 1, 1);
}

unittest {
	import std.typecons : Nullable, nullable;
	import std.datetime : DateTime;
	Nullable!(GQLDCustomLeaf!DateTime) dt;
}

struct GQLDDeprecatedData {
	IsDeprecated isDeprecated;
	string deprecationReason;
}

struct GQLDDescription {
	string text;
	string getText() const {
		return text !is null && text.empty ? this.text : "";
	}
}

GQLDDeprecatedData GQLDDeprecated(IsDeprecated isDeprecated) {
	return GQLDDeprecatedData(isDeprecated, "");
}

GQLDDeprecatedData GQLDDeprecated(IsDeprecated isDeprecated,
		string deprecationReason)
{
	return GQLDDeprecatedData(isDeprecated, deprecationReason);
}

GQLDUdaData GQLDUda(Args...)(Args args) {
	GQLDUdaData ret;
	static foreach(mem; __traits(allMembers, GQLDUdaData)) {
		static foreach(arg; args) {
			static if(is(typeof(__traits(getMember, ret, mem)) ==
						typeof(arg)))
			{
				__traits(getMember, ret, mem) = arg;
			}
		}
	}
	return ret;
}

private template isGQLDUdaData(alias Type) {
	enum isGQLDUdaData = is(typeof(Type) == GQLDUdaData);
}

private template getGQLDUdaData(Type, string mem) {
	import std.meta : Filter;
	alias getGQLDUdaData =
		Filter!(isGQLDUdaData,
				__traits(getAttributes, __traits(getMember, Type, mem)));
}

private template getGQLDUdaData(Type) {
	import std.meta : Filter;
	alias getGQLDUdaData =
		Filter!(isGQLDUdaData, __traits(getAttributes, Type));
}

template getUdaData(Type) {
	static if(isBuiltinType!Type) {
		enum getUdaData = GQLDUdaData.init;
	} else {
		alias GQLDUdaDataAS = getGQLDUdaData!Type;
		static if(GQLDUdaDataAS.length > 0) {
			enum getUdaData = GQLDUdaDataAS[0];
		} else {
			enum getUdaData = GQLDUdaData.init;
		}
	}
}

template getUdaData(Type, string mem) {
	alias GQLDUdaDataAS = getGQLDUdaData!(Type, mem);
	static if(GQLDUdaDataAS.length > 0) {
		enum  getUdaData = GQLDUdaDataAS[0];
	} else {
		enum  getUdaData = GQLDUdaData.init;
	}
}

unittest {
	@GQLDUda(
		GQLDDeprecated(IsDeprecated.yes, "Stupid name"),
		GQLDDescription("You normal test struct")
	)
	struct Foo {
		@GQLDUda(
			GQLDDeprecated(IsDeprecated.no, "Very good name"),
			GQLDDescription("Contains something")
		)
		int bar;

		int args;
	}

	enum GQLDUdaData fd = getUdaData!Foo;
	static assert(fd.deprecationInfo.isDeprecated == IsDeprecated.yes);
	static assert(fd.deprecationInfo.deprecationReason == "Stupid name");
	static assert(fd.description.text == "You normal test struct");

	enum GQLDUdaData bd = getUdaData!(Foo, "bar");
	static assert(bd.deprecationInfo.isDeprecated == IsDeprecated.no);
	static assert(bd.deprecationInfo.deprecationReason == "Very good name");
	static assert(bd.description.text == "Contains something");

	enum GQLDUdaData ad = getUdaData!(Foo, "args");
	static assert(ad.deprecationInfo.isDeprecated == IsDeprecated.undefined);
	static assert(ad.deprecationInfo.deprecationReason == "");
	static assert(ad.description.text == "");
}
