module traits;

import std.meta;
import std.range : ElementEncodingType;
import std.traits;
import std.typecons : Nullable;
import std.experimental.logger : logf;

template AllIncarnations(T, SCH...) {
	static if(SCH.length > 0 && is(T : SCH[0])) {
		alias AllIncarnations = AliasSeq!(SCH[0],
				.AllIncarnations!(T, SCH[1 ..  $])
			);
	} else static if(SCH.length > 0) {
		alias AllIncarnations = AliasSeq!(.AllIncarnations!(T, SCH[1 ..  $]));
	} else {
		alias AllIncarnations = AliasSeq!(T);
	}
}

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
	} else static if(is(T : Nullable!F, F)) {
		alias interfs = staticMap!(.InheritedClassImpl, F);
		alias tmp = AliasSeq!(T, interfs);
		alias InheritedClassImpl = tmp;
	} else {
		alias InheritedClassImpl = T;
	}
}

unittest {
	alias Bases = InheritedClasses!Union;
	static assert(is(Bases == AliasSeq!(Nullable!Bar, Nullable!Impl)));
}

unittest {
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

version(unittest) {
private:
	abstract class Base {
		int a;
	}

	class Impl : Base {
		float b;
	}

	class Bar {
		string c;
	}

	union Union {
		Nullable!Bar foo;
		Nullable!Impl impl;
	}
}

template isNotObject(Type) {
	enum isNotObject = !is(Type == Object);
}

template collectTypesImpl(Type) {
	static if(is(Type == interface)) {
		alias RetTypes = AliasSeq!(collectReturnType!(Type,
				__traits(allMembers, Type))
			);
		alias ArgTypes = AliasSeq!(collectParameterTypes!(Type,
				__traits(allMembers, Type))
			);
		alias collectTypesImpl = AliasSeq!(Type, RetTypes, ArgTypes,
					InterfacesTuple!Type
				);
	} else static if(is(Type == class)) {
		alias RetTypes = AliasSeq!(collectReturnType!(Type,
				__traits(allMembers, Type))
			);
		alias ArgTypes = AliasSeq!(collectParameterTypes!(Type,
				__traits(allMembers, Type))
			);
		alias tmp = AliasSeq!(
				Fields!(Type),
				InheritedClasses!Type,
				InterfacesTuple!Type
			);
		alias collectTypesImpl = AliasSeq!(Type, tmp, RetTypes, ArgTypes);
	} else static if(is(Type == union)) {
		alias collectTypesImpl = AliasSeq!(Type, InheritedClasses!Type);
	} else static if(is(Type : Nullable!F, F)) {
		alias collectTypesImpl = .collectTypesImpl!(F);
	} else static if(is(Type == struct)) {
		alias RetTypes = AliasSeq!(collectReturnType!(Type,
				__traits(allMembers, Type))
			);
		alias ArgTypes = AliasSeq!(collectParameterTypes!(Type,
				__traits(allMembers, Type))
			);
		alias collectTypesImpl = AliasSeq!(Type, RetTypes, ArgTypes);
	} else static if(isSomeString!Type) {
		alias collectTypesImpl = string;
	} else static if(is(Type == bool)) {
		alias collectTypesImpl = bool;
	} else static if(is(Type == enum)) {
		alias collectTypesImpl = Type;
	} else static if(isArray!Type) {
		alias collectTypesImpl = .collectTypesImpl!(ElementEncodingType!Type);
	} else static if(isIntegral!Type) {
		alias collectTypesImpl = long;
	} else static if(isFloatingPoint!Type) {
		alias collectTypesImpl = float;
	} else {
		alias collectTypesImpl = AliasSeq!();
	}
}

template collectReturnType(Type, Names...) {
	static if(Names.length > 0) {
		static if(isCallable!(__traits(getMember, Type, Names[0]))) {
			alias collectReturnType = AliasSeq!(
					ReturnType!(__traits(getMember, Type, Names[0])),
					.collectReturnType!(Type, Names[1 .. $])
				);
		} else {
			alias collectReturnType = .collectReturnType!(Type, Names[1 .. $]);
		}
	} else {
		alias collectReturnType = AliasSeq!();
	}
}

template collectParameterTypes(Type, Names...) {
	static if(Names.length > 0) {
		static if(isCallable!(__traits(getMember, Type, Names[0]))) {
			alias ArgTypes = ParameterTypeTuple!(
					__traits(getMember, Type, Names[0])
				);
			alias collectParameterTypes = AliasSeq!(ArgTypes,
					.collectParameterTypes!(Type, Names[1 .. $])
				);
		} else {
			alias collectParameterTypes = .collectParameterTypes!(Type,
					Names[1 .. $]
				);
		}
	} else {
		alias collectParameterTypes = AliasSeq!();
	}
}

template fixupBasicTypes(T) {
	static if(isSomeString!T) {
		alias fixupBasicTypes = string;
	} else static if(is(T == enum)) {
		alias fixupBasicTypes = T;
	} else static if(is(T == bool)) {
		alias fixupBasicTypes = bool;
	} else static if(isIntegral!T) {
		alias fixupBasicTypes = long;
	} else static if(isFloatingPoint!T) {
		alias fixupBasicTypes = float;
	} else static if(isArray!T) {
		alias ElemFix = fixupBasicTypes!(ElementEncodingType!T);
		alias fixupBasicTypes = ElemFix[];
	} else static if(is(T : Nullable!F, F)) {
		alias ElemFix = fixupBasicTypes!(F);
		alias fixupBasicTypes = Nullable!(ElemFix);
	} else {
		alias fixupBasicTypes = T;
	}
}

template noArrayOrNullable(T) {
	static if(is(T : Nullable!F, F)) {
		enum noArrayOrNullable = false;
	} else static if(!isSomeString!T && isArray!T) {
		enum noArrayOrNullable = false;
	} else {
		enum noArrayOrNullable = true;
	}
}

unittest {
	static assert(is(Nullable!int : Nullable!F, F));
	static assert(!is(int : Nullable!F, F));
	static assert( noArrayOrNullable!(int));
	static assert( noArrayOrNullable!(string));
	static assert(!noArrayOrNullable!(int[]));
	static assert(!noArrayOrNullable!(Nullable!int));
	static assert(!noArrayOrNullable!(Nullable!int));
}

template collectTypes(T...) {
	alias oneLevelDown = NoDuplicates!(staticMap!(collectTypesImpl, T));
	alias basicT = staticMap!(fixupBasicTypes, oneLevelDown);
	alias elemTypes = Filter!(noArrayOrNullable, basicT);
	alias noVoid = EraseAll!(void, elemTypes);
	alias rslt = NoDuplicates!(EraseAll!(Object, basicT),
			EraseAll!(Object, noVoid)
		);
	static if(rslt.length == T.length) {
		alias collectTypes = rslt;
	} else {
		alias collectTypes = .collectTypes!(rslt);
	}
}

version(unittest) {
package {
	enum Enum {
		one,
		two
	}
	class U {
		string f;
		Baz baz;
		Enum e;
	}
	class W {
		Nullable!(Nullable!(U)[]) us;
	}
	class Y {
		bool b;
		Nullable!W w;
	}
	class Z : Y {
		long id;
	}
	class Baz {
		string id;
		Z[] zs;
	}
	class Args {
		float value;
	}
	interface Foo {
		Baz bar();
		Args args();
	}
}
}

unittest {
	alias a = collectTypes!(Enum);
	static assert(is(a == AliasSeq!(Enum)));
}

unittest {
	alias ts = collectTypes!(Foo);
	alias expectedTypes = AliasSeq!(Foo, Baz, Args, float, Z[], Z, string,
			long, Y, bool, Nullable!W, W, Nullable!(Nullable!(U)[]), U, Enum);

	template canBeFound(T) {
		enum tmp = staticIndexOf!(T, expectedTypes) != -1;
		enum canBeFound = tmp;
	}
	static assert(allSatisfy!(canBeFound, ts));
}

template stripArrayAndNullable(T) {
	static if(is(T : Nullable!F, F)) {
		alias stripArrayAndNullable = .stripArrayAndNullable!F;
	} else static if(!isSomeString!T && isArray!T) {
		alias stripArrayAndNullable =
			.stripArrayAndNullable!(ElementEncodingType!T);
	} else {
		alias stripArrayAndNullable = T;
	}
}

template stringofType(T) {
	enum stringofType = T.stringof;
}

string[] interfacesForType(Schema)(string typename) {
	import std.algorithm.searching : canFind;
	alias filtered = staticMap!(stripArrayAndNullable, collectTypes!Schema);
	alias Types = NoDuplicates!(filtered);
	switch(typename) {
		static foreach(T; Types) {
			case T.stringof: {
				static enum ret = [NoDuplicates!(staticMap!(stringofType,
						EraseAll!(Object, AllIncarnations!(T, Types))))
					];
				//logf("%s %s %s", typename, T.stringof, ret);
				return ret;
			}
		}
		default:
			//logf("DEFAULT: '%s'", typename);
			if(canFind(["__Type", "__Field", "__InputValue", "__Schema",
						"__EnumValue", "__TypeKind", "__Directive",
						"__DirectiveLocation"], typename))
			{
				return [typename];
			}
			return string[].init;
	}
}

template PossibleTypes(Type, Schema) {
	static if(is(Type == union)) {
		alias PossibleTypes = Filter!(isAggregateType, FieldTypeTuple!Type);
	} else static if(is(Type == interface) || is(Type == class)) {
		alias AllTypes = NoDuplicates!(collectTypes!Schema);
		alias PossibleTypes = NoDuplicates!(PossibleTypesImpl!(Type, AllTypes));
	}
}

template PossibleTypesImpl(Type, AllTypes...) {
	static if(AllTypes.length == 0) {
		alias PossibleTypesImpl = AliasSeq!(Type);
	} else {
		static if(is(AllTypes[0] : Type)) {
			alias PossibleTypesImpl = AliasSeq!(AllTypes[0],
					.PossibleTypesImpl!(Type, AllTypes[1 .. $])
				);
		} else {
			alias PossibleTypesImpl = AliasSeq!(
					.PossibleTypesImpl!(Type, AllTypes[1 .. $])
				);
		}
	}
}
