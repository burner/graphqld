module schema2;

import std.traits;
import std.typecons;
import std.range : ElementEncodingType;

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
	NotNullable,
	Query,
	Mutation,
	Subscription
}

abstract class GQLDType(Con) {
	alias Context = Con;

	const GQLDKind kind;
	Json resolver = delegate(string name, Json parent,
			Json args, ref Context context);

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
			}
	}
}

class GQLDString(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.String);
	}
}

class GQLDFloat(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.Float);
	}
}

class GQLDInt(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.Int);
	}
}

class GQLDEnum(Con) : GQLDType!(Con) {
	string enumName;
	this(string enumName) {
		super(GQLDKind.Enum);
		this.enumName = enumName;
	}
}

class GQLDBool(Con) : GQLDType!(Con) {
	this() {
		super(GQLDKind.Bool);
	}
}

class GQLDObject(Con) : GQLDType!(Con) {
	string name;
	GQLDType[string] fields;
	GQLDObject!(Con) base;

	this(string name) {
		super(GQLDKind.Object_);
		this.name = name;
	}
}

class GQLDList(Con) : GQLDType!(Con) {
	GQLDType!(Con) elementType;

	this() {
		super(GQLDKind.List);
	}
}

class GQLDNotNullable!(Con) : GQLDType!(Con) {
	GQLDType!(Con) elementType;

	this() {
		super(GQLDKind.NotNullable);
	}
}

class GQLDOperation!(Con) : GQLDType!(Con) {
	GQLDType!(Con) returnType;
	string returnTypeName;

	GQLDType!(Con)[string] parameters;

	this(GQLDKind kind) {
		super(kind);
	}
}

class GQLDQuery!(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Query);
	}
}

class GQLDMutation!(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Mutation);
	}
}

class GQLDSubscription!(Con) : GQLDOperation!(Con) {
	this() {
		super(GQLDKind.Subscription);
	}
}

GQLDType!(Con) typeToGQLDType!(Type, Con)(ref GQLDType!(Con)[string] ret) {
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
		GQLDFloatingPoint!(Con) r;
		if("float" in ret) {
			r = cast(GQLDFloatingPoint!(Con))ret["float"];
		} else {
			r = new GQLDFloatingPoint!(Con)();
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
	} else static if(isAggregateType!Type) {
		GQLDObject!(Con) r;
		if(Type.stringof in ret) {
			r = cast(GQLDObject!(Con))ret[Type.stringof];
		} else {
			r = new GQLDObject!(Con)(Type.stringof);
			ret[Type.stringof] = r;
		}

		FieldNameTuple!(Type) fieldNames;
		Fields!(Type) fieldTypes;
		static foreach(idx, 0 .. fieldNames.length) {
			r[fieldNames[idx]] = typeToGQLDType!(fieldTypes[idx], Con)(ret);
		}

		BaseClassesTuple!(Type) bct;
		assert(bct.length < 3, Type.stringof);
		static foreach(bc; bct) {
			static if(is(bc == Object)) {
				r.base = typeToGQLDType!(bc, Con)(ret);
			}
		}
		return r;
	} else static if(is(T : Nullable!F, F)) {
		return new GQLDNotNullable!(Con)(typeToGQLDType!(F, Con)(ret));
	} else static if(isArray!Type) {
		return new GQLDList!(Con)(
				typeToGQLDType!(ElementEncodingType!Type, Con)(ret)
			);
	}
	static assert(false, Type.stringof);
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
				ret[mem] = qms == "query" ? new GQLDQuery()
					: qms == "mutation" ? new GQLDMutation()
					: qms == "subscription" ? new GQLDSubscription()
					: null;
				GQLDOperation!(Con) op = cast(GQLDOperation)ret[mem];
				assert(op !is null);
				op.returnType = typeToGQLDType!(ReturnType!(MemType), Con)(ret);
			}}
		}}
		ret[qms] = tmp;
	}}
	return ret;
}

string toString(Con)(ref GQLDType!(Con)[string] all) {
	return "";
}
