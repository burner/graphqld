module graphql.reflection;
import graphql.traits;
import std.traits;
import std.meta;
import vibe.data.json;

package struct SchemaReflection(Schema) {
	private {
		static SchemaReflection _instance;
		bool initialized;
	}

	static SchemaReflection *instance() @safe {
		_instance.initialize();
		return &_instance;
	}

	string[TypeInfo] classes;
	string[][TypeInfo] derivatives;
	string[][string] bases;
	static struct TypeWithStrippedName {
		Json typeJson;
		string name;
		bool canonical;
	}

	TypeWithStrippedName[string] jsonTypes;

	private:

	static void builder(T)(ref SchemaReflection ths) {
		static if(is(T == class)) {
			ths.classes[typeid(T)] = T.stringof;
			foreach(B; AliasSeq!(T, TransitiveBaseTypeTuple!T)) {
				static if(!is(B == Object)) {
					ths.derivatives.require(typeid(B), null) ~= T.stringof;
					ths.bases.require(T.stringof, null) ~= B.stringof;
				}
			}
		} else static if(is(T == interface)) {
			// go through all base types, and set up the derivation lines
			foreach(B; AliasSeq!(T, InterfacesTuple!T)) {
				ths.derivatives.require(typeid(B), null) ~= T.stringof;
				ths.bases.require(T.stringof, null) ~= B.stringof;
			}
		} else {
			// all other types have derivatives and bases of themselves
			ths.derivatives.require(typeid(T), null) ~= T.stringof;
			ths.bases.require(T.stringof, null) ~= T.stringof;
		}
	}

	static void builderPhase2(T)(ref SchemaReflection ths) {
		import graphql.schema.typeconversions : typeToTypeName, typeToJsonImpl;
		// build the second parts which need the first parts
		alias stripped = stripArrayAndNullable!T;
		ths.jsonTypes[typeToTypeName!T] =
			TypeWithStrippedName(typeToJsonImpl!(stripped, Schema, T)(),
								 stripped.stringof,
								 is(stripArrayAndNullable!T == T));
	}

	void initialize() @safe {
		if(initialized) {
			return;
		}
		initialized = true;

		execForAllTypes!(Schema, builder)(this);
		execForAllTypes!(Schema, builderPhase2)(this);
	}
}
