module graphql.schema.toschemafile;

import std.array;
import std.algorithm.iteration : map, joiner;
import std.algorithm.searching : canFind, startsWith;
import std.conv : to;
import std.stdio;
import std.format;
import std.typecons;

import graphql.graphql;
import graphql.schema.types;
import graphql.uda;
import graphql.schema.resolver;
import graphql.helper;

string schemaToString(T)() {
	return schemaToString(toSchema!T());
}

string schemaToString(T, Q)(GraphQLD!(T, Q) gqld) {
	return schemaToString(gqld.schema);
}

string schemaToString(T)(GQLDSchema!T sch) {
	auto app = appender!string();
	TraceType[string] tts;
	formIndent(app, 0, "schema {");
	foreach(it; ["mutationType", "queryType", "subscriptionType"]) {
		auto tPtr = it in sch.member;
		if(tPtr !is null) {
			auto t = *tPtr;
			formIndent(app, 1, "%s: %s", it, t.name);
			tts[t.name] = TraceType(t, false);
		}
	}
	formIndent(app, 0, "}");
	outer: while(true) {
		foreach(key, ref it; tts) {
			if(!it.normalDone
					|| (it.inDone.isNull == false && it.inDone.get() == false)
			) {
				toSchemaString(app, it, tts);
				continue outer;
			}
		}
		break outer;
	}
	return app.data;
}

struct TraceType {
	GQLDType type;
	bool normalDone;
	Nullable!bool inDone;
}

private:

void toSchemaString(Out)(ref Out o, ref TraceType tt, ref TraceType[string] tts) {
	if(isPrimitiveType(tt.type) || isNameSpecial(tt.type.name)) {
		return;
	}
	//writefln("%s %s %s", tt.type.name, tt.normalDone, tt.inDone.isNull()
	//		, !tt.inDone.isNull() ? to!string(tt.inDone.get()) : "");
	if(!tt.normalDone) {
		tt.normalDone = true;
		if(GQLDEnum e = toEnum(tt.type)) {
			formIndent(o, 0, "enum %s {", tt.type.name);
			foreach (m; e.memberNames) {
				formIndent(o, 1, "%s,", m);
			}
			formIndent(o, 0, "}");
		} else if(GQLDLeaf l = toLeaf(tt.type)) {
			formIndent(o, 0, "scalar %s", l.name);
		} else if(GQLDUnion u = toUnion(tt.type)) {
			formIndent(o, 0, "union %s = %--(%s | %)", u.name
					, u.member.byValue.map!(v => baseType(v).name));
		} else if(GQLDMap map = toMap(tt.type)) {
			string implementsStr;
			if(auto obj = cast(GQLDObject)map) {
				if(obj.base && obj.base.typeKind == TypeKind.INTERFACE) {
					implementsStr = " implements " ~ obj.base.name;
				}
			}
			formIndent(o, 0, "%s %s%s {", schemaTypeIndicator(tt.type)
					, tt.type.name, implementsStr);
			foreach(memName, mem; allMember(map)) {
				string typename = typeToStringMaybeIn(mem, false, false);
				if(isNameSpecial(typename)) {
					continue;
				}
				if(GQLDOperation op = toOperation(mem)) {
					formIndent(o, 1, "%s%s: %s%s", memName,
						op.parameters.keys.length > 0
							? format("(%--(%s, %))", op.parameters.byKeyValue
								.map!(kv => format("%s: %s", kv.key,
									typeToStringMaybeIn(kv.value
										, kv.value.udaData.typeKind == TypeKind.INPUT_OBJECT
										, true))))
							: ""
						, op.returnType.gqldTypeToString()
						, typeToDeprecationMessage(mem));
					addIfNew(tts, op.returnType, false);
					foreach(p; op.parameters.byValue) {
						addIfNew(tts, p, true);
					}
				} else {
					formIndent(o, 1, "%s: %s%s", memName, typename
							, typeToDeprecationMessage(mem));
					addIfNew(tts, mem, false);
				}
			}
			formIndent(o, 0, "}");
		}
	}
	if(!tt.inDone.isNull() && tt.inDone.get() == false) {
		tt.inDone = nullable(true);
		if(tt.type.udaData.typeKind != TypeKind.INPUT_OBJECT
			&& tt.type.udaData.typeKind != TypeKind.ENUM
			&& toEnum(tt.type) is null
		) {
			formIndent(o, 0, "input %sIn {", tt.type.name);
			if(GQLDMap map = toMap(tt.type)) {
				foreach(memName, mem; allMember(map)) {
					string typename = typeToStringMaybeIn(mem, false, false);
					if(isNameSpecial(typename)) {
						continue;
					}
					if(GQLDOperation op = toOperation(mem)) {
					} else {
						formIndent(o, 1, "%s: %s%s", memName, typename
								, typeToDeprecationMessage(mem));
					}
				}
			}
			formIndent(o, 0, "}");
		}
	}
}

void addIfNew(ref TraceType[string] tts, GQLDType t, bool isUsedAsInput) {
	t = baseType(t);
	if(isPrimitiveType(t)) {
		return;
	}
	TraceType* tt = t.name in tts;
	if(tt is null) {
		tts[t.name] = TraceType(t, false, Nullable!(bool).init);
		tt = t.name in tts;
	}
	if(isUsedAsInput && (*tt).inDone.isNull() == true) {
		(*tt).inDone = nullable(false);
	}
}

string schemaTypeIndicator(GQLDType t) {
	if(t.udaData.typeKind != TypeKind.UNDEFINED) {
		final switch(t.udaData.typeKind) {
			case TypeKind.UNDEFINED: return "type";
			case TypeKind.SCALAR: return "scalar";
			case TypeKind.OBJECT: return "type";
			case TypeKind.INTERFACE: return "interface";
			case TypeKind.UNION: return "union";
			case TypeKind.ENUM: return "enum";
			case TypeKind.INPUT_OBJECT: return "input";
			case TypeKind.LIST: return "type";
			case TypeKind.NON_NULL: return "type";
		}
	}
	if(auto u = toUnion(t)) {
		return "union";
	} else if(auto e = toEnum(t)) {
		return "enum";
	}
	return "type";
}

void formIndent(Out, Args...)(ref Out o, size_t indent, string s, Args args) {
	foreach(it; 0 .. indent) {
		formattedWrite(o, "\t");
	}
	formattedWrite(o, s, args);
	formattedWrite(o, "\n");
}


bool isPrimitiveType(const(GQLDType) type) {
	return type.kind == GQLDKind.String
		|| type.kind == GQLDKind.Float
		|| type.kind == GQLDKind.Int
		|| type.kind == GQLDKind.Bool;
}

string gqldTypeToString(const(GQLDType) t, string nameSuffix = "", Flag!"nonNullable" nonNullable = Yes.nonNullable) {
	if(auto base = cast(const(GQLDNullable))t) {
		return gqldTypeToString(base.elementType, nameSuffix, No.nonNullable);
	} else if(auto list = cast(const(GQLDList))t) {
		return '[' ~ gqldTypeToString(list.elementType, nameSuffix, Yes.nonNullable) ~ ']' ~ (nonNullable ? "!" : "");
	} else if(auto nn = cast(const(GQLDNonNull))t) {
		return gqldTypeToString(nn.elementType, nameSuffix, Yes.nonNullable);
	}
	return t.name ~ nameSuffix ~ (nonNullable ? "!" : "");
}


string typeToStringMaybeIn(GQLDType t, bool inputType, bool isParam) {
	auto bt = baseType(t);
	const bool baseTypeIsNotInputObject = bt.udaData.typeKind != TypeKind.INPUT_OBJECT;
	const bool isScalar = (toScalar(bt) !is null);
	if(isParam) {
		//writefln("bt: %s, name: %s, baseTypeIsNotInputObject %s, isScalar %s",
		//		bt.kind, bt.name, baseTypeIsNotInputObject, isScalar);
		//writefln("\nt.name: %s\nbaseTypeName: %s\ninputType: %s\nbaseTypeNameInTab: %s\nisNotInputOnly: %s\nisNotInputOrOutput: %s"
		//		~ "\n%s"
		//		, t.name, baseTypeName
		//		, inputType, baseTypeNameInTab
		//		, isNotInputOnly, isNotInputOrOutput
		//		, tab.byKey
		//		);
	}
	return gqldTypeToString(t, isParam && !isScalar && !inputType && baseTypeIsNotInputObject
				//&& baseTypeNameInTab
				//&& isNotInputOnly
				//&& isNotInputOrOutput
			? "In"
			: "");
}

string typeToDeprecationMessage(const(GQLDType) t) {
	return t.deprecatedInfo.isDeprecated == IsDeprecated.yes
		? ` @deprecated(reason: "`
			~ t.deprecatedInfo.deprecationReason
			~ `")`
		: "";
}

GQLDType baseType(GQLDType t) {
	if(auto base = cast(GQLDNullable)t) {
		return baseType(base.elementType);
	} else if(auto list = cast(GQLDList)t) {
		return baseType(list.elementType);
	} else if(auto nn = cast(GQLDNonNull)t) {
		return baseType(nn.elementType);
	}
	return t;
}
