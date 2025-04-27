/// D code generation.
module graphql.client.codegen;

/// Controls the UDAs and JSON serialization in generated code.
public struct SerializationLibraries {
	bool vibe_data_json;  /// `vibe.data.json` support
	bool ae_utils_json;  /// `ae.utils.json` support
}

/// GraphQL code generation settings.
public struct GraphQLSettings {
	/// Which serialization libraries to generate code for.
	SerializationLibraries serializationLibraries;

	/// Definitions of custom scalars.
	struct CustomScalar {
		/// Type name as it appears in the GraphQL schema.
		string graphqlType;

		/// Fully qualified name of the D type
		/// (use `.imported!"module.name.here"` to specify the module).
		string dType;

		/// Fully qualified name of the serialized type.
		/// This will usually be `"string"`.
		string serializableType = "string";

		enum Direction {
			/// Defines how to convert a serialized value (usually a string) to this type.
			/// Must be a fully-qualified function name, or a self-contained callable D expression.
			/// Example: `.imported!"std.datetime.date".Date.fromISOExtString`
			deserialization,

			/// Defines how to convert this type to a serializable value, as above.
			/// Example: `(x => x.toISOExtString())`
			serialization,
		}
		string[2] transformations;
	}
	CustomScalar[] customScalars; /// ditto
}

// Implementation follows.
package(graphql):

import std.array : join;

import graphql.client.document;

struct CodeGenerationSettings {
	/// A prefix used to qualify referenced type definitions.
	string schemaRefExpr;

	/// User-supplied settings.
	GraphQLSettings graphqlSettings;
}

/// If "name" is a GraphQL custom scalar, get its `CustomScalar` definition.
private const(GraphQLSettings.CustomScalar)* getScalarDefinition(
	string name,
	ref const CodeGenerationSettings settings,
) {
	foreach (ref definition; settings.graphqlSettings.customScalars) {
		if (name == definition.graphqlType) {
			return &definition;
		}
	}
	return null;
}

private enum TypeKind {
	none,  // no such type
	builtin,  // built-in GraphQL scalar type (Int, String...)
	object,
	interface_,
	scalar,  // custom GraphQL scalar
	enum_,
	input,
}
private TypeKind getTypeKind(
	string name,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	switch (name) {
		case "Int":
		case "Float":
		case "String":
		case "Boolean":
		case "ID":
			return TypeKind.builtin;
		default:
	}
	foreach (ref type; document.objectTypes) {
		if (type.name == name) {
			return TypeKind.object;
		}
	}
	foreach (ref type; document.interfaceTypes) {
		if (type.name == name) {
			return TypeKind.interface_;
		}
	}
	foreach (ref type; document.scalarTypes) {
		if (type.name == name) {
			return TypeKind.scalar;
		}
	}
	foreach (ref type; document.enumTypes) {
		if (type.name == name) {
			return TypeKind.enum_;
		}
	}
	foreach (ref type; document.inputTypes) {
		if (type.name == name) {
			return TypeKind.input;
		}
	}
	return TypeKind.none;
}

/// Returns `true` if the D type we would use for the GraphQL type `type`
/// has a `null` value which can map to a GraphQL `null`.
/// Currently, this is equivalent to checking if we would use a D `class` type.
private bool isNativelyNullable(
	ref const Type type,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	if (type.list || type.nullable)
		return false;
	auto typeKind = getTypeKind(type.name, document, settings);
	final switch (typeKind) {
		case TypeKind.none:
			throw new Exception("Unknown type: " ~ type.name);
		case TypeKind.builtin:
		case TypeKind.enum_:
		case TypeKind.scalar:
			return false;
		case TypeKind.object:
		case TypeKind.interface_:
		case TypeKind.input:
			return true;
	}
}

/// Convert a field type to D.
private string toD(
	ref const Type type,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	if (type.list) {
		return toD(type.list[0], document, settings) ~ "[]";
	} else if (type.nullable) {
		auto nextType = type.nullable[0];
		auto expr = toD(nextType, document, settings);
		if (!isNativelyNullable(nextType, document, settings))
			expr = "_graphqld_typecons.Nullable!(" ~ expr ~ ")";
		return expr;
	} else if (type.name) {
		return settings.schemaRefExpr ~ "Schema." ~ type.name;
	} else {
		assert(false, "Uninitialized type");
	}
}

/// Convert an object type definition to a D struct.
private string toD(
	ref const ObjectTypeDefinition type,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	string s;
	s ~= "final static class " ~ type.name ~ (
		type.implementsInterfaces.length
			? " : " ~ type.implementsInterfaces.join(", ")
			: ""
	) ~ " {\n";

	bool needsCustomSerialization = false;
	foreach (ref field; type.fields) {
		auto dType = toD(field.type, document, settings);
		s ~= toDField(field.name, dType, settings);

		bool isCustomScalar = getScalarDefinition(getTypeName(field.type), settings) !is null;
		if (isCustomScalar) {
			needsCustomSerialization = true;
		}
	}

	s ~= "this(\n";
	foreach (ref field; type.fields) {
		auto dType = toD(field.type, document, settings);
		auto dName = toDIdentifier(field.name);
		s ~= "\t" ~ dType ~ " " ~ dName ~ " = " ~ dType ~ ".init,\n";
	}
	s ~= ") {\n";
	foreach  (ref field; type.fields) {
		auto dName = toDIdentifier(field.name);
		s ~= "\t" ~ "this." ~ dName ~ " = " ~ dName ~ ";\n";
	}
	s ~= "}\n";

	if (needsCustomSerialization) {
		if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
			if (type.implementsInterfaces.length) {
				s ~= "override _graphqld_vibe_data_json.Json toJson() const @trusted {\n";
			} else {
				s ~= "_graphqld_vibe_data_json.Json toJson() const @trusted {\n";
			}
			s ~= "auto json = _graphqld_vibe_data_json.Json.emptyObject;\n";
			foreach (ref field; type.fields) {
				s ~= "json[`" ~ field.name ~ "`] = _graphqld_vibe_data_json.serializeToJson(" ~
					transformScalar(field.type, GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
					"(this." ~ toDIdentifier(field.name) ~ ")" ~
					");\n";
			}
			s ~= "return json;\n";
			s ~= "}\n";
			s ~= "static typeof(this) fromJson()(_graphqld_vibe_data_json.Json json) @safe {\n";
			s ~= "auto instance = new typeof(this);\n";
			foreach (ref field; type.fields) {
				s ~= "instance." ~ toDIdentifier(field.name) ~ " = " ~
					transformScalar(field.type, GraphQLSettings.CustomScalar.Direction.deserialization, settings) ~ "(" ~
					"_graphqld_vibe_data_json.deserializeJson!(" ~ toDSerializableType(field.type, document, settings) ~ ")" ~
					"(json[`" ~ field.name ~ "`])" ~
					");\n";
			}
			s ~= "return instance;\n";
			s ~= "}\n";
		}
		if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
			if (type.implementsInterfaces.length) s ~= "override ";
			s ~= "_graphqld_ae_utils_json.JSONFragment toJSON() const {\n";
			s ~= "_graphqld_ae_utils_json.JSONFragment[string] json;\n";
			foreach (ref field; type.fields) {
				s ~= "json[`" ~ field.name ~ "`] = _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(" ~
					transformScalar(field.type, GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
					"(this." ~ toDIdentifier(field.name) ~ ")" ~
					"));\n";
			}
			s ~= "return _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(json));\n";
			s ~= "}\n";
		}
	} else if (type.implementsInterfaces.length) {
		// Implement interfaces' JSON shim.
		// Call serializeToJson to perform standard serialization of all fields.
		// By marking this method protected, we avoid infinite recursion.
		if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
			s ~= "protected override _graphqld_vibe_data_json.Json toJson() const { " ~
				"return _graphqld_vibe_data_json.serializeToJson(this); " ~
				"}\n";
		}
		if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
			s ~= "protected override _graphqld_ae_utils_json.JSONFragment toJSON() const { " ~
				"return _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(this)); " ~
				"}\n";
		}
	}

	s ~= "}\n\n";
	return s;
}

/// Convert an interface type definition to a D struct.
private string toD(
	ref const InterfaceTypeDefinition type,
	ref const CodeGenerationSettings settings,
) {
	string s;
	s ~= "static interface " ~ type.name ~ " {\n";
	// Do not emit the fields, just the interface, and JSON serialisation shim
	if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
		s ~= "_graphqld_vibe_data_json.Json toJson() const @safe;\n" ~
			"static typeof(this) fromJson(_graphqld_vibe_data_json.Json) @safe { " ~
			"assert(false, `Deserialization not supported`); " ~
			"}\n";
	}
	if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
		s ~= "_graphqld_ae_utils_json.JSONFragment toJSON() const;\n";
	}
	s ~= "}\n\n";
	return s;
}

/// Returns the GraphQL type name of the given type, ignoring arrays and nullability.
private string getTypeName(ref const Type type) {
	if (type.list) {
		return getTypeName(type.list[0]);
	} else if (type.nullable) {
		return getTypeName(type.nullable[0]);
	} else if (type.name) {
		return type.name;
	} else {
		assert(false, "Uninitialized type");
	}
}

/// Combine two callable expressions using function composition,
/// such that `compose(f, g)(x) == g(f(x))`.
private string compose(string fun1, string fun2) {
	return "((ref x) => " ~ fun2 ~ "(" ~ fun1 ~ "(x)))";
}

/// Returns a callable expression which converts a value of the given type to a
/// `vibe.data.json.Json` value.
/// Note that `vibe.data.json` can do this automatically as well - this method
/// simply avoids a lot of the template instantiation overhead, significantly
/// improving compilation times for large schemas.
private string toJson(
	ref const Type type,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	string wrap(ref const Type type) {
		if (type.list) {
			auto next = wrap(type.list[0]);
			return compose(
				"_graphqld_helpers.map!(" ~ next ~ ")",
				"_graphqld_vibe_data_json.Json",
			);
		} else if (type.nullable) {
			auto nextType = type.nullable[0];
			auto next = wrap(nextType);
			if (isNativelyNullable(nextType, document, settings))
				return "((ref x) => x is null ? _graphqld_vibe_data_json.Json(null) : " ~ next ~ "(x))";
			else
				return "((ref x) => x.isNull ? _graphqld_vibe_data_json.Json(null) : " ~ next ~ "(x.get))";
		} else if (type.name) {
			auto typeKind = getTypeKind(type.name, document, settings);
			final switch (typeKind) {
				case TypeKind.none:
					throw new Exception("Unknown type: " ~ type.name);
				case TypeKind.builtin:
				case TypeKind.enum_:
					return "_graphqld_vibe_data_json.serializeToJson";
				case TypeKind.object:
				case TypeKind.interface_:
				case TypeKind.input:
					return "((ref x) => x.toJson())";
				case TypeKind.scalar:
					return compose(
						transformScalar(type, GraphQLSettings.CustomScalar.Direction.serialization, settings),
						"_graphqld_vibe_data_json.serializeToJson"
					);
			}
		} else {
			assert(false);
		}
	}
	return wrap(type);
}

/// Emit an expression which transforms a value (D expression) to convert any
/// contained custom serials before/after serialization/deserialization.
private string transformScalar(
	ref const Type type,
	GraphQLSettings.CustomScalar.Direction direction,
	ref const CodeGenerationSettings settings,
) {
	auto scalarDefinition = getScalarDefinition(getTypeName(type), settings);

	if (!scalarDefinition) {
		return ""; // Will be followed by "(" ~ expression ~ ")"
	}

	string wrap(ref const Type type) {
		if (type.list) {
			auto next = wrap(type.list[0]);
			return "_graphqld_helpers.map!(" ~ next ~ ")";
		} else if (type.nullable) {
			auto next = wrap(type.nullable[0]);
			return "_graphqld_helpers.map!(" ~ next ~ ")";
		} else if (type.name) {
			auto scalarDefinition = getScalarDefinition(getTypeName(type), settings);
			return scalarDefinition.transformations[direction];
		} else {
			assert(false);
		}
	}
	return wrap(type);
}

/// Like above, but for types (and only in the serialization direction).
/// Like toD(Type), but translates custom scalar types.
private string toDSerializableType(
	ref const Type type,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	if (type.list) {
		return toDSerializableType(type.list[0], document, settings) ~ "[]";
	} else if (type.nullable) {
		auto nextType = type.nullable[0];
		auto expr = toDSerializableType(nextType, document, settings);
		if (!isNativelyNullable(nextType, document, settings))
			expr = "_graphqld_typecons.Nullable!(" ~ expr ~ ")";
		return expr;
	} else if (type.name) {
		if (auto scalarDefinition = getScalarDefinition(type.name, settings)) {
			return scalarDefinition.serializableType;
		} else {
			return settings.schemaRefExpr ~ "Schema." ~ type.name;
		}
	} else {
		assert(false, "Uninitialized type");
	}
}

/// Convert an input object type definition to a D struct.
private string toD(
	ref const InputObjectTypeDefinition type,
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	/*
	  Input objects are a little different from regular objects.
	  - One key aspect is that the presence or absence of a value is significant,
	    and a "null" value is distinct from an absent value.
	  - We also want to allow easy building of input objects
	    while allowing the client code to specify
	    only the keys it knows (or cares) about.
      - One must also be aware that input objects can recurse arbitrarily deep,
        unlike query return value types.
	*/

	string s;
	s ~= "final static class " ~ type.name ~ " {\n";
	enum fieldPrefix = "f_";
	foreach (ref value; type.values) {
		// If the input object field type is nullable, then we need two layers of Nullable:
		// one to represent the absence or presence of the field, and one to represent
		// whether the value itself is null or not.
		auto dType = toD(value.type, document, settings);
		auto fieldType = dType;
		if (value.type.nullable)
			fieldType = "_graphqld_typecons.Nullable!(" ~ fieldType ~ ")";
		s ~= "\t" ~ fieldType ~ " " ~ fieldPrefix ~ value.name ~ ";\n";

		// Generate getter for field access
		s ~= "ref " ~ toDIdentifier(value.name) ~ "() inout { return this." ~ fieldPrefix ~ value.name ~ "; }\n";

		// Generate setter for builder-like construction
		s ~= "typeof(this) " ~ toDIdentifier(value.name) ~ "(Value)(auto ref Value value) " ~
			"if (is(typeof(this." ~ fieldPrefix ~ value.name ~ " = value))) " ~
			"{ this." ~ fieldPrefix ~ value.name ~ " = value; return this; }\n";
	}
	s ~= "\n\n";

	if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
		// Note: we use @trusted instead of @safe to work around DMD recursive attribute inference bugs
		s ~= "_graphqld_vibe_data_json.Json toJson() const @trusted {\n";
		s ~= "auto json = _graphqld_vibe_data_json.Json.emptyObject;\n";
		foreach (ref value; type.values) {
			bool nullable = !!value.type.nullable;
			if (nullable)
				s ~= "if (!this." ~ fieldPrefix ~ value.name ~ ".isNull) ";

			string expr = "this." ~ fieldPrefix ~ value.name;
			if (nullable)
				expr ~= ".get";
			auto transformation = toJson(value.type, document, settings);

			s ~= "json[`" ~ value.name ~ "`] = " ~ transformation ~ "(" ~ expr ~ ");\n";
		}
		s ~= "return json;\n";
		s ~= "}\n";
		s ~= "static typeof(this) fromJson()(_graphqld_vibe_data_json.Json json) @safe {\n";
		s ~= "auto instance = new typeof(this);\n";
		foreach (ref value; type.values) {
			s ~= "if (`" ~ value.name ~ "` in json)" ~
				"instance." ~ fieldPrefix ~ value.name ~ " = " ~
				transformScalar(value.type, GraphQLSettings.CustomScalar.Direction.deserialization, settings) ~ "(" ~
				"_graphqld_vibe_data_json.deserializeJson!(" ~ toDSerializableType(value.type, document, settings) ~ ")" ~
				"(json[`" ~ value.name ~ "`])" ~
				");\n";
		}
		s ~= "return instance;\n";
		s ~= "}\n";
	}
	if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
		s ~= "_graphqld_ae_utils_json.JSONFragment toJSON() const {\n";
		s ~= "_graphqld_ae_utils_json.JSONFragment[string] json;\n";
		foreach (ref value; type.values) {
			bool nullable = !!value.type.nullable;
			if (nullable)
				s ~= "if (!this." ~ fieldPrefix ~ value.name ~ ".isNull) ";
			s ~= "json[`" ~ value.name ~ "`] = _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(" ~
				transformScalar(value.type, GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
				"(this." ~ fieldPrefix ~ value.name ~ (nullable ? ".get" : "") ~ ")" ~
				"));\n";
		}
		s ~= "return _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(json));\n";
		s ~= "}\n";
	}
	s ~= "}\n\n\n";
	return s;
}

/// Convert a schema document to D,
/// producing types and definitions used by query document parsing.
string toD(
	ref const SchemaDocument document,
	ref const CodeGenerationSettings settings,
) {
	string s;
	s ~= getImports(settings);

	s ~= "struct Schema {\n";

	// Add standard definitions
	s ~= q{
		alias Int = int;
		alias Float = double;
		alias String = string;
		alias Boolean = bool;

		alias ID = string;
	};

	foreach (ref type; document.scalarTypes) {
		auto scalarDefinition = getScalarDefinition(type.name, settings);
		auto dType = scalarDefinition ? scalarDefinition.dType : "string";
		s ~= "alias " ~ type.name ~ " = " ~ dType ~ ";\n";
	}

	foreach (ref type; document.enumTypes) {
		if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
			// Note: see https://github.com/vibe-d/vibe.d/issues/2820
			s ~= "@(_graphqld_vibe_data_json.byName) ";
		}

		s ~= "enum " ~ type.name ~ " {\n";
		foreach (ref value; type.values) {
			s ~= "\t" ~ value.name ~ ",\n";
		}
		s ~= "}\n";
	}

	foreach (type; document.inputTypes) {
		s ~= toD(type, document, settings);
	}

	// Generate types for schema object types as well.
	// These won't be used directly by most client code,
	// but can be used for some client/server interoperability scenarios.
	foreach (type; document.objectTypes) {
		s ~= toD(type, document, settings);
	}

	foreach (type; document.interfaceTypes) {
		s ~= toD(type, settings);
	}

	s ~= "}\n";
	return s;
}

/// Convert a selection set (subset of a type) to a D field list.
private string toD(
	const Field[] selections,
	/// The name of the type being selected.
	string typeName,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	ref const CodeGenerationSettings settings,
)
in(typeName !is null, "No typeName provided") {
	auto typeFields = {
		foreach (ref objectType; schema.objectTypes) {
			if (objectType.name == typeName) {
				return objectType.fields;
			}
		}
		assert(false, "Object type not found in schema: " ~ typeName);
	}();

	string s;

	s ~= "alias __SchemaType = " ~ settings.schemaRefExpr ~ "Schema." ~ typeName ~ ";\n";

	bool needsCustomSerialization = false;
	const(Type)*[string] types;

	foreach (ref field; selections) {
		switch (field.name) {
			case "__typename":
				s ~= toDField(field.name, q{string}, settings);
				continue;
			default:
		}

		auto type = {
			foreach (ref typeField; typeFields) {
				if (typeField.name == field.name) {
					return &typeField.type;
				}
			}
			assert(false, "Field not found in type: " ~ field.name);
		}();
		types[field.name] = type;

		string dType;
		if (field.selections) {
			// Generate a custom type with just the selection fields.
			// Be sure to keep any nullability / listness of the field type.
			const(Type)* baseType = type;
			string function(string)[] wrappers;
			while (true) {
				if (baseType.nullable) {
					baseType = baseType.nullable.ptr;
					wrappers ~= s => "_graphqld_typecons.Nullable!(" ~ s ~ ")";
				} else if (baseType.list) {
					baseType = baseType.list.ptr;
					wrappers ~= s => s ~ "[]";
				} else if (baseType.name) {
					break;
				} else {
					assert(false);
				}
			}

			auto selectionTypeName = "_" ~ field.name ~ "_Type";
			s ~= "\tstruct " ~ selectionTypeName ~ " {\n";
			s ~= toD(field.selections, baseType.name, schema, settings);
			s ~= "\t}\n";

			dType = selectionTypeName;
			foreach_reverse (wrapper; wrappers) {
				dType = wrapper(dType);
			}
		} else {
			dType = toD(*type, schema, settings);

			bool isCustomScalar = getScalarDefinition(getTypeName(*type), settings) !is null;
			if (isCustomScalar) {
				needsCustomSerialization = true;
			}
		}

		s ~= toDField(field.name, dType, settings);
	}

	if (needsCustomSerialization) {
		if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
			s ~= "_graphqld_vibe_data_json.Json toJson() const @trusted {\n";
			s ~= "auto json = _graphqld_vibe_data_json.Json.emptyObject;\n";
			foreach (ref field; selections) {
				s ~= "json[`" ~ field.name ~ "`] = _graphqld_vibe_data_json.serializeToJson(" ~
					transformScalar(*types[field.name], GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
					"(this." ~ toDIdentifier(field.name) ~ ")" ~
					");\n";
			}
			s ~= "return json;\n";
			s ~= "}\n";
			s ~= "static typeof(this) fromJson()(_graphqld_vibe_data_json.Json json) @safe {\n";
			s ~= "typeof(this) instance;\n";
			foreach (ref field; selections) {
				s ~= "instance." ~ toDIdentifier(field.name) ~ " = " ~
					transformScalar(*types[field.name], GraphQLSettings.CustomScalar.Direction.deserialization, settings) ~ "(" ~
					"_graphqld_vibe_data_json.deserializeJson!(" ~ toDSerializableType(*types[field.name], schema, settings) ~ ")" ~
					"(json[`" ~ field.name ~ "`])" ~
					");\n";
			}
			s ~= "return instance;\n";
			s ~= "}\n";
		}
		if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
			s ~= "_graphqld_ae_utils_json.JSONFragment toJSON() const {\n";
			s ~= "_graphqld_ae_utils_json.JSONFragment[string] json;\n";
			foreach (ref field; selections) {
				s ~= "json[`" ~ field.name ~ "`] = _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(" ~
					transformScalar(*types[field.name], GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
					"(this." ~ toDIdentifier(field.name) ~ ")" ~
					"));\n";
			}
			s ~= "return _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(json));\n";
			s ~= "}\n";
		}
	}

	return s;
}


/// Convert an operation's variables and return type to D.
private string toD(
	ref const OperationDefinition operation,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	ref const CodeGenerationSettings settings,
) {
	string s;
	s ~= "struct ReturnType {\n";

	string typeName = {
		foreach (ref operationType; schema.schema.operationTypes) {
			if (operationType.type == operation.type) {
				return operationType.name;
			}
		}
		assert(false, "Operation type not found in schema");
	}();

	s ~= toD(operation.selections, typeName, schema, settings);

	s ~= "}\n";

	bool needsCustomSerialization = false;
	s ~= "struct Variables {\n";
	foreach (ref variable; operation.variables) {
		s ~= "\t" ~ toD(variable.type, schema, settings) ~ " " ~ variable.name ~ ";\n";
		bool isCustomScalar = getScalarDefinition(getTypeName(variable.type), settings) !is null;
		if (isCustomScalar) {
			needsCustomSerialization = true;
		}
	}

	if (needsCustomSerialization) {
		if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
			s ~= "_graphqld_vibe_data_json.Json toJson() const @trusted {\n";
			s ~= "auto json = _graphqld_vibe_data_json.Json.emptyObject;\n";
			foreach (ref variable; operation.variables) {
				s ~= "json[`" ~ variable.name ~ "`] = _graphqld_vibe_data_json.serializeToJson(" ~
					transformScalar(variable.type, GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
					"(this." ~ toDIdentifier(variable.name) ~ ")" ~
					");\n";
			}
			s ~= "return json;\n";
			s ~= "}\n";
			s ~= "static typeof(this) fromJson(_graphqld_vibe_data_json.Json json) @safe {\n";
			s ~= "typeof(this) instance;\n";
			foreach (ref variable; operation.variables) {
				s ~= "instance." ~ toDIdentifier(variable.name) ~ " = " ~
					transformScalar(variable.type, GraphQLSettings.CustomScalar.Direction.deserialization, settings) ~ "(" ~
					"_graphqld_vibe_data_json.deserializeJson!(" ~ toDSerializableType(variable.type, schema, settings) ~ ")" ~
					"(json[`" ~ variable.name ~ "`])" ~
					");\n";
			}
			s ~= "return instance;\n";
			s ~= "}\n";
		}
		if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
			s ~= "_graphqld_ae_utils_json.JSONFragment toJSON() const {\n";
			s ~= "_graphqld_ae_utils_json.JSONFragment[string] json;\n";
			foreach (ref variable; operation.variables) {
				s ~= "json[`" ~ variable.name ~ "`] = _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(" ~
					transformScalar(variable.type, GraphQLSettings.CustomScalar.Direction.serialization, settings) ~
					"(this." ~ toDIdentifier(variable.name) ~ ")" ~
					"));\n";
			}
			s ~= "return _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(json));\n";
			s ~= "}\n";
		}
	}
	s ~= "}\n";

	s ~= "struct QueryInstance {\n";
	s ~= "alias Query = __traits(parent, typeof(this));\n";
	s ~= "Variables variables;\n";
	s ~= "}\n";

	s ~= "QueryInstance opCall(\n";
	foreach (variable; operation.variables) {
		s ~= "\t" ~ toD(variable.type, schema, settings) ~ " " ~ variable.name ~ ",\n";
	}
	s ~= ") const {";
	s ~= "QueryInstance _graphqld_instance;";
	foreach (variable; operation.variables) {
		s ~= "\t_graphqld_instance.variables." ~ variable.name ~ " = " ~ variable.name ~ ";\n";
	}
	s ~= "\treturn _graphqld_instance;";
	s ~= "}";

	return s;
}

/// Convert a query document's operations to D.
string toD(
	ref const QueryDocument query,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	ref const CodeGenerationSettings settings,
) {
	assert(query.operations.length != 0,
		"GraphQL query document must contain at least one operation");

	string s;
	s ~= getImports(settings);

	if (query.operations.length == 1 && query.operations[0].name is null) {
		// Single operation
		auto operation = query.operations[0];
		s ~= toD(operation, schema, settings);
	} else {
		assert(false,
			"GraphQL query documents with multiple operations are not supported yet");
	}

	return s;
}

private string getImports(ref const CodeGenerationSettings settings) {
	string s;
	s ~= "private import _graphqld_helpers = graphql.client.helpers;\n\n";
	s ~= "private import _graphqld_typecons = std.typecons;\n\n";

	if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
		s ~= "private import _graphqld_vibe_data_json = vibe.data.json;\n\n";
	}
	if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
		s ~= "private import _graphqld_ae_utils_json = ae.utils.json;\n\n";
	}

	return s;
}

/// Generate a D variable / field declaration,
/// taking care to ensure that the name is a valid D identifier.
private string toDField(
	string name,
	string dType,
	ref const CodeGenerationSettings settings,
) {
	string s;
	string dName = toDIdentifier(name);
	if (dName != name) {
		if (settings.graphqlSettings.serializationLibraries.vibe_data_json) {
			s ~= "\t@(_graphqld_vibe_data_json.name(`" ~ name ~ "`))\n";
		}
		if (settings.graphqlSettings.serializationLibraries.ae_utils_json) {
			s ~= "\t@(_graphqld_ae_utils_json.JSONName(`" ~ name ~ "`))\n";
		}
	}

	s ~= "\t" ~ dType ~ " " ~ dName ~ ";\n";
	return s;
}

private string toDIdentifier(string name) {
	foreach (keyword; keywords) {
		if (name == keyword) {
			return name ~ "_";
		}
	}
	return name;
}

/// https://dlang.org/spec/lex.html#keywords
private immutable string[] keywords = [
  "abstract",
  "alias",
  "align",
  "asm",
  "assert",
  "auto",

  "body",
  "bool",
  "break",
  "byte",

  "case",
  "cast",
  "catch",
  "cdouble",
  "cent",
  "cfloat",
  "char",
  "class",
  "const",
  "continue",
  "creal",

  "dchar",
  "debug",
  "default",
  "delegate",
  "delete",
  "deprecated",
  "do",
  "double",

  "else",
  "enum",
  "export",
  "extern",

  "false",
  "final",
  "finally",
  "float",
  "for",
  "foreach",
  "foreach_reverse",
  "function",

  "goto",

  "idouble",
  "if",
  "ifloat",
  "immutable",
  "import",
  "in",
  "inout",
  "int",
  "interface",
  "invariant",
  "ireal",
  "is",

  "lazy",
  "long",

  "macro",
  "mixin",
  "module",

  "new",
  "nothrow",
  "null",

  "out",
  "override",

  "package",
  "pragma",
  "private",
  "protected",
  "public",
  "pure",

  "real",
  "ref",
  "return",

  "scope",
  "shared",
  "short",
  "static",
  "struct",
  "super",
  "switch",
  "synchronized",

  "template",
  "this",
  "throw",
  "true",
  "try",
  "typeid",
  "typeof",

  "ubyte",
  "ucent",
  "uint",
  "ulong",
  "union",
  "unittest",
  "ushort",

  "version",
  "void",

  "wchar",
  "while",
  "with",

  "__FILE__",
  "__FILE_FULL_PATH__",
  "__FUNCTION__",
  "__LINE__",
  "__MODULE__",
  "__PRETTY_FUNCTION__",

  "__gshared",
  "__parameters",
  "__rvalue",
  "__traits",
  "__vector",
];

private template fullyQualifiedName(alias x) {
	enum identifier = __traits(identifier, x);
	static if (!__traits(compiles, __traits(parent, x))) {
		enum fullyQualifiedName = identifier;
	} else {
		enum fullyQualifiedName = fullyQualifiedName!(__traits(parent, x)) ~ "." ~ identifier;
	}
}

string toDLiteral(T)(ref const T value) {
	static if (is(T == enum)) {
		string s = fullyQualifiedName!T ~ ".";
		static foreach (member; __traits(allMembers, T)) {
			if (__traits(getMember, T, member) == value) {
				return s ~ member;
			}
		}
		throw new Exception("Enum member not found");
	} else static if (is(T == string)) {
		string s = `"`;
		foreach (c; value) {
			if (c == '"' || c == '\\') {
				s ~= '\\';
			}
			s ~= c;
		}
		return s ~ `"`;
	} else static if (is(T == bool)) {
		return value ? "true" : "false";
	} else static if (is(T == struct)) {
		string s = fullyQualifiedName!T ~ "(";
		foreach (ref const field; value.tupleof) {
			s ~= toDLiteral(field) ~ ",\n";
		}
		s ~= ")";
		return s;
	} else static if (is(T == U[], U)) {
		string s = "[\n";
		foreach (ref const item; value) {
			s ~= toDLiteral(item) ~ ",\n";
		}
		s ~= "]";
		return s;
	} else static if (is(T == U[n], U, size_t n)) {
		string s = "[\n";
		foreach (ref const item; value) {
			s ~= toDLiteral(item) ~ ",\n";
		}
		s ~= "]";
		return s;
	} else static if (is(T == V[K], K, V)) {
		if (value.length == 0) {
			return "null";
		}
		string s = "[\n";
		foreach (ref const k, ref const v; value) {
			s ~= toDLiteral(k) ~ ":" ~ toDLiteral(v) ~ ",\n";
		}
		s ~= "]";
		return s;
	} else {
		static assert(false, "Unsupported type for toDLiteral: " ~ T.stringof);
	}
}
