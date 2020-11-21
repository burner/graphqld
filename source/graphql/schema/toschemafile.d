module graphql.schema.toschemafile;

import std.array;
import std.algorithm.iteration : map, joiner;
import std.conv : to;
import std.stdio;
import std.format;

import graphql.schema.types;
import graphql.uda;

private enum Visibility {
    inputOutput,
    outputOnly,
}

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

	Visibility[string] alreadyHandled;
	auto sch = toSchema!T();
	schemaImpl(app, sch, alreadyHandled);

	return app.data;
}

private void schemaImpl(Out, T)(ref Out o, T t, ref Visibility[string] ah) {
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

private Visibility typeImpl(Out)(ref Out o, const(GQLDType) type, ref Visibility[string] ah) {
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
    if (isPrimitiveType(type) || isNameSpecial(type.name)) {
       return Visibility.inputOutput;
    }

    if (auto vis = type.toString in ah) {
		return *vis;
	}

    Visibility ret = Visibility.inputOutput;

    ah[type.toString] = ret;
	scope(exit) {
        ah[type.toString] = ret;
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
        return ret;
    }

    if(auto enu = cast(const(GQLDEnum))type) {
        enumImpl(o, enu);
        return ret;
    }

    // handle typeImpl for types of members
    // need to assign to ret so the exit guard updates ah properly
	if(auto nul = cast(const(GQLDNullable))type) {
		typeImpl(o, nul.elementType, ah);
        return ret;
    } else if(auto op = cast(const(GQLDOperation))type) {
        typeImpl(o, op.returnType, ah);
        foreach(val; op.parameters.byValue) {
            typeImpl(o, val, ah);
        }
        return ret = Visibility.outputOnly;
    } else if(auto l = cast(const(GQLDList))type) {
        return ret = typeImpl(o, l.elementType, ah);
    } else if(auto nn = cast(const(GQLDNonNull))type) {
        return ret = typeImpl(o, nn.elementType, ah);
    } else if(auto nul = cast(const(GQLDNullable))type) {
        return ret = typeImpl(o, nul.elementType, ah);
	}

    const map = cast(const(GQLDMap))type;
    if(!map) {
        formIndent(o, 0, "# graphqld couldn't format type '%s' / '%s' / '%s'", type.kind, type.name, type);
        return ret;
    }
    
    Visibility[] memberVis;
    memberVis.reserve(map.member.values.length);
    foreach(_, val; map.member) {
        memberVis ~= typeImpl(o, val, ah);
        if(memberVis[$-1] == Visibility.outputOnly) {
            ret = Visibility.outputOnly;
        }
    }

    void dumpMem(bool inputType) {
        size_t memi = 0;
        foreach(mem, value; map.member) {
            scope (exit) {
                memi++;
            }
            if(isNameSpecial(mem)) {
                continue;
            }

            if(inputType && memberVis[memi] == Visibility.outputOnly) {
                mem ~= "In";
            }

            if(auto op = cast(const(GQLDOperation))value) {
                if (op.parameters.keys().length) {
                    if(!inputType) {
                        formIndent(o, 1, "%s(%s): %s", mem,
                                operationParmsToString(op),
                                gqldTypeToString(op.returnType));
                    }
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
    }

    string typestr = "type";
    if(auto unio = cast(const(GQLDUnion))type) {
        typestr = "union";
    } else if(auto obj = cast(const(GQLDObject))type) {
        typestr = typeKindToString(obj.typeKind);
    }

    formIndent(o, 0, "%s %s {", typestr, type.name);
    dumpMem(false);
	formIndent(o, 0, "}");

    if (ret == Visibility.outputOnly) {
        formIndent(o, 0, "%s %sIn {", typestr, type.name);
        dumpMem(true);
        formIndent(o, 0, "}");
    }

    return ret;
}

unittest {
	import graphql.testschema;

	writeln(schemaToString!(Schema)());
}
