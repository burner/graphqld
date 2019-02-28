module schema2;

import std.array;
import std.traits;
import std.typecons;
import std.algorithm : map, joiner;
import std.range : ElementEncodingType;
import std.format;
import std.experimental.logger;

import vibe.data.json;

@safe:

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

	override string toString() const {
		return "GQLDType";
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

class GQLDSchema(Con) : GQLDMap!(Con) {
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
		if(auto op = t.toObject()) {
			if(op.name == "__schema") {
				switch(field) {
					case "types":
						return this.__listType;
					case "queryTypes":
						return this.__type;
					case "mutationTypes":
						return this.__nullableType;
					case "subscriptionType":
						return this.__nullableType;
					default:
						assert(false,
								"introspecting directive not yet supported"
							);
				}
			} else if(op.name == "__type") {
			} else if(op.name == "__field") {
			} else if(op.name == "__inputValue") {
			} else if(op.name == "__enumValue") {
			}
		}
		if(auto s = t.toScalar()) {
			return s;
		} else if(auto op = t.toOperation()) {
			return op.returnType;
		} else if(auto map = t.toMap()) {
			if(field in map.member) {
				return map.member[field];
			} else {
				//logf("%s %s", t.toString(), field);
				return null;
			}
		} else {
			logf("%s", t.toString());
			return null;
		}
	}

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

string toShortString(Con)(const(GQLDType!(Con)) e) {
	if(auto o = cast(const(GQLDObject!(Con)))e) {
		return o.name;
	} else if(auto u = cast(const(GQLDUnion!(Con)))e) {
		return u.name;
	} else {
		return e.toString();
	}
}

GQLDType!(Con) typeToGQLDType(Type, Con)(ref GQLDSchema!(Con) ret) {
	pragma(msg, Type.stringof, " ", isIntegral!Type);
	static if(is(Type == bool)) {
		GQLDBool!(Con) r;
		if("bool" in ret.types) {
			r = cast(GQLDBool!(Con))ret.types["bool"];
		} else {
			r = new GQLDBool!(Con)();
			ret.types["bool"] = r;
		}
		return r;
	} else static if(isFloatingPoint!(Type)) {
		GQLDFloat!(Con) r;
		if("float" in ret.types) {
			r = cast(GQLDFloat!(Con))ret.types["float"];
		} else {
			r = new GQLDFloat!(Con)();
			ret.types["float"] = r;
		}
		return r;
	} else static if(isIntegral!(Type)) {
		GQLDInt!(Con) r;
		if("int" in ret.types) {
			r = cast(GQLDInt!(Con))ret.types["int"];
		} else {
			r = new GQLDInt!(Con)();
			ret.types["int"] = r;
		}
		pragma(msg, "166 ", Type.stringof, " int");
		return r;
	} else static if(isSomeString!Type) {
		GQLDString!(Con) r;
		if("string" in ret.types) {
			r = cast(GQLDString!(Con))ret.types["string"];
		} else {
			r = new GQLDString!(Con)();
			ret.types["string"] = r;
		}
		return r;
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

alias QueryResolver(Con) = Json delegate(string name, Json parent,
		Json args, ref Con context) @safe;

QueryResolver!(Con) buildTypeResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			logf("%s", args);
			Json ret;
			return ret;
		};
	return ret;
}

GQLDSchema!(Con) toSchema2(Type, Con)() {
	typeof(return) ret = new typeof(return)();
	ret.__schema = new GQLDObject!Con("__schema");
	ret.__type = new GQLDObject!Con("__type");
	ret.__type.resolver = buildTypeResolver!(Type, Con)();
	ret.__field = new GQLDObject!Con("__field");
	ret.__inputValue = new GQLDObject!Con("__inputValue");
	ret.__enumValue = new GQLDObject!Con("__enumValue");

	ret.__listType = new GQLDList!Con(ret.__type);
	ret.__listField = new GQLDList!Con(ret.__field);
	ret.__listInputValue = new GQLDList!Con(ret.__inputValue);
	ret.__listEnumValue = new GQLDList!Con(ret.__enumValue);

	ret.__nullableType = new GQLDNullable!Con(ret.__type);
	ret.__nullableField = new GQLDNullable!Con(ret.__field);
	ret.__nullableInputValue = new GQLDNullable!Con(ret.__inputValue);

	ret.__listNullableType = new GQLDList!Con(ret.__nullableType);
	ret.__listNullableField = new GQLDList!Con(ret.__nullableField);
	ret.__listNullableInputValue = new GQLDList!Con(ret.__nullableInputValue);

	ret.__nullableListNullableType =
			new GQLDNullable!Con(ret.__listNullableType);
	ret.__nullableListNullableField =
			new GQLDNullable!Con(ret.__listNullableField);
	ret.__nullableListNullableInputValue =
			new GQLDNullable!Con(ret.__listNullableInputValue);

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
