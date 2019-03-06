module traits;

template InheritedClasses(T) {
	import std.meta : NoDuplicates, EraseAll;
	alias Clss = InheritedClassImpl!T;
	alias ND = NoDuplicates!(Clss);
	alias NO = EraseAll!(Object, ND);
	alias NOT = EraseAll!(T, NO);
	alias InheritedClasses = NOT;
}

template InheritedClassImpl(T) {
	import std.meta : staticMap, AliasSeq, NoDuplicates;
	import std.traits : FieldTypeTuple, BaseClassesTuple, InterfacesTuple;
	static if(is(T == union)) {
		alias fields = staticMap!(.InheritedClassImpl, FieldTypeTuple!T);
		alias tmp = AliasSeq!(T, fields);
		alias InheritedClassImpl = tmp;
	} else static if(is(T == class)) {
		alias clss = staticMap!(.InheritedClassImpl, BaseClassesTuple!T);
		alias interfs = staticMap!(.InheritedClassImpl, InterfacesTuple!T);
		alias tmp = AliasSeq!(T, clss, interfs);
		alias InheritedClassImpl = tmp;
	} else static if(is(T == interface)) {
		alias interfs = staticMap!(.InheritedClassImpl, InterfacesTuple!T);
		alias tmp = AliasSeq!(T, interfs);
		alias InheritedClassImpl = tmp;
	} else {
		alias InheritedClassImpl = T;
	}
}

unittest {
	import std.meta : AliasSeq;
	alias Bases = InheritedClasses!Union;
	static assert(is(Bases == AliasSeq!(Foo, Impl, Base)));
}

unittest {
	import std.meta : AliasSeq;
	interface H {
		int h();
	}

	interface G : H {
		float g();
	}

	abstract class I : G {
	}

	abstract class J : I {
	}

	alias inter = InheritedClasses!G;
	static assert(is(inter == AliasSeq!(H)));

	alias inter2 = InheritedClasses!J;
	static assert(is(inter2 == AliasSeq!(I,G,H)));
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
