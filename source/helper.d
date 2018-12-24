module helper;

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
