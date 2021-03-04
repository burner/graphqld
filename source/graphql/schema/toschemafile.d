module graphql.schema.toschemafile;

import std.array;
import std.algorithm.iteration : map, joiner;
import std.conv : to;
import std.stdio;
import std.format;
import std.typecons;

import graphql.graphql;
import graphql.schema.types;
import graphql.uda;

string schemaToString(T)(GQLDSchema!T sch) {
	auto app = appender!string();

	TraceableType[string] symTab;

	formIndent(app, 0, "schema {");
	foreach(it; gqlSpecialOps.byKeyValue) {
		if(auto mem = it.key in sch.member) {
			formIndent(app, 1, "%s: %s", it.value, mem.name);
			traceType(*mem, symTab);
		}
	}
	formIndent(app, 0, "}");

	foreach(type; symTab.byValue) {
		typeImpl(app, type, symTab);
	}

	return app.data;
}

string schemaToString(T)() {
	import graphql.schema.resolver;
	return schemaToString(toSchema!T());
}

string schemaToString(T, Q)(GraphQLD!(T, Q) gqld) {
	return schemaToString(gqld.schema);
}

private:

static immutable string[string] gqlSpecialOps;
shared static this() {
	gqlSpecialOps = [ "mutationType":     "mutation",
	                  "queryType":        "query",
	                  "subscriptionType": "subscription"];
}

// for tracing; taken from gc algorithms
enum Colour {
	grey,  // currently being traced (need this to deal with recursive types)
	black, // done
	// there's also white, for as-yet untouched objects.  But we don't need
	// this because we cheat by putting all types into a flat table
}

// indeterminate is a good .init value
// but we want the ordering inputOutput < indeterminate < hasOutputOnly
// so that if we want the intersection of two visibilities, we just take the maximum
enum Visibility {
	indeterminate,
	inputOutput = indeterminate - 1,
	hasOutputOnly = indeterminate + 1,
}

struct TraceableType {
	GQLDType type;
	Colour colour;
	Visibility vis; // only valid for black types
}

void formIndent(Out, Args...)(ref Out o, size_t indent, string s, Args args) {
	foreach(it; 0 .. indent) {
		formattedWrite(o, "\t");
	}
	formattedWrite(o, s, args);
	formattedWrite(o, "\n");
}

bool isNameSpecial(string s) {
	import std.algorithm.searching: startsWith, canFind;
	// takes care of gql buildins (__Type, __TypeKind, etc.), as well as
	// some unuseful pieces from the d side (__ctor, opCmp, etc.)
	return s.startsWith("__") || s.startsWith("op") || ["factory", "toHash", "toString"].canFind(s);
}

bool isPrimitiveType(const(GQLDType) type) {
	return type.kind == GQLDKind.String
		|| type.kind == GQLDKind.Float
		|| type.kind == GQLDKind.Int
		|| type.kind == GQLDKind.Bool;
}

// all members of o, including derived ones
inout(GQLDType)[string] allMember(inout(GQLDMap) m) {
	import std.algorithm;
	GQLDType[string] ret;

	void process(GQLDMap m) {
		m.member.byPair.each!((k,v) => ret.require(k,v));

		if(auto o = cast(GQLDObject)m) {
			if(o.base) {
				process(o.base);
			}
		}
	}

	// inout(V)[K].require is broken
	process(cast()m);
	return cast(inout(GQLDType)[string])ret;
}

Visibility traceType(GQLDType t, ref TraceableType[string] tab) {
	import std.algorithm.comparison : max;
	import std.algorithm.iteration : filter;
	import std.range.primitives : empty;

	if(isPrimitiveType(t) || isNameSpecial(t.name)) {
		return Visibility.inputOutput;
	}

	if(t.baseTypeName in tab) {
		return tab[t.baseTypeName].colour == Colour.black
		 ? tab[t.baseTypeName].vis
		 : max(tab[t.baseTypeName].vis, Visibility.indeterminate);
	}

	// identifies itself as an object, but we really want to dump it as a scalar
	if((cast(GQLDObject)t && (cast(GQLDObject)t)
	                                 .allMember.byKey
	                                 .filter!(m => !isNameSpecial(m))
	                                 .empty)
	    || cast(GQLDUnion)t) {
		auto n = new GQLDScalar(GQLDKind.SimpleScalar);
		n.name = t.name;
		tab[n.name] = TraceableType(n, Colour.black, Visibility.inputOutput);
		return tab[n.name].vis;
	}
	if(cast(GQLDScalar)t) {
		tab[t.name] = TraceableType(t, Colour.black, Visibility.inputOutput);
		return tab[t.name].vis;
	}

	if(auto op = cast(GQLDOperation)t) {
		traceType(op.returnType, tab);
		foreach(val; op.parameters.byValue) {
			traceType(val, tab);
		}
		return Visibility.hasOutputOnly;
	} else if(auto l = cast(GQLDList)t) {
		return traceType(l.elementType, tab);
	} else if(auto nn = cast(GQLDNonNull)t) {
		return traceType(nn.elementType, tab);
	} else if(auto nul = cast(GQLDNullable)t) {
		return traceType(nul.elementType, tab);
	}

	auto map = cast(GQLDMap)t;
	if(!map) {
		return Visibility.inputOutput; // won't be dumped anyway, so doesn't matter
	}

	tab[map.name] = TraceableType(map, Colour.grey, map.outputOnlyMembers.length ? Visibility.hasOutputOnly : Visibility.inputOutput);
	scope(exit) tab[map.name].colour = Colour.black;

	foreach(mem, val; map.allMember) {
		if(isNameSpecial(mem) || isPrimitiveType(val)) {
			continue;
		}

		tab[map.name].vis = max(traceType(val, tab), tab[map.name].vis);
	}

	return tab[map.name].vis;
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

string baseTypeName(const(GQLDType) t) {
	if(auto base = cast(const(GQLDNullable))t) {
		return baseTypeName(base.elementType);
	} else if(auto list = cast(const(GQLDList))t) {
		return baseTypeName(list.elementType);
	} else if(auto nn = cast(const(GQLDNonNull))t) {
		return baseTypeName(nn.elementType);
	}
	return t.name;
}

string typeKindToString(TypeKind tk) {
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

void typeImpl(Out)(ref Out o, TraceableType type, in TraceableType[string] tab) {
	assert(!isPrimitiveType(type.type) && !isNameSpecial(type.type.baseTypeName));

	if(auto enu = cast(GQLDEnum)type.type) {
		formIndent(o, 0, "enum %s {", enu.name);

		foreach (m; enu.memberNames) {
			formIndent(o, 1, "%s,", m);
		}

		formIndent(o, 0, "}");
		return;
	}

	if(cast(GQLDScalar)type.type) {
		// it's not allowed to have, for instance, 'scalar subscriptionType'
		// so special-case the top-level operations to have a dummy member
		if(type.type.name in gqlSpecialOps) {
			formIndent(o, 0, "type %s { _: Boolean }", type.type.name);
		} else {
			formIndent(o, 0, "scalar %s", type.type.name);
		}
		return;
	}

	const map = cast(GQLDMap)type.type;
	if(!map) {
		formIndent(o, 0, "# graphqld couldn't format type '%s' / '%s' / '%s'", type.type.kind, type.type.name, type.type);
		return;
	}

	void dumpMem(bool inputType) {
		string typeToStringMaybeIn(const(GQLDType) t) {
			return gqldTypeToString(t, inputType && t.baseTypeName in tab && tab[t.baseTypeName].vis != Visibility.inputOutput ? "In" : "");
		}

		foreach(mem, value; map.allMember) {
			if(isNameSpecial(mem) || (inputType && (mem in map.outputOnlyMembers || (cast(GQLDOperation)value && map.name != "mutationType")))) {
				continue;
			}

			if(auto op = cast(GQLDOperation)value) {
				if (op.parameters.keys().length) {
					formIndent(o, 1, "%s(%s): %s", mem,
					        op.parameters.byKeyValue().map!(kv => format("%s: %s", kv.key,
					                                        typeToStringMaybeIn(kv.value)))
					                .joiner(", ")
					                .to!string,
					        map.name == "mutationType" ? gqldTypeToString(op.returnType)
					                                   : typeToStringMaybeIn(op.returnType));
				} else {
					// apparently graphql doesn't allow foo(): bar
					// so special-case that and turn it into foo: bar
					formIndent(o, 1, "%s: %s", mem,
					        map.name == "mutationType" ? gqldTypeToString(op.returnType)
					                                   : typeToStringMaybeIn(op.returnType));
				}
			} else {
				formIndent(o, 1, "%s: %s", mem, typeToStringMaybeIn(value));
			}
		}
	}

	string typestr = "type";
	if(auto unio = cast(GQLDUnion)map) {
		typestr = "union";
	} else if(auto obj = cast(GQLDObject)map) {
		typestr = typeKindToString(obj.typeKind);
	}

	formIndent(o, 0, "%s %s {", typestr, map.name);
	dumpMem(map.name == "mutationType");
	formIndent(o, 0, "}");

	if (type.vis == Visibility.indeterminate) {
		formIndent(o, 0, "# note: nestedness of type '%s' not determined; output may be suboptimal", map.name);
	}

	if(type.vis != Visibility.inputOutput && map.name !in gqlSpecialOps) {
		formIndent(o, 0, "input %sIn {", map.name);
		dumpMem(true);
		formIndent(o, 0, "}");
	}
}
