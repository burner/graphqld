/// Helpers used by generated code.
module graphql.client.helpers;

static import std.typecons;

// Avoid redundant nullability for reference types +
// work around https://github.com/dlang/phobos/issues/10661
template NullableIfNeeded(T) {
	static if (is(T == class)) {
		// Already nullable - no need for extra nullability
		alias NullableIfNeeded = T;
	} else {
		alias NullableIfNeeded = std.typecons.Nullable!T;
	}
}

unittest {
	struct S {}
	class C {}
	static assert(is(NullableIfNeeded!int == std.typecons.Nullable!int));
	static assert(is(NullableIfNeeded!S == std.typecons.Nullable!S));
	static assert(is(NullableIfNeeded!C == C));
}

// Helpers for pre/post-converting custom scalars.
template map(alias pred) {
	import std.typecons : Nullable; // https://github.com/dlang/dmd/issues/21008
	auto map(T)(ref inout Nullable!T value) {
		alias U = typeof({ T v = void; return pred(v); }());
		if (value.isNull)
			return std.typecons.Nullable!U();
		else
			return std.typecons.nullable(pred(value.get()));
	}

	auto map(T)(ref inout T[] value) {
		alias U = typeof({ T v = void; return pred(v); }());
		auto result = new U[value.length];
		foreach (i, ref v; value) {
			result[i] = pred(v);
		}
		return result;
	}
}

unittest {
	import std.typecons : nullable;

	auto ni = 1.nullable;
	assert(map!(x => x + 1)(ni) == 2.nullable);

	auto ai = [1];
	assert(map!(x => x + 1)(ai) == [2]);
}

unittest {
	import std.typecons : Nullable, nullable;
	import std.datetime.date : Date;
	import core.time : days;

	Nullable!Date nd = Date(2020, 01, 01);
	assert(map!(x => x + days(1))(nd) == Date(2020, 01, 02).nullable);

	const Nullable!Date cnd = Date(2020, 01, 01);
	assert(map!(x => x + days(1))(cnd) == Date(2020, 01, 02).nullable);
}
