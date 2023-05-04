module graphql.traits;

import std.meta;
import std.range : ElementEncodingType;
import std.traits;
import std.typecons : Nullable;
import std.meta : AliasSeq, Filter;

import nullablestore;

import graphql.uda;
import graphql.schema.types;

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

template isNotCustomLeafOrIgnore(T) {
	import graphql.uda;
	enum GQLDUdaData u = getUdaData!T;
	enum isNotCustomLeafOrIgnore = u.ignore != Ignore.yes;
}

template InheritedClassImpl(T) {
	import std.meta : staticMap, AliasSeq, NoDuplicates;
	import std.traits : Select;

	alias getInheritedFields() = staticMap!(.InheritedClassImpl,
			FieldTypeTuple!T
		);

	alias ftt = Select!(is(T == union), getInheritedFields, AliasSeq);

	alias getBaseTuple() = staticMap!(.InheritedClassImpl, BaseClassesTuple!T);
	alias clss = Select!(is(T == class), getBaseTuple, AliasSeq);

	alias getInter() = staticMap!(.InheritedClassImpl, InterfacesTuple!T);
	alias inter = Select!(is(T == class) || is(T == interface),
			getInter, AliasSeq);

	static if(is(T : Nullable!F, F) || is(T : NullableStore!F, F)) {
		alias interfs = staticMap!(.InheritedClassImpl, F);
		alias tmp = AliasSeq!(T, interfs);
		alias nn = tmp;
	} else {
		alias nn = T;
	}

	alias InheritedClassImpl = AliasSeq!(ftt!(), clss!(), inter!(), nn);
}

unittest {
	alias Bases = InheritedClasses!Union;
	static assert(is(Bases ==
			AliasSeq!(Nullable!Bar, Bar, Nullable!Impl, Base, Impl))
		);
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
	static assert(is(inter2 == AliasSeq!(H,G,I)));
}

private abstract class Base {
	int a;
}

private class Impl : Base {
	float b;
}

private class Bar {
	string c;
}

private union Union {
	Nullable!Bar foo;
	Nullable!Impl impl;
}

template isNotObject(Type) {
	enum isNotObject = !is(Type == Object);
}

template isNotCustomLeaf(Type) {
	import graphql.uda;
	enum isNotCustomLeaf = !is(Type : GQLDCustomLeaf!Fs, Fs...);
}

unittest {
	string toS(int i) {
		return "";
	}
	int fromS(string s) {
		return 0;
	}
	alias t = AliasSeq!(int, GQLDCustomLeaf!(int, toS, fromS));
	alias f = Filter!(isNotCustomLeaf, t);
	static assert(is(f == AliasSeq!(int)));
}

template collectTypesImpl(Type) {
	import graphql.uda;
	static if(is(Type : GQLDCustomLeaf!Fs, Fs...)) {
		alias collectTypesImpl = AliasSeq!(Type);
	} else static if(is(Type == interface)) {
		alias RetTypes = AliasSeq!(collectReturnType!(Type,
				__traits(allMembers, Type))
			);
		alias ArgTypes = AliasSeq!(collectParameterTypes!(Type,
				__traits(allMembers, Type))
			);
		alias collectTypesImpl =
				AliasSeq!(Type, RetTypes, ArgTypes, InterfacesTuple!Type);
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
		//alias collectTypesImpl = Filter!(isNotCustomLeaf,
		alias collectTypesImpl =
				AliasSeq!(Type, tmp, RetTypes, ArgTypes)
			;
	} else static if(is(Type == union)) {
		alias collectTypesImpl = AliasSeq!(Type, InheritedClasses!Type);
	} else static if(is(Type : Nullable!F, F)) {
		alias collectTypesImpl = .collectTypesImpl!(F);
	} else static if(is(Type : NullableStore!F, F)) {
		alias collectTypesImpl = .collectTypesImpl!(Type.TypeValue);
	} else static if(is(Type : WrapperStore!F, F)) {
		alias collectTypesImpl = AliasSeq!(Type);
	} else static if(is(Type == struct)) {
		alias RetTypes = AliasSeq!(collectReturnType!(Type,
				__traits(allMembers, Type))
			);
		alias ArgTypes = AliasSeq!(collectParameterTypes!(Type,
				__traits(allMembers, Type))
			);
		alias Fi = Fields!Type;
		//alias collectTypesImpl = Filter!(isNotCustomLeaf,
		alias collectTypesImpl =
				AliasSeq!(Type, RetTypes, ArgTypes, Fi)
			;
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

unittest {
	struct Foo {
		int a;
	}
	alias Type = NullableStore!Foo;
	static if(is(Type : NullableStore!F, F)) {
		alias T = Type.TypeValue;
	} else {
		alias T = int;
	}
	static assert(is(T == Foo));
}

template collectReturnType(Type, Names...) {
	import graphql.uda : getUdaData, GQLDUdaData;
	enum GQLDUdaData udaDataT = getUdaData!(Type);
	static if(Names.length > 0) {
		static if(__traits(getProtection, __traits(getMember, Type, Names[0]))
				== "public"
				&& isCallable!(__traits(getMember, Type, Names[0])))
		{
			alias rt = ReturnType!(__traits(getMember, Type, Names[0]));
			alias before = AliasSeq!(rt,
					.collectReturnType!(Type, Names[1 .. $])
				);
			//alias tmp = Filter!(isNotCustomLeaf, before);
			alias collectReturnType = before;
		} else {
			alias tmp = .collectReturnType!(Type, Names[1 .. $]);
			//alias collectReturnType = Filter!(isNotCustomLeaf, tmp);
			alias collectReturnType = tmp;
		}
	} else {
		alias collectReturnType = AliasSeq!();
	}
}

template collectParameterTypes(Type, Names...) {
	static if(Names.length > 0) {
		static if(__traits(getProtection, __traits(getMember, Type, Names[0]))
				== "public"
				&& isCallable!(__traits(getMember, Type, Names[0])))
		{
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
	} else static if(is(T : GQLDCustomLeaf!Fs, Fs...)) {
		alias ElemFix = fixupBasicTypes!(Fs[0]);
		alias fixupBasicTypes = GQLDCustomLeaf!(ElemFix, Fs[1 .. $]);
	} else static if(is(T : Nullable!F, F)) {
		alias ElemFix = fixupBasicTypes!(F);
		alias fixupBasicTypes = Nullable!(ElemFix);
	} else static if(is(T : NullableStore!F, F)) {
		alias ElemFix = fixupBasicTypes!(F);
		alias fixupBasicTypes = NullableStore!(ElemFix);
	} else {
		alias fixupBasicTypes = T;
	}
}

template noArrayOrNullable(T) {
	static if(is(T : Nullable!F, F)) {
		enum noArrayOrNullable = false;
	} else static if(is(T : NullableStore!F, F)) {
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
	static assert(!is(int : NullableStore!F, F));
	static assert( noArrayOrNullable!(int));
	static assert( noArrayOrNullable!(string));
	static assert(!noArrayOrNullable!(int[]));
	static assert(!noArrayOrNullable!(Nullable!int));
	static assert(!noArrayOrNullable!(Nullable!int));
	static assert(!noArrayOrNullable!(NullableStore!int));
}

template collectTypes(T...) {
	import graphql.schema.introspectiontypes;
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
		alias tmp = .collectTypes!(rslt);
		alias collectTypes = tmp;
	}
}

template collectTypesPlusIntrospection(T) {
	import graphql.schema.introspectiontypes;
	alias collectTypesPlusIntrospection = AliasSeq!(collectTypes!T,
			IntrospectionTypes
		);
}

package {
	enum Enum {
		one,
		two
	}
	class U {
		string f;
		Baz baz;
		Enum e;

		override string toString() { return "U"; }
	}
	class W {
		Nullable!(Nullable!(U)[]) us;
		override string toString() { return "W"; }
	}
	class Y {
		bool b;
		Nullable!W w;
		override string toString() { return "Y"; }
	}
	class Z : Y {
		long id;
		override string toString() { return "Z"; }
	}
	class Baz {
		string id;
		Z[] zs;
		override string toString() { return "Baz"; }
	}
	class Args {
		float value;
		override string toString() { return "Args"; }
	}
	interface Foo {
		Baz bar();
		Args args();
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

unittest {
	import nullablestore;
	struct Foo {
		int a;
	}

	struct Bar {
		NullableStore!Foo foo;
	}

	static assert(is(collectTypes!Bar : AliasSeq!(Bar, NullableStore!Foo, Foo,
			long))
		);
}

template stripArrayAndNullable(T) {
	static if(is(T : Nullable!F, F)) {
		alias stripArrayAndNullable = .stripArrayAndNullable!F;
	} else static if(is(T : NullableStore!F, F)) {
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

string[] basesOfType(Sch)(Sch schema, string typename) {
	GQLDType* t = typename in schema.types;
	if(t !is null) {
		GQLDObject o = toObject(*t);
		if(o !is null && o.base !is null) {
			return [typename] ~ basesOfType(schema, o.base.name);
		}
	}
	return [typename];
}

string[] interfacesForType(Schema)(Schema schema, string typename) {
	import std.algorithm.searching : canFind;
	//import graphql.reflection : SchemaReflection;
	//if(auto result = typename in SchemaReflection!Schema.instance.bases) {
	//	return *result;
	//}
	if(typename in schema.types) {
		return basesOfType(schema, typename);
	}
	if(canFind(["__Type", "__Field", "__InputValue", "__Schema",
			   "__EnumValue", "__TypeKind", "__Directive",
			   "__DirectiveLocation"], typename))
	{
		return [typename];
	}
	return string[].init;
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

// compiler has a hard time inferring safe. So we have to tag it.
void execForAllTypes(T, alias fn, Context...)(auto ref Context context) @safe {
	// establish a seen array to ensure no infinite recursion.
	execForAllTypesImpl!(T, fn)((bool[void*]).init, context);
}

@trusted private void* keyFor(TypeInfo ti) {
	return cast(void*)ti;
}
