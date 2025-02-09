/// D code generation.
module graphql.client.codegen;

// This is an internal module.
package(graphql):

import graphql.client.document;

/// Convert a field type to D.
string toD(
	ref const Type type,
	/// A prefix used to qualify referenced type definitions.
	string schemaRefExpr,
)
{
	if (type.list)
		return toD(type.list[0], schemaRefExpr) ~ "[]";
	else if (type.nullable)
		return "Nullable!(" ~ toD(type.nullable[0], schemaRefExpr) ~ ")";
	else if (type.name)
		return schemaRefExpr ~ "Schema." ~ type.name;
	else
		assert(false, "Uninitialized type");
}

// /// Convert an object type definition to a D struct.
// private string toD(ref const ObjectTypeDefinition type)
// {
// 	string s;
// 	s ~= "struct " ~ type.name ~ " {\n";
// 	foreach (field; type.fields)
// 		s ~= "\t" ~ toD(field.type, "") ~ " " ~ field.name ~ ";\n";
// 	s ~= "}\n";
// 	return s;
// }

/// Convert a schema document to D,
/// producing types and definitions used by query document parsing.
string toD(ref const SchemaDocument document)
{
	string s;
	s ~= "struct Schema {\n";

	// Add standard definitions
	s ~= q{
		alias Int = int;
		alias Float = double;
		alias String = string;
		alias Boolean = bool;

		alias ID = string;
	};

	// foreach (type; document.objectTypes)
	// 	s ~= toD(type);

	foreach (ref type; document.scalarTypes)
	{
		// TODO: allow customizing serialization / D type?
		s ~= "alias " ~ type.name ~ " = string;\n";
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
	/// A prefix used to qualify referenced type definitions.
	string schemaRefExpr,
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
					wrappers ~= s => "Nullable!(" ~ s ~ ")";
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
			s ~= toD(field.selections, baseType.name, schema, schemaRefExpr);
			s ~= "\t}\n";

			string dType = selectionTypeName;
			foreach_reverse (wrapper; wrappers)
				dType = wrapper(dType);
			s ~= "\t" ~ dType ~ " " ~ field.name ~ ";\n";
		}
		else
			s ~= "\t" ~ toD(*type, schemaRefExpr) ~ " " ~ field.name ~ ";\n";
	}
	return s;
}


/// Convert an operation's variables and return type to D.
private string toD(
	ref const OperationDefinition operation,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	/// A prefix used to qualify referenced type definitions.
	string schemaRefExpr,
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

	s ~= toD(
		operation.selections,
		typeName,
		schema,
		schemaRefExpr,
	);

	s ~= "}\n";

	s ~= "struct Variables {\n";
	foreach (variable; operation.variables)
		s ~= "\t" ~ toD(variable.type, schemaRefExpr) ~ " " ~ variable.name ~ ";\n";
	s ~= "}\n";

	return s;
}

/// Convert a query document's operations to D.
string toD(
	ref const QueryDocument query,
	/// The schema document (used to resolve types).
	ref const SchemaDocument schema,
	/// A prefix used to qualify referenced type definitions.
	string schemaRefExpr,
)
{
	assert(query.operations.length != 0,
		"GraphQL query document must contain at least one operation");

	string s = "private import std.typecons : Nullable;\n\n";

	if (query.operations.length == 1 && query.operations[0].name is null)
	{
		// Single operation
		auto operation = query.operations[0];
		s ~= toD(operation, schema, schemaRefExpr);
	}
	else
	{
		assert(false,
			"GraphQL query documents with multiple operations are not supported yet");
	}

	return s;
}
