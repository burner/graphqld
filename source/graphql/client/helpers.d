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

// Helpers for pre/post-converting custom scalars.
template map(alias pred)
{
	auto map(T)(ref Nullable!T value) {
		alias U = typeof({ T v = void; return pred(v); }());
		if (value.isNull)
			return std.typecons.Nullable!U();
		else
			return std.typecons.nullable(pred(value.get()));
	}

	auto map(T)(ref T[] value) {
		alias U = typeof({ T v = void; return pred(v); }());
		auto result = new U[value.length];
		foreach (i, ref v; value) {
			result[i] = pred(v);
		}
		return result;
	}
}
