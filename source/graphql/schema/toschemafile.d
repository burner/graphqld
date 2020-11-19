module graphql.schema.toschemafile;

import std.array;
import std.algorithm.iteration : map, joiner;
import std.conv : to;
import std.stdio;
import std.format;

import graphql.schema.types;
import graphql.uda;

private void formIndent(Out, Args...)(ref Out o, size_t indent, string s, Args args) {
	foreach(it; 0 .. indent) {
		formattedWrite(o, "\t");
	}
	formattedWrite(o, s, args);
	formattedWrite(o, "\n");
}

string schemaToString(T)() {
	import graphql.schema.resolver;
	auto app = appender!string();

	bool[string] alreadyHandled;
	auto sch = toSchema!T();
	schemaImpl(app, sch, alreadyHandled);

	return app.data;
}

private void schemaImpl(Out, T)(ref Out o, T t, ref bool[string] ah) {
	auto qms =
			[ [ "mutationType", "mutation"]
			, [ "queryType", "query"]
			, [ "subscriptionType", "subscription"]
			];
	formIndent(o, 0, "schema {");
	foreach(it; qms) {
		auto mem = it[0] in t.member;
		if(mem) {
			formIndent(o, 1, "%s: %s", it[1], mem.name);
		}
	}
	formIndent(o, 0, "}");

	foreach(it; qms) {
		typeImpl(o, t.member[it[0]], ah);
	}
}

private string operationParmsToString(const(GQLDOperation) o) {
	return o.parameters.keys().map!(k => format("%s: %s", k,
				o.parameters[k].gqldTypeToString()))
		.joiner(", ")
		.to!string();
}

private string gqldTypeToString(const(GQLDType) t) {
	if(auto base = cast(const(GQLDNullable))t) {
		return gqldTypeToString(base.elementType);
	} else if(auto list = cast(const(GQLDList))t) {
		return '[' ~ gqldTypeToString(list.elementType) ~ ']';
	} else if(auto nn = cast(const(GQLDNonNull))t) {
		return gqldTypeToString(nn.elementType) ~ "!";
	}
	return t.name;
}

private string typeKindToString(TypeKind tk) {
	final switch(tk) {
		case TypeKind.UNDEFINED: return "type";
		case TypeKind.SCALAR: return "SCALAR";
		case TypeKind.OBJECT: return "type";
		case TypeKind.INTERFACE: return "interface";
		case TypeKind.UNION: return "union";
		case TypeKind.ENUM: return "enum";
		case TypeKind.INPUT_OBJECT: return "input";
		case TypeKind.LIST: return "LIST";
		case TypeKind.NON_NULL: return "NON_NULL";
	}
}

private void enumImpl(Out)(ref Out o, const(GQLDEnum) enu) {
	formIndent(o, 0, "enum %s {", enu.name);

	foreach (m; enu.memberNames) {
		formIndent(o, 1, "%s,", m);
	}

	formIndent(o, 0, "}");
}

private void typeImpl(Out)(ref Out o, const(GQLDType) type, ref bool[string] ah) {
	//formIndent(o, 0, "%s", type.name);
	if(type.toString in ah) {
		return;
	}
	ah[type.toString] = true;

	if(auto map = cast(const(GQLDMap))type) {
		foreach(mem, value; map.member) {
			if(auto op = cast(const(GQLDOperation))value) {
				typeImpl(o, op.returnType, ah);
				foreach(key, val; op.parameters) {
					typeImpl(o, val, ah);
				}
			} else if(auto l = cast(const(GQLDList))value) {
				typeImpl(o, l.elementType, ah);
			} else if(auto nn = cast(const(GQLDNonNull))value) {
				typeImpl(o, nn.elementType, ah);
			} else {
				typeImpl(o, value, ah);
			}
		}
	} else if(auto nul = cast(const(GQLDNullable))type) {
		typeImpl(o, nul.elementType, ah);
		return;
	}//else if(type.kind == GQLDKind.CustomLeaf)

	if(auto unio = cast(const(GQLDUnion))type) {
		formIndent(o, 0, "union %s {", type.name);
	} else if(auto obj = cast(const(GQLDObject))type) {
		// if it has no members, print it out as a scalar and bail here
		import std.algorithm.iteration : filter;
		import std.range.primitives : empty;
		if (obj.member.keys
		       .filter!(m => m != "__type" && m != "__schema" && m != "__ctor")
		       .empty) {
			formIndent(o, 0, "scalar %s", type.name);
			return;
		}
		formIndent(o, 0, "%s %s {", typeKindToString(obj.typeKind), type.name);
	} else if(cast(const(GQLDQuery))type
	          || cast(const(GQLDMutation))type
	          || cast(const(GQLDSubscription))type) {
		formIndent(o, 0, "%s %s {", "type", type.name);
    } else if(auto enu = cast(const(GQLDEnum))type) {
        enumImpl(o, enu);
        return;
	} else {
		formIndent(o, 0, "stuff %s %s '''%s```", type.kind, type.name, type.toString());
        return;
	}
	if(auto map = cast(const(GQLDMap))type) {
		foreach(mem, value; map.member) {
			if(mem == "__type" || mem == "__schema" || mem == "__ctor") {
				continue;
			}
			if(auto op = cast(const(GQLDOperation))value) {
                if (op.parameters.keys().length) {
					formIndent(o, 1, "%s(%s): %s", mem,
							operationParmsToString(op),
							gqldTypeToString(op.returnType));
                } else {
					// apparently graphql doesn't allow foo(): bar
					// so we have to special-case that and turn it into foo: bar
					formIndent(o, 1, "%s: %s", mem,
							gqldTypeToString(op.returnType));
				}
			} else {
				formIndent(o, 1, "%s: %s", mem, gqldTypeToString(value));
			}
		}
	}
	formIndent(o, 0, "}");

}

unittest {
	import graphql.testschema;

	writeln(schemaToString!(Schema)());
}
