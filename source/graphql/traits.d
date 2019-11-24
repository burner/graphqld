module graphql.traits;

import std.meta;
import std.range : ElementEncodingType;
import std.traits;
import std.typecons : Nullable;
import std.experimental.logger : logf;
import std.meta : AliasSeq, Filter;

import nullablestore;

import graphql.uda;

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
	alias t = AliasSeq!(int, GQLDCustomLeaf!int);
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

template collectTypesX(T...) {
	static if(T.length == 1)
		pragma(msg, "collect all types! " ~ T.stringof);
	import graphql.schema.introspectiontypes;
	alias oneLevelDown = NoDuplicates!(staticMap!(collectTypesImpl, T));
	alias basicT = staticMap!(fixupBasicTypes, oneLevelDown);
	alias elemTypes = Filter!(noArrayOrNullable, basicT);
	alias noVoid = EraseAll!(void, elemTypes);
	alias rslt = NoDuplicates!(EraseAll!(Object, basicT),
			EraseAll!(Object, noVoid)
		);
	static if(rslt.length == T.length) {
		alias collectTypesX = rslt;
	} else {
		alias tmp = .collectTypesX!(rslt);
		alias collectTypesX = tmp;
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
	alias a = collectTypesX!(Enum);
	static assert(is(a == AliasSeq!(Enum)));
}

/+unittest {
	alias ts = collectTypesX!(Foo);
	alias expectedTypes = AliasSeq!(Foo, Baz, Args, float, Z[], Z, string,
			long, Y, bool, Nullable!W, W, Nullable!(Nullable!(U)[]), U, Enum);

	template canBeFound(T) {
		enum tmp = staticIndexOf!(T, expectedTypes) != -1;
		enum canBeFound = tmp;
	}
	static assert(allSatisfy!(canBeFound, ts));
}+/

/+unittest {
	import nullablestore;
	struct Foo {
		int a;
	}

	struct Bar {
		NullableStore!Foo foo;
	}

	static assert(is(collectTypesX!Bar : AliasSeq!(Bar, NullableStore!Foo, Foo,
			long))
		);
}+/

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

string[] interfacesForType(Schema)(string typename) {
	import std.algorithm.searching : canFind;
	// this is awful, but I'm not sure yet whether non-classes can return
	// anything but themselves.
	static string[][string] typeMap;
	if(typeMap is null)
	{
		// build the type map. This involves comparing every type to every other
		// type.
		static void checkForDerived(T)(ref string[][string] typeMap)
		{
			static if(is(stripArrayAndNullable!T == T))
			{
				static void checkType(U)(ref string[] incarnations)
				{
					static if(is(stripArrayAndNullable!U == U))
					{
						static if(is(T : U))
							incarnations ~= U.stringof;
					}
				}
				string[] incarnations;
				execForAllTypes!(Schema, checkType)(incarnations);
				typeMap[T.stringof] = incarnations;
			}
		}

		execForAllTypes!(Schema, checkForDerived)(typeMap);
	}
	if(auto result = typename in typeMap)
	{
		return *result;
	}
	if(canFind(["__Type", "__Field", "__InputValue", "__Schema",
			   "__EnumValue", "__TypeKind", "__Directive",
			   "__DirectiveLocation"], typename))
	{
		return [typename];
	}
	return string[].init;
	/+alias filtered = staticMap!(stripArrayAndNullable, collectTypes!Schema);
	alias Types = NoDuplicates!(filtered);
	switch(typename) {
		static foreach(T; Types) {
			case T.stringof: {
				static enum ret = [NoDuplicates!(staticMap!(stringofType,
						EraseAll!(Object, AllIncarnations!(T, Types))))
					];
				logf("%s %s %s", typename, ret);
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
	}+/
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
@safe
void execForAllTypes(T, alias fn, Context...)(auto ref Context context)
{
	//alias allTypes = collectTypesX!T;
	// establish a seen array to ensure no infinite recursion.
	static keyFor(T)() @trusted { return cast(void*)typeid(T); }
	static bool fn2(T)(auto ref Context context)
	{
		fn!T(context);
		return true;
	}
	execForAllTypesImpl!(T, fn2, keyFor)((bool[void*]).init, context);
}

@safe
void execForAllTypesImpl(Type, alias fn, alias keyFor, V, K, Context...)(
									 V[K] seen, auto ref Context context)
{
	alias FixedType = fixupBasicTypes!Type;
	static if(!is(FixedType == Type))
	{
		return .execForAllTypesImpl!(FixedType, fn, keyFor)(seen, context);
	} else static if(isArray!Type && !is(Type == string)) {
		return .execForAllTypesImpl!(typeof(Type.init[0]), fn, keyFor)(seen, context);
	} else static if( // only process types we are interested in
		  isAggregateType!Type ||
		  is(Type == bool) ||
		  is(Type == enum) ||
		  is(Type == long) ||
		  is(Type == float) ||
		  is(Type == string))
   	{
		auto tid = keyFor!Type();
		if(auto v = tid in seen)
		{
			// already in there
			return;
		}
		// store the result
		seen[tid] = fn!Type(context);

		// now, handle the types we can get to from this type.
		static if(is(Type : GQLDCustomLeaf!Fs, Fs...)) {
			// ignore subtypes
		} else static if(is(Type : WrapperStore!F, F)) {
			// ignores subtypes
		} else static if(is(Type : Nullable!F, F)) {
			.execForAllTypesImpl!(F, fn, keyFor)(seen, context);
		} else static if(is(Type : NullableStore!F, F)) {
			.execForAllTypesImpl!(Type.TypeValue, fn, keyFor)(seen, context);
		} else static if(isAggregateType!Type) { // class, struct, interface, union
			// do callables first. Then do fields separately
			static foreach(mem; __traits(allMembers, Type))
			{{
				 static if(__traits(getProtection, __traits(getMember, Type, mem))
						   == "public"
						   && isCallable!(__traits(getMember, Type, mem)))
				 {
					 // return type
					 .execForAllTypesImpl!(ReturnType!(__traits(getMember, Type, mem)), fn, keyFor)(seen, context);
					 // parameters
					 static foreach(T; ParameterTypeTuple!(__traits(getMember,
																	Type, mem)))
					 {
						 .execForAllTypesImpl!(T, fn, keyFor)(seen, context);
					 }
				 }
			}}

			// now do all fields
			static foreach(T; Fields!Type)
			{
				.execForAllTypesImpl!(T, fn, keyFor)(seen, context);
			}

			// do any base types (stolen from BaseTypeTuple, which annoyingly
			// doesn't work on all aggregates)
			static if(is(Type S == super))
			{
				static foreach(T; S)
				{
					.execForAllTypesImpl!(T, fn, keyFor)(seen, context);
				}
			}
		}
	}
	// other types we don't care about.
}
