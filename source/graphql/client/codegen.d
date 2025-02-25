/// D code generation.
module graphql.client.codegen;

// This is an internal module.
package(graphql):

import graphql.client.document;

/// Controls the UDAs and JSON serialization in generated code.
struct SerializationLibraries
{
	bool vibe_data_json;  /// `vibe.data.json` support
	bool ae_utils_json;  /// `ae.utils.json` support
}

struct CodeGenerationSettings
{
	/// A prefix used to qualify referenced type definitions.
	string schemaRefExpr;

	/// Controls the UDAs and JSON serialization in generated code.
	SerializationLibraries serializationLibraries;
}

/// Convert a field type to D.
string toD(
	ref const Type type,
	ref const CodeGenerationSettings settings,
)
{
	if (type.list)
		return toD(type.list[0], settings) ~ "[]";
	else if (type.nullable)
		return "_graphqld_typecons.Nullable!(" ~ toD(type.nullable[0], settings) ~ ")";
	else if (type.name)
		return settings.schemaRefExpr ~ "Schema." ~ type.name;
	else
		assert(false, "Uninitialized type");
}

/// Convert an input object type definition to a D struct.
private string toD(
	ref const InputObjectTypeDefinition type,
	ref const CodeGenerationSettings settings,
)
{
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
	foreach (ref value; type.values)
	{
		auto dType = "_graphqld_typecons.Nullable!(" ~ toD(value.type, settings) ~ ")";
		s ~= toDField(value.name, dType, settings);
	}

	s ~= "\n\n";
	s ~= "this(Args...)(Args args) if (Args.length % 2 == 0) {\n";
	s ~= "static foreach (i; 0 .. args.length / 2) {{\n";
	s ~= "alias name = args[i * 2];\n";
	s ~= "alias value = args[i * 2 + 1];\n";
	foreach (ref value; type.values)
	{
		s ~=
			"if (name == `" ~ value.name ~ "`) {\n" ~
			"  static if (is(typeof({ this." ~ toDIdentifier(value.name) ~ " = value; })))\n" ~
			"    this." ~ toDIdentifier(value.name) ~ " = value;\n" ~
			"  else\n" ~
			"    assert(false, `Cannot convert ` ~ typeof(value).stringof ~ ` to ` ~ " ~
			"typeof(this." ~ toDIdentifier(value.name) ~ ".get()).stringof ~ ` for field ` ~ name);\n" ~
			"} else ";
	}
	s ~= "assert(false, `Unknown field name: ` ~ name);\n";
	s ~= "}}\n";
	s ~= "}\n\n";

	if (settings.serializationLibraries.vibe_data_json)
	{
		s ~= "_graphqld_vibe_data_json.Json toJson() const {\n";
		s ~= "auto json = _graphqld_vibe_data_json.Json.emptyObject;\n";
		foreach (ref value; type.values)
			s ~= "if (!this." ~ toDIdentifier(value.name) ~ ".isNull) " ~
				"json[`" ~ value.name ~ "`] = _graphqld_vibe_data_json.serializeToJson(this." ~ toDIdentifier(value.name) ~ ".get);\n";
		s ~= "return json;\n";
		s ~= "}\n";
		s ~= "static typeof(this) fromJson(_graphqld_vibe_data_json.Json) @safe { assert(false, `Deserialization not supported`); }\n";
	}
	if (settings.serializationLibraries.ae_utils_json)
	{
		s ~= "_graphqld_ae_utils_json.JSONFragment toJSON() const {\n";
		s ~= "_graphqld_ae_utils_json.JSONFragment[string] json;\n";
		foreach (ref value; type.values)
			s ~= "if (!this." ~ toDIdentifier(value.name) ~ ".isNull) " ~
				"json[`" ~ value.name ~ "`] = _graphqld_ae_utils_json.JSONFragment(_graphqld_ae_utils_json.toJson(this." ~ toDIdentifier(value.name) ~ ".get));\n";
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
)
{
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

	foreach (ref type; document.scalarTypes)
	{
		// TODO: allow customizing serialization / D type?
		s ~= "alias " ~ type.name ~ " = string;\n";
	}

	foreach (ref type; document.enumTypes)
	{
		s ~= "enum " ~ type.name ~ " {\n";
		foreach (ref value; type.values)
			s ~= "\t" ~ value.name ~ ",\n";
		s ~= "}\n";
	}

	foreach (type; document.inputTypes)
		s ~= toD(type, settings);

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
in(typeName !is null, "No typeName provided")
{
	auto typeFields = {
		foreach (ref objectType; schema.objectTypes)
			if (objectType.name == typeName)
				return objectType.fields;
		assert(false, "Object type not found in schema: " ~ typeName);
	}();

	string s;
	foreach (ref field; selections)
	{
		auto type = {
			foreach (ref typeField; typeFields)
				if (typeField.name == field.name)
					return &typeField.type;
			assert(false, "Field not found in type: " ~ field.name);
		}();

		string dType;
		if (field.selections)
		{
			// Generate a custom type with just the selection fields.
			// Be sure to keep any nullability / listness of the field type.
			const(Type)* baseType = type;
			string function(string)[] wrappers;
			while (true)
				if (baseType.nullable)
				{
					baseType = baseType.nullable.ptr;
					wrappers ~= s => "_graphqld_typecons.Nullable!(" ~ s ~ ")";
				}
				else if (baseType.list)
				{
					baseType = baseType.list.ptr;
					wrappers ~= s => s ~ "[]";
				}
				else if (baseType.name)
					break;
				else
					assert(false);

			auto selectionTypeName = "_" ~ field.name ~ "_Type";
			s ~= "\tstruct " ~ selectionTypeName ~ " {\n";
			s ~= toD(field.selections, baseType.name, schema, settings);
			s ~= "\t}\n";

			dType = selectionTypeName;
			foreach_reverse (wrapper; wrappers)
				dType = wrapper(dType);
		}
		else
			dType = toD(*type, settings);

		s ~= toDField(field.name, dType, settings);
	}
	return s;
}


/// Convert an operation's variables and return type to D.
private string toD(
	ref const OperationDefinition operation,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	ref const CodeGenerationSettings settings,
)
{
	string s;
	s ~= "struct ReturnType {\n";

	string typeName = {
		foreach (ref operationType; schema.schema.operationTypes)
			if (operationType.type == operation.type)
				return operationType.name;
		assert(false, "Operation type not found in schema");
	}();

	s ~= toD(operation.selections, typeName, schema, settings);

	s ~= "}\n";

	s ~= "struct Variables {\n";
	foreach (variable; operation.variables)
		s ~= "\t" ~ toD(variable.type, settings) ~ " " ~ variable.name ~ ";\n";
	s ~= "}\n";

	return s;
}

/// Convert a query document's operations to D.
string toD(
	ref const QueryDocument query,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	ref const CodeGenerationSettings settings,
)
{
	assert(query.operations.length != 0,
		"GraphQL query document must contain at least one operation");

	string s;
	s ~= getImports(settings);

	if (query.operations.length == 1 && query.operations[0].name is null)
	{
		// Single operation
		auto operation = query.operations[0];
		s ~= toD(operation, schema, settings);
	}
	else
	{
		assert(false,
			"GraphQL query documents with multiple operations are not supported yet");
	}

	return s;
}

private string getImports(CodeGenerationSettings settings)
{
	string s;
	s ~= "private import _graphqld_typecons = std.typecons;\n\n";

	if (settings.serializationLibraries.vibe_data_json)
		s ~= "private import _graphqld_vibe_data_json = vibe.data.json;\n\n";
	if (settings.serializationLibraries.ae_utils_json)
		s ~= "private import _graphqld_ae_utils_json = ae.utils.json;\n\n";

	return s;
}

/// Generate a D variable / field declaration,
/// taking care to ensure that the name is a valid D identifier.
private string toDField(
	string name,
	string dType,
	ref const CodeGenerationSettings settings,
)
{
	string s;
	string dName = toDIdentifier(name);
	if (dName != name)
	{
		if (settings.serializationLibraries.vibe_data_json)
			s ~= "\t@(_graphqld_vibe_data_json.name(`" ~ name ~ "`))\n";
		if (settings.serializationLibraries.ae_utils_json)
			s ~= "\t@(_graphqld_ae_utils_json.JSONName(`" ~ name ~ "`))\n";
	}

	s ~= "\t" ~ dType ~ " " ~ dName ~ ";\n";
	return s;
}

private string toDIdentifier(string name)
{
	foreach (keyword; keywords)
		if (name == keyword)
			return name ~ "_";
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
