module traits;

template BaseClasses(T) {
	import std.meta : EraseAll, NoDuplicates;
	alias BaseClasses = EraseAll!(Object, NoDuplicates!(BaseClassesImpl!T));
}

template BaseClassesImpl(T) {
	import std.traits : FieldNameTuple, Fields, BaseClassesTuple;
	import std.meta : staticMap, AliasSeq, NoDuplicates;
	static if(is(T == class)) {
		alias BaseClassSeq = Fields!T;
		alias BaseClassesImpl = NoDuplicates!(
				T,
				BaseClassSeq,
				staticMap!(.BaseClassesImpl, BaseClassesTuple!T)
			);
	} else static if(is(T == union)) {
		alias BaseClassesImpl = NoDuplicates!(
				T,
				Fields!T,
				staticMap!(.BaseClassesImpl, Fields!T)
			);
	} else {
		alias BaseClassesImpl = T;
	}
}

template AllFieldNames(T) {
	import std.traits : isAggregateType, FieldNameTuple, BaseClassesTuple;
	import std.meta : AliasSeq, staticMap, NoDuplicates;
	static if(isAggregateType!T) {
		alias SubAggregates = BaseClasses!T;
		alias AllFieldNames = NoDuplicates!(AliasSeq!(FieldNameTuple!T,
				staticMap!(FieldNameTuple, SubAggregates))
			);
	} else {
		alias AllFieldNames = AliasSeq!();
	}
}

version(unittest) {
private:
	abstract class Base {
		int a;
	}

	class Impl : Base {
		float b;
	}

	class Foo {
		string c;
	}

	union Union {
		Foo foo;
		Impl impl;
	}
}

unittest {
	import std.meta : AliasSeq;

	static assert(is(BaseClasses!Union ==
			AliasSeq!(Union, Foo, Impl, string, float, Base, int)
			)
		);
}
