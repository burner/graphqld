module schema2;

import std.array;
import std.traits;
import std.typecons;
import std.algorithm : map, joiner;
import std.range : ElementEncodingType;
import std.format;
import std.experimental.logger;

import vibe.data.json;

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

	const GQLDKind kind;
	alias Resolver = Json delegate(string name, Json parent,
			Json args, ref Context context);

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
}

class GQLDScalar(Con) : GQLDType!(Con) {
	this(GQLDKind kind) {
		super(kind);
	}
}

class GQLDString(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.String);
	}

	override string toString() {
		return "String";
	}
}

class GQLDFloat(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.Float);
	}

	override string toString() {
		return "Float";
	}
}

class GQLDInt(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.Int);
	}

	override string toString() {
		return "Int";
	}
}

class GQLDEnum(Con) : GQLDScalar!(Con) {
	string enumName;
	this(string enumName) {
		super(GQLDKind.Enum);
		this.enumName = enumName;
	}

	override string toString() {
		return this.enumName;
	}
}

class GQLDBool(Con) : GQLDScalar!(Con) {
	this() {
		super(GQLDKind.Bool);
	}

	override string toString() {
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

	override string toString() {
		auto app = appender!string();
		foreach(key, value; this.member) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}
		return app.data;
	}
}

class GQLDObject(Con) : GQLDMap!(Con) {
	string name;
	GQLDObject!(Con) base;

	this(string name) {
		super(GQLDKind.Object_);
		this.name = name;
	}

	override string toString() {
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
	string name;

	this(string name) {
		super(GQLDKind.Union);
		this.name = name;
	}

	override string toString() {
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
		this.elementType = elemType;
	}

	override string toString() {
		return format("List(%s)", this.elementType.toShortString());
	}
}

class GQLDNullable(Con) : GQLDType!(Con) {
	GQLDType!(Con) elementType;

	this(GQLDType!(Con) elemType) {
		super(GQLDKind.Nullable);
		this.elementType = elemType;
	}

	override string toString() {
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

	override string toString() {
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
	}
}

class GQLDMutation(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Mutation);
	}
}

class GQLDSubscription(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Subscription);
	}
}

class GQLDSchema(Con) : GQLDMap!(Con) {
	GQLDType!(Con)[string] types;

	this() {
		super(GQLDKind.Schema);
	}

	override string toString() {
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

GQLDType!(Con) getReturnType(Con)(GQLDType!Con t, string field) {
	if(auto s = t.toScalar()) {
		return s;
	}
	if(auto op = t.toOperation()) {
		return op.returnType;
	}
	if(auto map = t.toMap()) {
		if(field in map.member) {
			return map.member[field];
		}
	}
	return null;
}

string toShortString(Con)(GQLDType!(Con) e) {
	if(auto o = cast(GQLDObject!(Con))e) {
		return o.name;
	} else if(auto u = cast(GQLDUnion!(Con))e) {
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

GQLDSchema!(Con) toSchema2(Type, Con)() {
	typeof(return) ret = new typeof(return)();

	pragma(msg, __traits(allMembers, Type));
	static foreach(qms; ["query", "mutation", "subscription"]) {{
		GQLDMap!(Con) cur = new GQLDMap!Con();
		ret.member[qms] = cur;
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
