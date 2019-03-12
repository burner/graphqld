module schema2;

import std.conv : to;
import std.array;
import std.meta;
import std.traits;
import std.typecons;
import std.algorithm : map, joiner, canFind;
import std.range : ElementEncodingType;
import std.format;
import std.string : strip;
import std.experimental.logger;

import vibe.data.json;

import helper;
import traits;

@safe:

enum GQLDKind {
	String,
	Float,
	Int,
	Bool,
	Object_,
	List,
	Enum,
	Map,
	Nullable,
	NonNull,
	Union,
	Query,
	Mutation,
	Subscription,
	Schema
}

abstract class GQLDType(Con) {
	alias Context = Con;

	const GQLDKind kind;
	string name;

	this(GQLDKind kind) {
		this.kind = kind;
	}

	override string toString() const {
		return "GQLDType";
	}

	string toShortString() const {
		return this.toString();
	}
}

class GQLDScalar(Con) : GQLDType!(Con) {
	this(GQLDKind kind) {
		super(kind);
	}
}

class GQLDString(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.String);
		super.name = "String";
	}

	override string toString() const {
		return "String";
	}
}

class GQLDFloat(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.Float);
		super.name = "Float";
	}

	override string toString() const {
		return "Float";
	}
}

class GQLDInt(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.Int);
		super.name = "Int";
	}

	override string toString() const {
		return "Int";
	}
}

class GQLDEnum(Con) : GQLDScalar!(Con) {
	string enumName;
	this(string enumName) {
		super(GQLDKind.Enum);
		this.enumName = enumName;
		super.name = enumName;
	}

	override string toString() const {
		return this.enumName;
	}
}

class GQLDBool(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.Bool);
		super.name = "Bool";
	}

	override string toString() const {
		return "Bool";
	}
}

class GQLDMap(Con) : GQLDType!(Con) {
	GQLDType!(Con)[string] member;
	GQLDMap!(Con)[] derivatives;

	this() {
		super(GQLDKind.Map);
	}
	this(GQLDKind kind) {
		super(kind);
	}

	void addDerivative(GQLDMap!(Con) d) {
		if(!canFind!((a,b) => a is b)(this.derivatives, d)) {
			this.derivatives ~= d;
		}
	}

	override string toString() const {
		auto app = appender!string();
		foreach(key, value; this.member) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}
		return app.data;
	}
}

class GQLDObject(Con) : GQLDMap!(Con) {
	GQLDObject!(Con) _base;

	@property const(GQLDObject!(Con)) base() const {
		return cast(const)this._base;
	}

	@property void base(GQLDObject!(Con) nb) {
		this._base = nb;
	}

	this(string name) {
		super(GQLDKind.Object_);
		super.name = name;
	}

	override string toString() const {
		return format(
				"Object %s(%s))\n\t\t\t\tBase(%s)\n\t\t\t\tDerivaties(%s)",
				this.name,
				this.member
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t"),
				(this.base !is null ? this.base.toShortString() : "null"),
				this.derivatives.map!(d => d.toShortString())
			);
	}

	override string toShortString() const {
		return format("%s", super.name);
	}
}

class GQLDUnion(Con) : GQLDMap!(Con) {
	this(string name) {
		super(GQLDKind.Union);
		super.name = name;
	}

	override string toString() const {
		return format("Union %s(%s))\n\t\t\t\tDerivaties(%s)",
				this.name,
				this.member
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t"),
				this.derivatives.map!(d => d.toShortString())
			);
	}
}

class GQLDList(Con) : GQLDType!(Con) {
	GQLDType!(Con) elementType;

	this(GQLDType!(Con) elemType) {
		super(GQLDKind.List);
		super.name = "List";
		this.elementType = elemType;
	}

	override string toString() const {
		return format("List(%s)", this.elementType.toShortString());
	}

	override string toShortString() const {
		return format("List(%s)", this.elementType.toShortString());
	}
}

class GQLDNonNull(Con) : GQLDType!(Con) {
	GQLDType!(Con) elementType;

	this(GQLDType!(Con) elemType) {
		super(GQLDKind.NonNull);
		super.name = "NonNull";
		this.elementType = elemType;
	}

	override string toString() const {
		return format("NonNull(%s)", this.elementType.toShortString());
	}

	override string toShortString() const {
		return format("NonNull(%s)", this.elementType.toShortString());
	}
}

class GQLDNullable(Con) : GQLDType!(Con) {
	GQLDType!(Con) elementType;

	this(GQLDType!(Con) elemType) {
		super(GQLDKind.Nullable);
		super.name = "Nullable";
		this.elementType = elemType;
	}

	override string toString() const {
		return format("Nullable(%s)", this.elementType.toShortString());
	}

	override string toShortString() const {
		return format("Nullable(%s)", this.elementType.toShortString());
	}
}

class GQLDOperation(Con) : GQLDType!(Con) {
	GQLDType!(Con) returnType;
	string returnTypeName;

	GQLDType!(Con)[string] parameters;

	this(GQLDKind kind) {
		super(kind);
	}

	override string toString() const {
		return format("%s %s(%s)", super.kind, returnType.toShortString(),
				this.parameters
					.byKeyValue
					.map!(kv =>
						format("%s %s", kv.key, kv.value.toShortString())
					)
					.joiner(", ")
				);
	}
}

class GQLDQuery(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Query);
		super.name = "Query";
	}
}

class GQLDMutation(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Mutation);
		super.name = "Mutation";
	}
}

class GQLDSubscription(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Subscription);
		super.name = "Subscription";
	}
}

class GQLDSchema(Type, Con) : GQLDMap!(Con) {
	GQLDType!(Con)[string] types;

	GQLDObject!(Con) __schema;
	GQLDObject!(Con) __type;
	GQLDObject!(Con) __field;
	GQLDObject!(Con) __inputValue;
	GQLDObject!(Con) __enumValue;

	GQLDNonNull!Con __nonNullType;
	GQLDNullable!Con __nullableType;
	GQLDNullable!Con __listOfNonNullType;
	GQLDNonNull!Con __nonNullListOfNonNullType;
	GQLDNonNull!Con __nonNullField;
	GQLDNullable!Con __listOfNonNullField;
	GQLDNonNull!Con __nonNullInputValue;
	GQLDList!Con __listOfNonNullInputValue;
	GQLDNonNull!Con __nonNullListOfNonNullInputValue;
	GQLDList!Con __listOfNonNullEnumValue;

	this() {
		super(GQLDKind.Schema);
		super.name = "Schema";
		this.createInbuildTypes();
		this.createIntrospectionTypes();
	}

	void createInbuildTypes() {
		this.types["string"] = new GQLDString!Con();
		foreach(t; ["String", "Int", "Float", "Bool"]) {
			GQLDObject!Con tmp = new GQLDObject!Con(t);
			this.types[t] = tmp;
			tmp.member["name"] = new GQLDString!Con();
			tmp.member["description"] = new GQLDString!Con();
			tmp.member["kind"] = new GQLDEnum!Con("__TypeKind");
			//tmp.resolver = buildTypeResolver!(Type,Con)();
		}
	}

	void createIntrospectionTypes() {
		// build base types
		auto str = new GQLDString!Con();
		auto nnStr = new GQLDNonNull!Con(str);
		auto nllStr = new GQLDNullable!Con(str);

		auto b = new GQLDBool!Con();
		auto nnB = new GQLDNonNull!Con(b);
		this.__schema = new GQLDObject!Con("__schema");
		this.__type = new GQLDObject!Con("__Type");
		this.__schema.member["mutationType"] = this.__type;
		this.__schema.member["subscriptionType"] = this.__type;

		this.__nullableType = new GQLDNullable!Con(this.__type);
		this.__type.member["ofType"] = this.__nullableType;
		this.__type.member["kind"] = new GQLDEnum!Con("__TypeKind");
		this.__type.member["name"] = nllStr;
		this.__type.member["description"] = nllStr;

		this.__nonNullType = new GQLDNonNull!Con(this.__type);
		this.__schema.member["queryType"] = this.__type;
		auto lNNTypes = new GQLDList!Con(this.__nonNullType);
		this.__listOfNonNullType = new GQLDNullable!Con(lNNTypes);
		this.__type.member["interfaces"] = str;
		this.__type.member["possibleTypes"] = str;

		this.__nonNullListOfNonNullType = new GQLDNonNull!Con(lNNTypes);
		this.__schema.member["types"] = this.__nonNullListOfNonNullType;

		this.__field = new GQLDObject!Con("__Field");
		this.__field.member["name"] = nnStr;
		this.__field.member["description"] = nllStr;
		this.__field.member["type"] = this.__nonNullType;
		this.__field.member["isDeprecated"] = nnB;
		this.__field.member["deprecationReason"] = nllStr;

		this.__nonNullField = new GQLDNonNull!Con(this.__field);
		auto lNNFields = new GQLDList!Con(this.__nonNullField);
		this.__listOfNonNullField = new GQLDNullable!Con(lNNFields);
		this.__type.member["fields"] = this.__listOfNonNullField;

		this.__inputValue = new GQLDObject!Con("__InputValue");
		this.__inputValue.member["name"] = nnStr;
		this.__inputValue.member["description"] = nllStr;
		this.__inputValue.member["defaultValue"] = nllStr;
		this.__inputValue.member["type"] = this.__nonNullType;

		this.__nonNullInputValue = new GQLDNonNull!Con(this.__inputValue);
		this.__listOfNonNullInputValue = new GQLDList!Con(
				this.__nonNullInputValue
			);

		this.__type.member["inputFields"] = this.__listOfNonNullInputValue;

		this.__nonNullListOfNonNullInputValue = new GQLDNonNull!Con(
				this.__listOfNonNullInputValue
			);

		this.__field.member["args"] = this.__nonNullListOfNonNullInputValue;

		this.__enumValue = new GQLDObject!Con("__EnumValue");
		this.__enumValue.member["name"] = nnStr;
		this.__enumValue.member["description"] = nllStr;
		this.__enumValue.member["isDeprecated"] = nnB;
		this.__enumValue.member["deprecationReason"] = nllStr;

		this.__listOfNonNullEnumValue = new GQLDList!Con(new GQLDNonNull!Con(
				this.__enumValue
			));

		this.__type.member["enumValues"] = this.__listOfNonNullEnumValue;

		foreach(t; ["String", "Int", "Float", "Bool"]) {
			this.types[t].toObject().member["fields"] =
				this.__listOfNonNullField;
		}
	}

	override string toString() const {
		auto app = appender!string();
		formattedWrite(app, "Operation\n");
		foreach(key, value; super.member) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}

		formattedWrite(app, "Types\n");
		foreach(key, value; this.types) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}
		return app.data;
	}

	GQLDType!(Con) getReturnType(Con)(GQLDType!Con t, string field) {
		//logf("'%s' '%s'", t.name, field);
		GQLDType!Con ret;
		if(auto s = t.toScalar()) {
			//log();
			ret = s;
		} else if(auto op = t.toOperation()) {
			//log();
			ret = op.returnType;
		} else if(auto map = t.toMap()) {
			if((map.name == "query" || map.name == "mutation"
						|| map.name == "subscription")
					&& field in map.member)
			{
				//log();
				auto tmp = map.member[field];
				if(auto op = tmp.toOperation()) {
					//log();
					ret = op.returnType;
				} else {
					//log();
					ret = tmp;
				}
			} else if(field in map.member) {
				//log();
				ret = map.member[field];
			} else if(field == "__typename") {
				ret = this.types["string"];
			} else {
				// if we couldn't find it in the passed map, maybe it is in some
				// of its derivatives
				foreach(deriv; map.derivatives) {
					if(field in deriv.member) {
						return deriv.member[field];
					}
				}
				return null;
			}
		} else {
			ret = t;
		}
		//logf("%s", ret.name);
		return ret;
	}
}

GQLDSchema!(Con) toSchemaFoo(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDObject!(Con) toObject(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDMap!(Con) toMap(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDScalar!(Con) toScalar(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDOperation!(Con) toOperation(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDList!(Con) toList(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDNullable!(Con) toNullable(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

GQLDNonNull!(Con) toNonNull(Con)(GQLDType!Con t) {
	return cast(typeof(return))t;
}

unittest {
	auto str = new GQLDString!(int)();
	assert(str.name == "String");

	auto map = str.toMap();
	assert(map is null);
}

string toShortString(Con)(const(GQLDType!(Con)) e) {
	if(auto o = cast(const(GQLDObject!(Con)))e) {
		return o.name;
	} else if(auto u = cast(const(GQLDUnion!(Con)))e) {
		return u.name;
	} else {
		return e.toString();
	}
}

GQLDType!(Con) typeToGQLDType(Type, Con, SCH)(ref SCH ret) {
	pragma(msg, Type.stringof, " ", isIntegral!Type);
	static if(is(Type == enum)) {
		GQLDEnum!(Con) r;
		if(Type.stringof in ret.types) {
			r = cast(GQLDEnum!(Con))ret.types[Type.stringof];
		} else {
			r = new GQLDEnum!(Con)(Type.stringof);
			ret.types[Type.stringof] = r;
		}
		return r;
	} else static if(is(Type == bool)) {
		return new GQLDBool!(Con)();
	} else static if(isFloatingPoint!(Type)) {
		return new GQLDFloat!(Con)();
	} else static if(isIntegral!(Type)) {
		return new GQLDInt!(Con)();
	} else static if(isSomeString!Type) {
		return new GQLDString!(Con)();
	} else static if(is(Type == union)) {
		GQLDUnion!(Con) r;
		if(Type.stringof in ret.types) {
			r = cast(GQLDUnion!(Con))ret.types[Type.stringof];
		} else {
			r = new GQLDUnion!(Con)(Type.stringof);
			ret.types[Type.stringof] = r;

			alias fieldNames = FieldNameTuple!(Type);
			alias fieldTypes = Fields!(Type);
			static foreach(idx; 0 .. fieldNames.length) {{
				auto tmp = typeToGQLDType!(fieldTypes[idx], Con)(ret);
				r.member[fieldNames[idx]] = tmp;

				if(GQLDMap!Con tmpMap = tmp.toMap()) {
					r.addDerivative(tmpMap);
				}
			}}
		}
		return r;
	} else static if(is(Type : Nullable!F, F)) {
		return new GQLDNullable!(Con)(typeToGQLDType!(F, Con)(ret));
	} else static if(isArray!Type) {
		return new GQLDList!(Con)(
				typeToGQLDType!(ElementEncodingType!Type, Con)(ret)
			);
	} else static if(isAggregateType!Type) {
		GQLDObject!(Con) r;
		if(Type.stringof in ret.types) {
			r = cast(GQLDObject!(Con))ret.types[Type.stringof];
		} else {
			r = new GQLDObject!(Con)(Type.stringof);
			ret.types[Type.stringof] = r;

			alias fieldNames = FieldNameTuple!(Type);
			alias fieldTypes = Fields!(Type);
			static foreach(idx; 0 .. fieldNames.length) {{
				r.member[fieldNames[idx]] =
					typeToGQLDType!(fieldTypes[idx], Con)(ret);
			}}

			static if(is(Type == class)) {
				alias bct = BaseClassesTuple!(Type);
				static if(bct.length > 1) {
					auto d = cast(GQLDObject!(Con))typeToGQLDType!(bct[0], Con)(
							ret
						);
					r.base = d;
					d.addDerivative(r);

				}
				assert(bct.length > 1 ? r.base !is null : true);
			}
		}
		return r;
	} else {
		pragma(msg, "218 ", Type.stringof);
		static assert(false, Type.stringof);
	}
}

template typeToTypeEnum(Type) {
	static if(is(Type == enum)) {
		enum typeToTypeEnum = "ENUM";
	} else static if(is(Type == bool)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isFloatingPoint!(Type)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isIntegral!(Type)) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(isSomeString!Type) {
		enum typeToTypeEnum = "SCALAR";
	} else static if(is(Type == union)) {
		enum typeToTypeEnum = "UNION";
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToTypeEnum = "NULLABLE";
	} else static if(isArray!Type) {
		enum typeToTypeEnum = "LIST";
	} else static if(isAggregateType!Type) {
		enum typeToTypeEnum = "OBJECT";
	} else {
		static assert(false, T.stringof ~ " not handled");
	}
}

unittest {
	static assert(typeToTypeEnum!(int[]) == "LIST");
}

template typeToTypeName(Type) {
	static if(is(Type == enum)) {
		enum typeToTypeName = Type.stringof;
	} else static if(is(Type == bool)) {
		enum typeToTypeName = "Bool";
	} else static if(isFloatingPoint!(Type)) {
		enum typeToTypeName = "Float";
	} else static if(isIntegral!(Type)) {
		enum typeToTypeName = "Int";
	} else static if(isSomeString!Type) {
		enum typeToTypeName = "String";
	} else static if(isArray!Type) {
		enum typeToTypeName = "__listType";
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToTypeName = "__nullType";
	} else {
		enum typeToTypeName = Type.stringof;
	}
}

unittest {
	static assert(typeToTypeName!(Nullable!int) == "__nullType");
}

template isScalarType(Type) {
	static if(is(Type == bool)) {
		enum isScalarType = true;
	} else static if(isFloatingPoint!(Type)) {
		enum isScalarType = true;
	} else static if(isIntegral!(Type)) {
		enum isScalarType = true;
	} else static if(isSomeString!Type) {
		enum isScalarType = true;
	} else static if(is(Type == enum)) {
		enum isScalarType = true;
	} else {
		enum isScalarType = false;
	}
}

template typeToFieldType(Type) {
	static if(isArray!Type && !isSomeString!Type) {
		enum typeToFieldType = "__listType";
	} else static if(is(Type : Nullable!F, F)) {
		enum typeToFieldType = F.stringof;
	} else {
		enum typeToFieldType = "__nonNullType";
	}
}

Json typeToField(T, string name)() {
	alias Ts = stripArrayAndNullable!T;
	Json ret = Json.emptyObject();
	ret["name"] = name;
	ret["typename"] = typeToTypeName!(Ts);
	ret["typenameOrig"] = typeToFieldType!(T);
	ret["description"] = "TODO";
	ret["isDeprecated"] = false;
	ret["deprecationReason"] = "TODO";
	return ret;
}

/*Json typeFields(T)() {
	import std.algorithm.searching : startsWith;
	import std.traits : FieldTypeTuple, FieldNameTuple;
	Json ret = Json.emptyArray();

	alias manyTypes = EraseAll!(Object, AliasSeq!(T, InheritedClasses!T));
	pragma(msg, "775 ", T.stringof, " ", manyTypes);
	static foreach(Type; manyTypes) {{
		static if(is(Type : Nullable!F, F)) {
			alias FT = F;
		} else {
			alias FT = Type;
		}
		pragma(msg, FT);
		Json tmp = Json.emptyObject();
		tmp["description"] = "TODO";
		tmp["isDeprecated"] = false;
		tmp["deprecationReason"] = "TODO";
		static if(isBasicType!FT) {
		} else {
			tmp["name"] = mem;
			static foreach(mem; __traits(allMembers, FT)) {{
				alias MemType = typeof(__traits(getMember, FT, mem));
				static if(isCallable!(__traits(getMember, FT, mem))) {
					alias RT = ReturnType!(__traits(getMember, FT, mem));
					alias RTS = stripArrayAndNullable!RT;
					tmp["typename"] = typeToTypeName!(RTS);
					tmp["typenameOrig"] = typeToTypeName!(RT);
				}
			}}
		}
		ret ~= tmp;
		//alias fieldTypes = FieldTypeTuple!Type;
		//alias fieldNames = FieldNameTuple!Type;
		//static foreach(idx; 0 .. fieldTypes.length) {{
		//	static if(!fieldNames[idx].empty
		//			&& !startsWith(fieldNames[idx], "_"))
		//	{
		//		ret ~= typeToField!(fieldTypes[idx], fieldNames[idx]);
		//	}
		//}}
	}}
	return ret;
}*/

Json typeFields(T)() {
	static enum memsToIgnore = ["__ctor", "toString", "toHash", "opCmp",
			"opEquals", "Monitor", "factory"];
	Json ret = Json.emptyArray();
	alias TplusParents = AliasSeq!(T, InheritedClasses!T);
	static foreach(Type; TplusParents) {{
		pragma(msg, "746 ", Type.stringof);
		static foreach(mem; __traits(allMembers, Type)) {{
			static if(!canFind(memsToIgnore, mem)) {
				Json tmp = Json.emptyObject();
				tmp["name"] = mem;
				tmp["description"] = "";
				tmp["isDeprecated"] = false;
				tmp["deprecationReason"] = "";
				pragma(msg, "\t749 ", mem);
				static if(isCallable!(__traits(getMember, Type, mem))) {
					pragma(msg, "\t\tcallable");
					alias RT = ReturnType!(__traits(getMember, Type, mem));
					alias RTS = stripArrayAndNullable!RT;
					tmp["typename"] = typeToTypeName!RTS;
					tmp["typenameOrg"] = typeToTypeName!RT;
				} else {
					pragma(msg, "\t\tfield");
					alias Ts = stripArrayAndNullable!(
							typeof(__traits(getMember, Type, mem))
						);
					tmp["typename"] = typeToTypeName!Ts;
					tmp["typenameOrg"] = typeToTypeName!(
							typeof(__traits(getMember, Type, mem))
						);
				}
				ret ~= tmp;
			}
		}}
	}}
	return ret;
}

Json emptyType() {
	Json ret = Json.emptyObject();
	ret["kind"] = "";
	ret["name"] = Json(null);
	ret["__typename"] = Json(null);
	ret["description"] = Json(null);
	ret["fields"] = Json(null);
	ret["interfacesNames"] = Json(null);
	ret["possibleTypesNames"] = Json(null);
	ret["ofTypeName"] = Json(null);
	ret["enumValues"] = Json(null);
	return ret;
}

Json typeToJson(Type)() {
	Json ret = Json.emptyObject();
	ret["kind"] = typeToTypeEnum!Type;
	ret["name"] = typeToTypeName!Type;
	ret["__typename"] = "__Type";
	ret["description"] = "TODO";

	// fields
	static if(
			(is(Type == class) || is(Type == interface) || is(Type == struct))
			&& !is(Type : Nullable!K, K))
	{
		ret["fields"] = typeFields!Type();
	} else {
		ret["fields"] = Json(null);
	}

	// needed to resolve interfaces
	static if(is(Type == class)) {
		ret["interfacesNames"] = Json.emptyArray();
		static foreach(interfaces; InheritedClasses!Type) {{
			ret["interfacesNames"] ~= interfaces.stringof;
		}}
	} else {
		ret["interfacesNames"] = Json(null);
	}

	// needed to resolve possibleTypes
	static if(is(Type == class) || is(Type == union)
			|| is(Type == interface))
	{
		ret["possibleTypesNames"] = Json.emptyArray();
		static foreach(pt; AliasSeq!(Type, InheritedClasses!Type)) {
			ret["possibleTypesNames"] ~= pt.stringof;
		}
	} else {
		ret["possibleTypesNames"] = Json(null);
	}

	// enumValues
	static if(is(Type == enum)) {
		ret["enumValues"] = Json.emptyArray();
		static foreach(mem; EnumMembers!Type) {{
			Json tmp = Json.emptyObject();
			tmp["name"] = Json(to!string(mem));
			tmp["description"] = "ENUM_DESCRIPTION_TODO";
			tmp["isDeprecated"] = false;
			tmp["deprecationReason"] = "ENUM_DEPRECATIONREASON_TODO";
			ret["enumValues"] ~= tmp;
		}}
	} else {
		ret["enumValues"] = Json(null);
	}

	// needed to resolve ofType
	static if(!isSomeString!Type && isArray!Type) {
		ret["ofTypeName"] = ElementEncodingType!(Type).stringof;
	} else static if(is(Type : Nullable!F, F)) {
		ret["ofTypeName"] = F.stringof;
	} else {
		ret["ofTypeName"] = Type.stringof;
	}

	return ret;
}

alias QueryResolver(Con) = Json delegate(string name, Json parent,
		Json args, ref Con context) @safe;

QueryResolver!(Con) buildSchemaResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			//logf("%s %s %s", name, args, parent);
			Json ret = returnTemplate();
			ret["data"]["types"] = Json.emptyArray();
			pragma(msg, collectTypes!(Type));
			static foreach(type; collectTypes!(Type)) {{
				Json tmp = typeToJson!type();
				ret["data"]["types"] ~= tmp;
			}}
			ret["data"]["directives"] = Json.emptyArray();
			ret["data"]["queryType"] = typeToJson!(typeof(
					__traits(getMember, Type, "query")))();
			return ret;
		};
	return ret;
}

QueryResolver!(Con) buildTypeResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			logf("%s %s %s", name, args, parent);
			Json ret = returnTemplate();
			string typeName;
			if("name" in args) {
				typeName = args["name"].get!string();
			}
			if("typenameOrig" in parent) {
				typeName = parent["typenameOrig"].get!string();
			} else if("name" in parent) {
				typeName = parent["name"].get!string();
			}
			string typeCap;
			if(typeName.empty) {
				ret["error"] ~= Json(format("unknown type"));
				goto retLabel;
			} else {
				typeCap = firstCharUpperCase(typeName);
			}
			if(typeName == "__listType") {
				ret["data"] = typeToJson!(int[])();
				ret["data"]["__typename"] = "__listType";
				ret["data"]["typenameOrig"] = parent["typename"];
				ret["data"]["name"] = Json(null);
				ret["data"]["kind"] = "LIST";
				goto retLabel;
			} else if(typeName == "__nullType") {
				ret["data"] = typeToJson!(Nullable!int)();
				ret["data"]["typenameOrig"] = parent["typename"];
				ret["data"]["__typename"] = "__nullType";
				ret["data"]["name"] = Json(null);
				goto retLabel;
			} else if(typeName == "__nonNullType") {
				ret["data"] = typeToJson!(int)();
				ret["data"]["typenameOrig"] = parent["typename"];
				ret["data"]["__typename"] = "__nonNullType";
				ret["data"]["name"] = Json(null);
				ret["data"]["kind"] = "NON_NULL";
				goto retLabel;
			}
			pragma(msg, "collectTypes ", collectTypes!(Type));
			static foreach(type; collectTypes!(Type)) {{
				enum typeConst = typeToTypeName!(type);
				if(typeCap == typeConst) {
					ret["data"] = typeToJson!type();
					logf("%s %s %s", typeCap, typeConst, ret["data"]);
					goto retLabel;
				} else {
					logf("||||||||||| %s %s", typeCap, typeConst);
				}
			}}
			retLabel:
			logf("%s", ret.toPrettyString());
			return ret;
		};
	return ret;
}

GQLDSchema!(Type, Con) toSchema2(Type, Con)() {
	typeof(return) ret = new typeof(return)();

	pragma(msg, __traits(allMembers, Type));
	static foreach(qms; ["query", "mutation", "subscription"]) {{
		GQLDMap!(Con) cur = new GQLDMap!Con();
		cur.name = qms;
		ret.member[qms] = cur;
		if(qms == "query") {
			cur.member["__schema"] = ret.__schema;
			cur.member["__type"] = ret.__type;
		}
		static if(__traits(hasMember, Type, qms)) {
			alias QMSType = typeof(__traits(getMember, Type, qms));
			static foreach(mem; __traits(allMembers, QMSType)) {{
				alias MemType = typeof(__traits(getMember, QMSType, mem));
				static if(isCallable!(MemType)) {{
					GQLDOperation!(Con) op = qms == "query"
						? new GQLDQuery!Con()
						: qms == "mutation" ? new GQLDMutation!Con()
						: qms == "subscription" ? new GQLDSubscription!Con()
						: null;
					cur.member[mem] = op;
					assert(op !is null);
					op.returnType = typeToGQLDType!(ReturnType!(MemType), Con)(
							ret
						);

					alias paraNames = ParameterIdentifierTuple!(
							__traits(getMember, QMSType, mem)
						);
					alias paraTypes = Parameters!(
							__traits(getMember, QMSType, mem)
						);
					static foreach(idx; 0 .. paraNames.length) {
						op.parameters[paraNames[idx]] =
							typeToGQLDType!(paraTypes[idx], Con)(ret);
					}
				}}
			}}
		}
	}}
	return ret;
}

string toString(Con)(ref GQLDType!(Con)[string] all) {
	auto app = appender!string();
	foreach(key, value; all) {
		formattedWrite(app, "%20s: %s\n", key, value.toString());
	}
	return app.data;
}
