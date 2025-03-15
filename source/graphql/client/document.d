/// A CTFE-friendly representation of (a subset of)
/// GraphQL documents (schemas and queries).
module graphql.client.document;

// This is an internal module.
package(graphql):

import ast = graphql.ast;

/*
  Q: Why mirror the AST type hierarchy, isn't it redundant?
  A: 1. By restricting the representation to a certain subset of the D type system,
        we can allow the representation to be used in more ways (e.g. as "enum"
		instead of "static const").
	 2. Dealing with the AST is a little verbose in some situations (e.g.
	    VariableDefinition.var.name.value), doing this as a separate step
		allows us to avoid pushing this complexity into the code generating D types.
	 3. We can cull parts of the document that are not relevant to D code generation.
     4. By walking the AST ahead of time, we can do some work only once instead of
	    per query template instantiation (`schema.query!"..."`).
	 5. In case parsing the schema at compile-time becomes too expensive,
	    in the future we could add support to dumping the parsed representation
		of the GraphQL schema to .d files (which would be useful as the GraphQL
		schema usually changes much rarer than the queries when building clients).
 */

struct Type {
	// Only one (of name / list / nullable) may be set:
	string name;
	// We use a 0-or-1-element dynamic array instead of a pointer,
	// because struct pointers are not very CTFE-friendly
	Type[] list;
	Type[] nullable;

	this(ast.Type t) {
		final switch (t.ruleSelection) {
			case ast.TypeEnum.TN:
				name = t.tname.value;
				break;
			case ast.TypeEnum.LN:
				list = [Type(t.list.type)];
				break;
			case ast.TypeEnum.T:
				nullable.length = 1;
				nullable[0].name = t.tname.value;
				break;
			case ast.TypeEnum.L:
				nullable.length = 1;
				nullable[0].list = [Type(t.list.type)];
				break;
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct FieldDefinition {
	string name;
	Type type;

	this(ast.FieldDefinition fd) {
		if (auto des = fd.des) { /* TODO handle description */ }
		if (auto arg = fd.arg) { /* TODO handle arguments */ }
		if (auto dir = fd.dir) { /* TODO handle directives */ }

		this.name = fd.name.tok.value;
		this.type = Type(fd.typ);
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct InterfaceTypeDefinition {
	string name;
	FieldDefinition[] fields;

	this(ast.InterfaceTypeDefinition itd) {
		this.name = itd.name.value;
		for (auto fds = itd.fds; fds !is null; fds = fds.follow) {
			if (auto fd = fds.fd) {
				this.fields ~= FieldDefinition(fd);
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct ObjectTypeDefinition {
	string name;
	string[] implementsInterfaces;
	FieldDefinition[] fields;

	this(ast.ObjectTypeDefinition otd) {
		this.name = otd.name.value;
		for (auto fds = otd.fds; fds !is null; fds = fds.follow) {
			if (auto fd = fds.fd) {
				this.fields ~= FieldDefinition(fd);
			}
		}
		if (auto ii = otd.ii) {
			for (auto nts = ii.nts; nts !is null; nts = nts.follow) {
				this.implementsInterfaces ~= nts.name.value;
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct InputValueDefinition {
	string name;
	Type type;

	this(ast.InputValueDefinition ivd) {
		this.name = ivd.name.tok.value;
		this.type = Type(ivd.type);
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct InputObjectTypeDefinition {
	string name;
	InputValueDefinition[] values;

	this(ast.InputObjectTypeDefinition otd) {
		this.name = otd.name.value;
		for (auto ivds = otd.ivds; ivds !is null; ivds = ivds.follow) {
			if (auto iv = ivds.iv) {
				this.values ~= InputValueDefinition(iv);
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct ScalarTypeDefinition {
	string name;

	this(ast.ScalarTypeDefinition std) {
		this.name = std.name.value;
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct EnumValueDefinition {
	string name;

	this(ast.EnumValueDefinition evd) {
		this.name = evd.name.value;
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct EnumTypeDefinition {
	string name;
	EnumValueDefinition[] values;

	this(ast.EnumTypeDefinition etd) {
		this.name = etd.name.value;
		for (auto evds = etd.evds; evds !is null; evds = evds.follow) {
			if (auto evd = evds.evd) {
				this.values ~= EnumValueDefinition(evd);
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

alias OperationTypeEnum = ast.OperationTypeEnum;

struct OperationTypeDefinition {
	OperationTypeEnum type;
	string name;

	this(ast.OperationTypeDefinition otd) {
		this.type = otd.ot.ruleSelection;
		this.name = otd.nt.value;
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct SchemaDefinition {
	OperationTypeDefinition[] operationTypes;

	this(ast.SchemaDefinition sch) {
		for (auto otds = sch.otds; otds !is null; otds = otds.follow) {
			if (otds.otd) {
				this.operationTypes ~= OperationTypeDefinition(otds.otd);
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct SchemaDocument {
	SchemaDefinition schema;
	ObjectTypeDefinition[] objectTypes;
	InterfaceTypeDefinition[] interfaceTypes;
	ScalarTypeDefinition[] scalarTypes;
	EnumTypeDefinition[] enumTypes;
	InputObjectTypeDefinition[] inputTypes;

	this(ast.Document d) {
		for (auto defs = d.defs; defs !is null; defs = defs.follow) {
			if (auto def = defs.def) {
				if (auto type = def.type) {
					if (auto sch = type.sch) {
						assert(schema is SchemaDefinition.init,
							"Multiple schema definitions in document");
						this.schema = SchemaDefinition(sch);
					}

					if (auto td = type.td) {
						if (auto otd = td.otd) {
							this.objectTypes ~= ObjectTypeDefinition(otd);
						}
						if (auto itd = td.itd) {
							this.interfaceTypes ~= InterfaceTypeDefinition(itd);
						}
						if (auto std = td.std) {
							this.scalarTypes ~= ScalarTypeDefinition(std);
						}
						if (auto etd = td.etd) {
							this.enumTypes ~= EnumTypeDefinition(etd);
						}
						if (auto iod = td.iod) {
							this.inputTypes ~= InputObjectTypeDefinition(iod);
						}
					}
				}
			}
		}

		if (this.schema is SchemaDefinition.init) {
			// Populate with the default
			this.schema = SchemaDefinition([
				OperationTypeDefinition(OperationTypeEnum.Query, "Query"),
				OperationTypeDefinition(OperationTypeEnum.Mutation, "Mutation"),
				OperationTypeDefinition(OperationTypeEnum.Sub, "Subscription"),
			]);
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct Field {
	string name;
	Field[] selections;

	this(ast.Field f) {
		this.name = f.name.name.tok.value;
		if (auto ss = f.ss) {
			for (auto sels = ss.sel; sels !is null; sels = sels.follow) {
				if (auto sel = sels.sel) {
					if (auto field = sel.field) {
						this.selections ~= Field(field);
					}
				}
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct VariableDefinition {
	string name;
	Type type;

	this(ast.VariableDefinition vd) {
		this.name = vd.var.name.value;
		this.type = Type(vd.type);
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct OperationDefinition {
	OperationTypeEnum type;
	string name;
	VariableDefinition[] variables;
	Field[] selections;

	this(ast.OperationDefinition od) {
		this.type = od.ot ? od.ot.ruleSelection : OperationTypeEnum.Query;
		this.name = od.name.value;
		if (auto vd = od.vd) {
			for (auto vars = vd.vars; vars !is null; vars = vars.follow) {
				if (auto var = vars.var) {
					this.variables ~= VariableDefinition(var);
				}
			}
		}
		if (auto ss = od.ss) {
			for (auto sels = ss.sel; sels !is null; sels = sels.follow) {
				if (auto sel = sels.sel) {
					if (auto field = sel.field) {
						this.selections ~= Field(field);
					}
				}
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}

struct QueryDocument {
	OperationDefinition[] operations;

	this(ast.Document d) {
		for (auto defs = d.defs; defs !is null; defs = defs.follow) {
			if (auto def = defs.def) {
				if (auto op = def.op) {
					operations ~= OperationDefinition(op);
				}
			}
		}
	}
	this(typeof(this.tupleof) args) { this.tupleof = args; }
}
