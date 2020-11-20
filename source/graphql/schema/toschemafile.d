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
    import std.algorithm.iteration : filter;
    import std.range.primitives : empty;

    bool isNameSpecial(string s) {
        import std.algorithm.searching: startsWith;
        // takes care of gql buildins (__Type, __TypeKind, etc.), as well as
        // some unuseful pieces from the d side (__ctor, opCmp, etc.)
        return s.startsWith("__") || s.startsWith("op");
    }
    bool isPrimitiveType(const(GQLDType) type) {
        return type.kind == GQLDKind.String
            || type.kind == GQLDKind.Float
            || type.kind == GQLDKind.Int
            || type.kind == GQLDKind.Bool;
    }

    // Need to use toString instead of name because in the case of (e.g.)
    // Nullable(T), name will just be Nullable, so we won't generate any
    // code for Nullable(U).
    // An alternative would be to put this check after the member type
    // generation, but that causes problems with recursive types.
    if (isPrimitiveType(type) || isNameSpecial(type.name) || type.toString in ah) {
		return;
	}
	ah[type.toString] = true;

    // handle typeImpl for types of members
    if(auto map = cast(const(GQLDMap))type) {
        foreach (val; map.member.byValue) {
            typeImpl(o, val, ah);
        }
	} else if(auto nul = cast(const(GQLDNullable))type) {
		typeImpl(o, nul.elementType, ah);
        return;
    } else if(auto op = cast(const(GQLDOperation))type) {
        typeImpl(o, op.returnType, ah);
        foreach(val; op.parameters.byValue) {
            typeImpl(o, val, ah);
        }
    } else if(auto l = cast(const(GQLDList))type) {
        typeImpl(o, l.elementType, ah);
        return;
    } else if(auto nn = cast(const(GQLDNonNull))type) {
        typeImpl(o, nn.elementType, ah);
        return;
    } else if(auto nul = cast(const(GQLDNullable))type) {
        typeImpl(o, nul.elementType, ah);
        return;
	}

    // if the type is an object or union with no members (or an actual scalar),
    // export it as a scalar and bail here
    if((cast(const(GQLDObject))type && (cast(const(GQLDObject))type)
                                        .member
                                        .byKey
                                        .filter!(m => !isNameSpecial(m))
                                        .empty)
        || (cast(const(GQLDUnion))type && (cast(const(GQLDUnion))type).member.empty)
        || cast(const(GQLDScalar))type) {

        formIndent(o, 0, "scalar %s", type.name);
        return;
    }

    if(auto enu = cast(const(GQLDEnum))type) {
        enumImpl(o, enu);
        return;
    }

    const map = cast(const(GQLDMap))type;
    if(!map) {
        formIndent(o, 0, "# graphqld couldn't format type '%s' / '%s' / '%s'", type.kind, type.name, type);
        return;
    }
    
    {
        string typestr = "type";
        if(auto unio = cast(const(GQLDUnion))type) {
            typestr = "union";
        } else if(auto obj = cast(const(GQLDObject))type) {
            typestr = typeKindToString(obj.typeKind);
        }
		formIndent(o, 0, "%s %s {", typestr, type.name);
	}

    foreach(mem, value; map.member) {
        if(isNameSpecial(mem)) {
            continue;
        }
        if(auto op = cast(const(GQLDOperation))value) {
            if (op.parameters.keys().length) {
                // below causes problems for mutations, so disable temporarily
                formIndent(o, 1, "# %s(%s): %s", mem,
                        operationParmsToString(op),
                        gqldTypeToString(op.returnType));
            } else {
                // apparently graphql doesn't allow foo(): bar
                // so special-case that and turn it into foo: bar
                formIndent(o, 1, "%s: %s", mem,
                        gqldTypeToString(op.returnType));
            }
        } else {
            formIndent(o, 1, "%s: %s", mem, gqldTypeToString(value));
        }
    }

	formIndent(o, 0, "}");
}

unittest {
	import graphql.testschema;

	writeln(schemaToString!(Schema)());
}
