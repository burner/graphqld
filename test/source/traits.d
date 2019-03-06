module traits;

template InheritedClasses(T) {
	import std.meta : NoDuplicates, EraseAll;
	alias InheritedClass = EraseAll!(T, EraseAll!(Object,
			NoDuplicates!(InheritedClassImpl!T))
		);
}

template InheritedClassImpl(T) {
	import std.meta : staticMap, AliasSeq, NoDuplicates;
	import std.traits : FieldTypeTuple, BaseClassesTuple;
	static if(is(T == union)) {
		alias InheritedClassImpl = AliasSeq!(T, staticMap!(.InheritedClassImpl,
				FieldTypeTuple!T));
	} else static if(is(T == class)) {
		alias InheritedClassImpl = AliasSeq!(T, staticMap!(.InheritedClassImpl,
				BaseClassesTuple!T));
	} else {
		alias InheritedClassImpl = AliasSeq!();
	}
}

unittest {
	import std.meta : AliasSeq;
	alias Bases = InheritedClasses!Union;
	static assert(is(Bases == AliasSeq!(Foo, Impl, Base)));
}

template BaseFields(T) {
	import std.meta : EraseAll, NoDuplicates;
	alias BaseFields = EraseAll!(Object, NoDuplicates!(BaseFieldsImpl!T));
}

template BaseFieldsImpl(T) {
	import std.traits : FieldNameTuple, Fields, BaseClassesTuple;
	import std.meta : staticMap, AliasSeq, NoDuplicates;
	static if(is(T == class)) {
		alias BaseClassSeq = Fields!T;
		alias BaseFieldsImpl = NoDuplicates!(
				T,
				BaseClassSeq,
				staticMap!(.BaseFieldsImpl, BaseClassesTuple!T)
			);
	} else static if(is(T == union)) {
		alias BaseFieldsImpl = NoDuplicates!(
				T,
				Fields!T,
				staticMap!(.BaseFieldsImpl, Fields!T)
			);
	} else {
		alias BaseFieldsImpl = T;
	}
}

template AllFieldNames(T) {
	import std.traits : isAggregateType, FieldNameTuple, BaseClassesTuple;
	import std.meta : AliasSeq, staticMap, NoDuplicates;
	static if(isAggregateType!T) {
		alias SubAggregates = BaseFields!T;
		alias AllFieldNames = NoDuplicates!(AliasSeq!(FieldNameTuple!T,
				staticMap!(FieldNameTuple, SubAggregates))
			);
	} else {
		alias AllFieldNames = AliasSeq!();
	}
}

template BaseFieldAggregates(T) {
	import std.meta : Filter;
	import std.traits : isAggregateType;
	alias BaseFieldAggregates = Filter!(isAggregateType, BaseFields!T);
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

	alias B = BaseFields!Union;
	static assert(is(B == AliasSeq!(Union, Foo, Impl, string, float, Base,
			int))
		);
}
