module schema2;

import std.traits;
import std.typecons;
import std.algorithm : map, joiner;
import std.range : ElementEncodingType;
import std.format;

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
	Nullable,
	Union,
	Query,
	Mutation,
	Subscription
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
				if(name in parent) {
					return parent;
				} else {
					return Json.emptyObject();
				}
			};
	}
}

class GQLDString(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.String);
	}

	override string toString() {
		return "String";
	}
}

class GQLDFloat(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.Float);
	}

	override string toString() {
		return "Float";
	}
}

class GQLDInt(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.Int);
	}

	override string toString() {
		return "Int";
	}
}

class GQLDEnum(Con) : GQLDType!(Con) {
	string enumName;
	this(string enumName) {
		super(GQLDKind.Enum);
		this.enumName = enumName;
	}

	override string toString() {
		return this.enumName;
	}
}

class GQLDBool(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.Bool);
	}

	override string toString() {
		return "Bool";
	}
}

class GQLDObject(Con) : GQLDType!(Con) {
	string name;
	GQLDType!(Con)[string] fields;
	GQLDObject!(Con) base;

	this(string name) {
		super(GQLDKind.Object_);
		this.name = name;
	}

	override string toString() {
		return format("Object %s(%s))\n\t\t\t\tBase(%s)",
				this.name,
				this.fields
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t"),
				(this.base !is null ? this.base.toShortString() : "null")
			);
	}
}

class GQLDUnion(Con) : GQLDType!(Con) {
	string name;
	GQLDType!(Con)[string] members;

	this(string name) {
		super(GQLDKind.Union);
		this.name = name;
	}

	override string toString() {
		return format("Union %s(%s))",
				this.name,
				this.members
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

string toShortString(Con)(GQLDType!(Con) e) {
	if(auto o = cast(GQLDObject!(Con))e) {
		return o.name;
	} else if(auto u = cast(GQLDUnion!(Con))e) {
		return u.name;
	} else {
		return e.toString();
	}
}

GQLDType!(Con) typeToGQLDType(Type, Con)(ref GQLDType!(Con)[string] ret) {
	pragma(msg, Type.stringof, " ", isIntegral!Type);
	static if(is(Type == bool)) {
		GQLDBool!(Con) r;
		if("bool" in ret) {
			r = cast(GQLDBool!(Con))ret["bool"];
		} else {
			r = new GQLDBool!(Con)();
			ret["bool"] = r;
		}
		return r;
	} else static if(isFloatingPoint!(Type)) {
		GQLDFloat!(Con) r;
		if("float" in ret) {
			r = cast(GQLDFloat!(Con))ret["float"];
		} else {
			r = new GQLDFloat!(Con)();
			ret["float"] = r;
		}
		return r;
	} else static if(isIntegral!(Type)) {
		GQLDInt!(Con) r;
		if("int" in ret) {
			r = cast(GQLDInt!(Con))ret["int"];
		} else {
			r = new GQLDInt!(Con)();
			ret["int"] = r;
		}
		pragma(msg, "166 ", Type.stringof, " int");
		return r;
	} else static if(isSomeString!Type) {
		GQLDString!(Con) r;
		if("string" in ret) {
			r = cast(GQLDString!(Con))ret["string"];
		} else {
			r = new GQLDString!(Con)();
			ret["string"] = r;
		}
		return r;
	} else static if(is(Type == enum)) {
		GQLDEnum!(Con) r;
		if(Type.stringof in ret) {
			r = cast(GQLDEnum!(Con))ret[Type.stringof];
		} else {
			r = new GQLDEnum!(Con)();
			ret[Type.stringof] = r;
		}
		return r;
	} else static if(is(Type == union)) {
		GQLDUnion!(Con) r;
		if(Type.stringof in ret) {
			r = cast(GQLDUnion!(Con))ret[Type.stringof];
		} else {
			r = new GQLDUnion!(Con)(Type.stringof);
			ret[Type.stringof] = r;

			alias fieldNames = FieldNameTuple!(Type);
			alias fieldTypes = Fields!(Type);
			static foreach(idx; 0 .. fieldNames.length) {{
				r.members[fieldNames[idx]] =
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
		if(Type.stringof in ret) {
			r = cast(GQLDObject!(Con))ret[Type.stringof];
		} else {
			r = new GQLDObject!(Con)(Type.stringof);
			ret[Type.stringof] = r;

			alias fieldNames = FieldNameTuple!(Type);
			alias fieldTypes = Fields!(Type);
			static foreach(idx; 0 .. fieldNames.length) {{
				r.fields[fieldNames[idx]] =
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

GQLDType!(Con)[string] toSchema2(Type, Con)() {
	GQLDType!(Con)[string] ret;

	pragma(msg, __traits(allMembers, Type));
	static foreach(qms; ["query", "mutation", "subscription"]) {{
		static assert(__traits(hasMember, Type, qms));
		alias QMSType = typeof(__traits(getMember, Type, qms));
		static foreach(mem; __traits(allMembers, QMSType)) {{
			alias MemType = typeof(__traits(getMember, QMSType, mem));
			static if(isCallable!(MemType)) {{
				ret[mem] = qms == "query" ? new GQLDQuery!Con()
					: qms == "mutation" ? new GQLDMutation!Con()
					: qms == "subscription" ? new GQLDSubscription!Con()
					: null;
				GQLDOperation!(Con) op = cast(GQLDOperation!Con)ret[mem];
				assert(op !is null);
				op.returnType = typeToGQLDType!(ReturnType!(MemType), Con)(ret);

				alias paraNames = ParameterIdentifierTuple!(
						__traits(getMember, QMSType, mem)
					);
				alias paraTypes = Parameters!(
						__traits(getMember, QMSType, mem)
					);
				pragma(msg, "\n ", mem);
				pragma(msg, "names ", paraNames);
				pragma(msg, "types ", paraTypes);
				static foreach(idx; 0 .. paraNames.length) {
					op.parameters[paraNames[idx]] =
						typeToGQLDType!(paraTypes[idx], Con)(ret);
				}
			}}
		}}
		//ret[qms] = tmp;
	}}
	return ret;
}

string toString(Con)(ref GQLDType!(Con)[string] all) {
	import std.array;
	auto app = appender!string();
	foreach(key, value; all) {
		formattedWrite(app, "%20s: %s\n", key, value.toString());
	}
	return app.data;
}
