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
	formIndent(o, 0, "schema {\n");
	foreach(it; qms) {
		auto mem = it[0] in t.member;
		if(mem) {
			formIndent(o, 1, "%s: %s\n", it[1], mem.name);
		}
	}
	formIndent(o, 0, "}\n\n");

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
	if(auto list = cast(const(GQLDList))t) {
		return gqldTypeToString(list.elementType) ~ "[]";
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

private void typeImpl(Out)(ref Out o, const(GQLDType) type, ref bool[string] ah) {
	//formIndent(o, 0, "%s\n\n", type.name);
	if(type.name in ah) {
		return;
	}
	ah[type.name] = true;

	if(auto unio = cast(const(GQLDUnion))type) {
		formIndent(o, 0, "union %s {\n", type.name);
	} else if(auto obj = cast(const(GQLDObject))type) {
		formIndent(o, 0, "%s %s {\n", typeKindToString(obj.typeKind), type.name);
	} else if(auto t = cast(const(GQLDQuery))type) {
		formIndent(o, 0, "%s %s {\n", "type", type.name);
	} else if(auto mu = cast(const(GQLDMutation))type) {
		formIndent(o, 0, "%s %s {\n", "type", type.name);
	} else if(auto sub = cast(const(GQLDSubscription))type) {
		formIndent(o, 0, "%s %s {\n", "type", type.name);
	} else {
		formIndent(o, 0, "stuff %s %s '''%s```\n", type.kind, type.name,
				type.toString());
	}
	if(auto map = cast(const(GQLDMap))type) {
		foreach(mem, value; map.member) {
			if(mem == "__type" || mem == "__schema") {
				continue;
			}
			if(auto op = cast(const(GQLDOperation))value) {
				formIndent(o, 1, "%s(%s): %s;\n", mem,
						operationParmsToString(op),
						gqldTypeToString(op.returnType));
			} else {
				formIndent(o, 1, "%s: %s;\n", mem, gqldTypeToString(value));
			}
		}
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
			}
		}
	}
	formIndent(o, 0, "}\n\n");
}

unittest {
	import graphql.testschema;

	writeln(schemaToString!(Schema)());
}
