module schema2;

import std.array;
import std.meta;
import std.traits;
import std.typecons;
import std.algorithm : map, joiner;
import std.range : ElementEncodingType;
import std.format;
import std.experimental.logger;

import vibe.data.json;

@safe:

Json returnTemplate() {
	Json ret = Json.emptyObject();
	ret["data"] = Json.emptyObject();
	ret["error"] = Json.emptyArray();
	return ret;
}

struct DefaultContext {
}

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
	Union,
	Query,
	Mutation,
	Subscription,
	Schema
}


abstract class GQLDType(Con) {
	alias Context = Con;

	alias Resolver = Json delegate(string name, Json parent,
			Json args, ref Context context);

	const GQLDKind kind;
	string name;
	Resolver resolver;

	this(GQLDKind kind) {
		this.kind = kind;
		this.resolver = delegate(string name, Json parent, Json args,
							ref Context context)
			{
				import std.format;
				logf("name: %s, parent: %s, args: %s", name, parent, args);
				Json ret = Json.emptyObject();
				ret["data"] = Json.emptyObject();
				ret["error"] = Json.emptyArray();
				if(name in parent) {
					ret["data"] = parent[name];
				} else {
					ret["error"] = Json(format("no field name '%s' found",
										name)
									);
				}
				return ret;
			};
	}

	Json call(string name, Json parent, Json args, ref Context context) {
		return this.resolver(name, parent, args, context);
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
	this() {
		super(GQLDKind.Map);
	}
	this(GQLDKind kind) {
		super(kind);
	}

	override string toString() const {
		auto app = appender!string();
		foreach(key, value; this.member) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}
		return app.data;
	}

	override Json call(string name, Json parent, Json args, ref Context context)
	{
		if(name in this.member) {
			return this.member[name].call(name, parent, args, context);
		} else {
			return this.resolver(name, parent, args, context);
		}
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
		return format("Object %s(%s))\n\t\t\t\tBase(%s)",
				this.name,
				this.member
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t"),
				(this.base !is null ? this.base.toShortString() : "null")
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
		return format("Union %s(%s))",
				this.name,
				this.member
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t")
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

	GQLDList!(Con) __listType;
	GQLDList!(Con) __listField;
	GQLDList!(Con) __listInputValue;
	GQLDList!(Con) __listEnumValue;

	GQLDNullable!(Con) __nullableType;
	GQLDNullable!(Con) __nullableField;
	GQLDNullable!(Con) __nullableInputValue;

	GQLDList!(Con) __listNullableType;
	GQLDList!(Con) __listNullableField;
	GQLDList!(Con) __listNullableInputValue;

	GQLDNullable!(Con) __nullableListNullableType;
	GQLDNullable!(Con) __nullableListNullableField;
	GQLDNullable!(Con) __nullableListNullableInputValue;

	this() {
		super(GQLDKind.Schema);
		super.name = "Schema";
		this.createInbuildTypes();
		this.createIntrospectionTypes();
	}

	void createInbuildTypes() {
		this.types["string"] = new GQLDObject!Con("string");
		this.types["int"] = new GQLDObject!Con("int");
		this.types["float"] = new GQLDObject!Con("float");
		this.types["bool"] = new GQLDObject!Con("bool");

		foreach(t; ["string", "int", "float", "bool"]) {
			this.types[t].toObject().member["name"] = new GQLDString!Con();
			this.types[t].resolver = buildTypeResolver!(Type,Con)();
		}
	}

	void createIntrospectionTypes() {
		// build base types
		this.__schema = new GQLDObject!Con("__schema");

		this.__type = new GQLDObject!Con("__type");
		this.__field = new GQLDObject!Con("__field");
		this.__inputValue = new GQLDObject!Con("__inputValue");
		this.__enumValue = new GQLDObject!Con("__enumValue");

		this.__listType = new GQLDList!Con(this.__type);
		this.__listField = new GQLDList!Con(this.__field);
		this.__listInputValue = new GQLDList!Con(this.__inputValue);
		this.__listEnumValue = new GQLDList!Con(this.__enumValue);

		this.__nullableType = new GQLDNullable!Con(this.__type);
		this.__nullableField = new GQLDNullable!Con(this.__field);
		this.__nullableInputValue = new GQLDNullable!Con(this.__inputValue);

		this.__listNullableType = new GQLDList!Con(this.__nullableType);
		this.__listNullableField = new GQLDList!Con(this.__nullableField);
		this.__listNullableInputValue =
				new GQLDList!Con(this.__nullableInputValue);

		this.__nullableListNullableType =
				new GQLDNullable!Con(this.__listNullableType);
		this.__nullableListNullableField =
				new GQLDNullable!Con(this.__listNullableField);
		this.__nullableListNullableInputValue =
				new GQLDNullable!Con(this.__listNullableInputValue);

		// set members of base types

		this.__type.resolver = buildTypeResolver!(Type, Con)();
		this.__type.member["name"] = new GQLDString!Con();
		this.__type.member["description"] = new GQLDString!Con();
		this.__type.member["fields"] = this.__listField;
		this.__type.member["kind"] = new GQLDEnum!Con("__TypeKind");

		this.__field.resolver = buildFieldResolver!(Type, Con)();
		this.__field.member["name"] = new GQLDString!Con();
		this.__field.member["description"] = new GQLDString!Con();
		this.__field.member["type"] = this.__type;
		this.__field.member["isDeprecated"] = new GQLDBool!Con();
		this.__field.member["deprecatedReason"] = new GQLDString!Con();
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
		logf("%s %s", t.name, field);
		GQLDType!Con ret;
		if(auto op = t.toObject()) {
			if(op.name == "__schema") {
				switch(field) {
					case "types": ret = this.__listType; break;
					case "queryTypes": ret = this.__type; break;
					case "mutationTypes": ret = this.__nullableType; break;
					case "subscriptionType": ret = this.__nullableType; break;
					default:
						assert(false,
								"introspecting directive not yet supported"
							);
				}
			} else if(op.name == "__field") {
				switch(field) {
					case "__type": ret = this.__type; break;
					case "name": ret = this.types["string"]; break;
					case "description": ret = this.types["string"]; break;
					case "fields": ret = this.__listField; break;
					case "interfaces": ret = this.__listType; break;
					case "possibleTypes": ret = this.__listType; break;
					case "enumValues": ret = this.__listEnumValue; break;
					case "oyType": ret = this.__type; break;
					default:
						ret = null;
						break;
				}
			} else if(op.name == "__field") {
			} else if(op.name == "__inputValue") {
			} else if(op.name == "__enumValue") {
			}
			if(ret) {
				logf("%s", ret.name);
				return ret;
			}
		}
		if(auto s = t.toScalar()) {
			log();
			ret = s;
		} else if(auto op = t.toOperation()) {
			log();
			ret = op.returnType;
		} else if(auto map = t.toMap()) {
			if(map.name == "query" && field in map.member) {
				log();
				auto tmp = map.member[field];
				if(auto op = tmp.toOperation()) {
					log();
					ret = op.returnType;
				} else {
					log();
					ret = tmp;
				}
			} else if(field in map.member) {
				log();
				ret = map.member[field];
			} else {
				log();
				//logf("%s %s", t.toString(), field);
				return null;
			}
		} else {
			ret = t;
		}
		logf("%s", ret.name);
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

template isNotObject(Type) {
	enum isNotObject = !is(Type == Object);
}

template collectTypesImpl(Type) {
	static if(is(Type == interface)) {
		alias tmp = AliasSeq!(collectReturnType!(Type,
				__traits(allMembers, Type))
			);
		alias collectTypesImpl = AliasSeq!(Type, tmp);
	} else static if(is(Type == class)) {
		alias tmp = AliasSeq!(
				Fields!(Type),
				Filter!(isNotObject, BaseClassesTuple!Type)
			);
		alias collectTypesImpl = AliasSeq!(Type, tmp);
	} else static if(is(Type : Nullable!F, F)) {
		alias collectTypesImpl = .collectTypesImpl!(F);
	} else static if(isSomeString!Type) {
		alias collectTypesImpl = string;
	} else static if(is(Type == bool)) {
		alias collectTypesImpl = bool;
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

template fixupBasicTypes(T) {
	static if(isSomeString!T) {
		alias fixupBasicTypes = string;
	} else static if(is(T == bool)) {
		alias fixupBasicTypes = bool;
	} else static if(isIntegral!T) {
		alias fixupBasicTypes = long;
	} else static if(isFloatingPoint!T) {
		alias fixupBasicTypes = float;
	} else {
		alias fixupBasicTypes = T;
	}
}

template noArrayOrNullable(T) {
	import std.typecons : Nullable;
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
	static if(oneLevelDown.length == T.length) {
		alias basicT = staticMap!(fixupBasicTypes, T);
		alias collectTypes = NoDuplicates!(Filter!(noArrayOrNullable, basicT));
	} else {
		alias collectTypes = .collectTypes!(oneLevelDown);
	}
}

version(unittest) {
package {
	class U {
		string f;
		Bar bar;
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
	class Bar {
		string id;
		Z[] zs;
	}
	class Args {
		float value;
	}
	interface Foo {
		Bar bar();
		Args args();
	}
}
}

unittest {
	alias ts = collectTypes!(Foo);

	template canBeFound(T) {
		alias expectedTypes = AliasSeq!(U, string, W, Y, bool, Z, long, Bar,
				Args, Foo, float
			);
		enum tmp = staticIndexOf!(T, expectedTypes) != -1;
		enum canBeFound = tmp;
	}
	static assert(allSatisfy!(canBeFound, ts));
}

GQLDType!(Con) typeToGQLDType(Type, Con, SCH)(ref SCH ret) {
	pragma(msg, Type.stringof, " ", isIntegral!Type);
	static if(is(Type == bool)) {
		return new GQLDBool!(Con)();
	} else static if(isFloatingPoint!(Type)) {
		return new GQLDFloat!(Con)();
	} else static if(isIntegral!(Type)) {
		return new GQLDInt!(Con)();
	} else static if(isSomeString!Type) {
		return new GQLDString!(Con)();
	} else static if(is(Type == enum)) {
		GQLDEnum!(Con) r;
		if(Type.stringof in ret.types) {
			r = cast(GQLDEnum!(Con))ret.types[Type.stringof];
		} else {
			r = new GQLDEnum!(Con)();
			ret.types[Type.stringof] = r;
		}
		return r;
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
				r.member[fieldNames[idx]] =
					typeToGQLDType!(fieldTypes[idx], Con)(ret);
			}}
		}
		return r;
	} else static if(is(Type : Nullable!F, F)) {
		pragma(msg, "Nullable ", F.stringof);
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

		alias bct = BaseClassesTuple!(Type);
		static if(bct.length > 1) {
			r.base = cast(GQLDObject!(Con))typeToGQLDType!(bct[0], Con)(ret);
		}
		assert(bct.length > 1 ? r.base !is null : true);
	}
	return r;
} else {
	pragma(msg, "218 ", Type.stringof);
	static assert(false, Type.stringof);
}
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

Json typeToField(T, string name)() {
	alias Ts = stripArrayAndNullable!T;
	Json ret = Json.emptyObject();
	ret["name"] = name;
	ret["description"] = "TODO";
	ret["type"] = Ts.stringof;
	ret["isDeprected"] = false;
	ret["deprecationReason"] = "TODO";
	return ret;
}

alias QueryResolver(Con) = Json delegate(string name, Json parent,
		Json args, ref Con context) @safe;

QueryResolver!(Con) buildTypeResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			logf("%s %s %s", name, args, parent);
			Json ret = returnTemplate();
			string typeName;
			if("name" in parent) {
				typeName = parent["name"].get!string();
			} else if("name" in args) {
				typeName = args["name"].get!string();
			} else {
				ret["error"] ~= Json(format("unknown type"));
				return ret;
			}
			ret["data"]["name"] = typeName;
			ret["data"]["description"] = "No description";
			pragma(msg, collectTypes!(Type));
			static foreach(type; collectTypes!(Type)) {{
				if(typeName == type.stringof) {
					logf("%s %s", typeName, type.stringof);
					alias fieldsTypes = Fields!(type);
					alias fieldsNames = FieldNameTuple!(type);
					ret["data"]["fields"] = Json.emptyArray();
					static foreach(idx; 0 .. fieldsTypes.length) {{
						ret["data"]["fields"] ~=
							typeToField!(fieldsTypes[idx], fieldsNames[idx]);
					}}
				}
			}}
			logf("%s", ret.toPrettyString());
			return ret;
		};
	return ret;
}

QueryResolver!(Con) buildFieldResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			logf("\n\n%s %s\n\n", name, args.toPrettyString());
			assert(false);
			//return parent;
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
		static assert(__traits(hasMember, Type, qms));
		alias QMSType = typeof(__traits(getMember, Type, qms));
		static foreach(mem; __traits(allMembers, QMSType)) {{
			alias MemType = typeof(__traits(getMember, QMSType, mem));
			static if(isCallable!(MemType)) {{
				GQLDOperation!(Con) op = qms == "query" ? new GQLDQuery!Con()
					: qms == "mutation" ? new GQLDMutation!Con()
					: qms == "subscription" ? new GQLDSubscription!Con()
					: null;
				cur.member[mem] = op;
				assert(op !is null);
				op.returnType = typeToGQLDType!(ReturnType!(MemType), Con)(ret);

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
