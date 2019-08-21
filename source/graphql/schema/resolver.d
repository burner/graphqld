module graphql.schema.resolver;

import std.array : empty;
import std.format : format;
import std.meta;
import std.traits;
import std.typecons : Nullable;
import std.experimental.logger;
import std.stdio;
import std.string : capitalize;

import vibe.data.json;

import graphql.schema.types;
import graphql.schema.typeconversions;
import graphql.helper;
import graphql.traits;
import graphql.constants;
import graphql.graphql;

@safe:

alias QueryResolver(Con) = Json delegate(string name, Json parent,
		Json args, ref Con context) @safe;

QueryResolver!(Con) buildSchemaResolver(Type, Con)() {
	return ret;
}

QueryResolver!(Con) buildTypeResolver(Type, Con)() {
	return ret;
}

GQLDSchema!(Type) toSchema(Type)() {
	typeof(return) ret = new GQLDSchema!Type();

	static foreach(qms; ["queryType", "mutationType", "subscriptionType"]) {{
		GQLDMap cur = new GQLDMap();
		cur.name = qms;
		ret.member[qms] = cur;
		if(qms == "queryType") {
			cur.member["__schema"] = ret.__schema;
			cur.member["__type"] = ret.__nonNullType;
		}
		static if(__traits(hasMember, Type, qms)) {
			alias QMSType = typeof(__traits(getMember, Type, qms));
			static foreach(mem; __traits(allMembers, QMSType)) {{
				alias MemType = typeof(__traits(getMember, QMSType, mem));
				static if(isCallable!(MemType)) {{
					GQLDOperation op = qms == "queryType"
						? new GQLDQuery()
						: qms == "mutationType" ? new GQLDMutation()
						: qms == "subscriptionType" ? new GQLDSubscription()
						: null;
					cur.member[mem] = op;
					assert(op !is null);
					op.returnType = typeToGQLDType!(ReturnType!(MemType))(
							ret
						);

					alias paraNames = ParameterIdentifierTuple!(
							__traits(getMember, QMSType, mem)
						);
					alias paraTypes = Parameters!(
							__traits(getMember, QMSType, mem)
						);
					static foreach(idx; 0 .. paraNames.length) {
						op.parameters[paraNames[idx]] =
							typeToGQLDType!(paraTypes[idx])(ret);
					}
				}}
			}}
		}
	}}
	return ret;
}

private immutable typeStr = `
{
	"kind" : "OBJECT",
	"name" : "__Type",
	"interfaces" : null,
	"fields" : ["kind", "name", "description", "fields", "interfaces",
		"possibleTypes", "enumValues", "inputFields", "ofType"]
}
`;

private immutable typeKindStr = `
{
	"kind": "ENUM",
	"name": "__TypeKind",
	"enumValues" : [ "SCALAR", "OBJECT", "INTERFACE", "UNION", "ENUM",
		"INPUT_OBJECT", "LIST", "NON_NULL" ],
	"fields" : null
}
`;

private immutable fieldStr = `
{
	"kind": "OBJECT",
	"name": "__Field",
	"interfaces" : null,
	"fields" : ["name", "description", "args", "type", "isDeprecated",
		"deprecationReason"]
}
`;

private immutable inputValueStr = `
{
	"kind": "OBJECT",
	"name": "__InputValue",
	"interfaces" : null,
	"fields" : ["name", "description", "type", "defaultValue"]
}
`;

private immutable enumValueStr = `
{
	"kind": "OBJECT",
	"name": "__EnumValue",
	"interfaces" : null,
	"fields" : ["name", "description", "isDeprecated", "deprecationReason"]
}
`;

private immutable directiveStr = `
{
	"kind": "OBJECT",
	"name": "__Directive",
	"interfaces" : null,
	"fields" : ["name", "description", "locations", "args"]
}
`;

private immutable directiveLocationStr = `
{
	"kind": "ENUM",
	"name": "__DirectiveLocation",
	"interfaces" : null,
	"fields" : null
}
`;

void setDefaultSchemaResolver(T, Con)(GraphQLD!(T,Con) graphql) {
	auto typeJS = parseJsonString(typeStr);
	auto typeKindJS = parseJsonString(typeKindStr);
	auto fieldJS = parseJsonString(fieldStr);
	auto enumValueJS = parseJsonString(enumValueStr);
	auto inputValueJS = parseJsonString(inputValueStr);
	auto directiveJS = parseJsonString(directiveStr);
	auto directiveLocationJS = parseJsonString(directiveLocationStr);

	auto typeResolver = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			graphql.defaultResolverLog.logf("%s %s %s", name, args, parent);
			Json ret = //returnTemplate();
				Json.emptyObject();
			string typeName;
			if(Constants.name in args) {
				typeName = args[Constants.name].get!string();
			}
			if(Constants.typenameOrig in parent) {
				typeName = parent[Constants.typenameOrig].get!string();
			} else if(Constants.name in parent) {
				typeName = parent[Constants.name].get!string();
			}
			string typeCap;
			string old;
			StringTypeStrip stripType;
			if(typeName.empty) {
				ret.insertError("unknown type");
				goto retLabel;
			} else {
				typeCap = typeName;
				old = typeName;
			}
			stripType = typeCap.stringTypeStrip();
			//writeln("args ", args.toPrettyString());
			//writeln("pare ", parent.toPrettyString());
			//writeln(__LINE__, " ", stripType);
			//writeln("ST ", stripType);
			pragma(msg, staticMap!typeToTypeName, collectTypes!(T));
			static foreach(type; collectTypes!(T)) {{
				enum typeConst = typeToTypeName!(type);
				writefln("%s %s == %s", __LINE__, stripType.str, typeConst);
				if(stripType.str == typeConst) {
					const bool inner = stripType.innerNotNull;
					const bool outer = stripType.outerNotNull;
					const bool arr = stripType.arr;

					writefln("inner %s, outer %s, arr %s, old %s, new %s",
							inner, outer, arr, stripType.input, stripType.str);

					if(inner && outer && arr) {
						writeln(__LINE__, " ", stripType);
						alias PassType = type[];
						ret["data"] = typeToJson!(PassType,T)();
					} else if(!inner && outer && arr) {
						writeln(__LINE__, " ", stripType);
						alias PassType = Nullable!(type)[];
						ret["data"] = typeToJson!(PassType,T)();
					} else if(inner && !outer && arr) {
						writeln(__LINE__, " ", stripType);
						alias PassType = Nullable!(type[]);
						ret["data"] = typeToJson!(PassType,T)();
					} else if(!inner && !outer && arr) {
						writeln(__LINE__, " ", stripType);
						alias PassType = Nullable!(Nullable!(type)[]);
						ret["data"] = typeToJson!(PassType,T)();
					} else if(!inner && !arr) {
						writeln(__LINE__, " ", stripType);
						alias PassType = Nullable!(type);
						ret["data"] = typeToJson!(PassType,T)();
					} else if(inner && !arr) {
						writeln(__LINE__, " ", stripType);
						alias PassType = type;
						ret["data"] = typeToJson!(PassType,T)();
					} else {
						assert(false, format("%s", stripType));
					}
					writeln(ret["data"].toPrettyString());
					graphql.defaultResolverLog.logf("%s %s %s", stripType.str,
							typeConst, ret["data"]
						);
					goto retLabel;
				} else {
					graphql.defaultResolverLog.logf("||||||||||| %s %s",
							stripType.str, typeConst
						);
				}
			}}
			retLabel:
			graphql.defaultResolverLog.logf("%s", ret.toPrettyString());
			return ret;
		};

	QueryResolver!(Con) schemaResolver = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			//logf("%s %s %s", name, args, parent);
			Json ret = Json.emptyObject();
			ret["data"] = Json.emptyObject();
			ret["data"]["types"] = Json.emptyArray();
			ret["data"]["types"] ~= typeJS;
			ret["data"]["types"] ~= typeKindJS;
			ret["data"]["types"] ~= fieldJS;
			ret["data"]["types"] ~= inputValueJS;
			ret["data"]["types"] ~= enumValueJS;
			ret["data"]["types"] ~= directiveJS;
			ret["data"]["types"] ~= directiveLocationJS;

			alias AllTypes = collectTypes!(T);
			alias NoListOrArray = staticMap!(stripArrayAndNullable, AllTypes);
			alias FixUp = staticMap!(fixupBasicTypes, NoListOrArray);
			static if(hasMember!(T, Constants.directives)) {
				alias NoDirectives = EraseAll!(
						typeof(__traits(getMember, T, Constants.directives)),
						FixUp
					);
			} else {
				alias NoDirectives = FixUp;
			}
			alias NoDup = NoDuplicates!(EraseAll!(T, NoDirectives));
			static foreach(type; NoDup) {{
				Json tmp = typeToJsonImpl!(type,T,type)();
				ret["data"]["types"] ~= tmp;
			}}
			static if(hasMember!(T, Constants.directives)) {
				ret["data"][Constants.directives] =
					directivesToJson!(typeof(
							__traits(getMember, T, Constants.directives)
						));
			}

			static foreach(tName; ["subscriptionType",
					"queryType", "mutationType"])
			{
				static if(hasMember!(T, tName)) {
					ret["data"][tName] =
						typeToJsonImpl!(typeof(__traits(getMember, T, tName)),
								T, typeof(__traits(getMember, T, tName)));
				}
			}
			graphql.defaultResolverLog.logf("%s", ret.toPrettyString());
			return ret;
		};

	graphql.setResolver("queryType", "__type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("%s %s %s", name, parent, args);
				Json tr = typeResolver(name, parent, args, context);
				Json ret = Json.emptyObject();
				//ret["data"] = tr["data"]["ofType"];
				ret["data"] = tr["data"];
				writefln("%s %s", __LINE__, tr.toPrettyString());
				graphql.defaultResolverLog.logf("%s %s", tr.toPrettyString(),
						ret.toPrettyString());
				return ret;
			}
		);

	graphql.setResolver("queryType", "__schema", schemaResolver);

	graphql.setResolver("__Field", "type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				import std.string : capitalize;
				Json ret = typeResolver(name, parent, args, context);
				graphql.defaultResolverLog.logf("FIELDDDDD TYPPPPPE %s",
						ret.toPrettyString()
					);
				writefln("%s %s\n%s", __LINE__, parent.toPrettyString(),
						ret.toPrettyString());
				return ret;
			}
		);

	graphql.setResolver("__InputValue", "type",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				writeln("\n\nPar ", parent.toPrettyString());
				graphql.defaultResolverLog.logf("%s %s %s", name, parent, args);
				Json tr = typeResolver(name, parent, args, context);
				Json ret = Json.emptyObject();
				Json d = tr["data"];
				//writeln("InputValue ", tr.toPrettyString());
				//writeln("ret ", ret["data"].type == Json.Type.object);
				//writeln("d ", d["ofType"].type == Json.Type.object);
				ret["data"] = d["ofType"];
				graphql.defaultResolverLog.logf("%s %s", tr.toPrettyString(),
						ret.toPrettyString()
					);
				return ret;
			}
		);

	graphql.setResolver("__Type", "ofType",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				Json ofType;
				if(parent.hasPathTo("ofType", ofType)) {
					ret["data"] = ofType;
				} else {
					ret["data"] = Json(null);
				}
				graphql.defaultResolverLog.logf("%s", ret);
				return ret;
			}
		);

	graphql.setResolver("__Type", "interfaces",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				ret["data"] = Json.emptyObject();
				if("kind" in parent
						&& parent["kind"].get!string() == "OBJECT")
				{
					ret["data"] = Json.emptyArray();
				}
				if("interfacesNames" !in parent) {
					return ret;
				}
				Json interNames = parent["interfacesNames"];
				if(interNames.type == Json.Type.array) {
					if(interNames.length > 0) {
						assert(ret["data"].type == Json.Type.array,
								format("%s", parent.toPrettyString())
							);
						ret["data"] = Json.emptyArray();
						foreach(Json it; interNames.byValue()) {
							string typeName = it.get!string();
							string typeCap = capitalize(typeName);
							l: switch(typeCap) {
								static foreach(type; collectTypes!(T)) {{
									case typeToTypeName!(type): {
									//if(typeCap == typeToTypeName!(type)) {
										alias striped =
											stripArrayAndNullable!type;
										graphql.defaultResolverLog.logf("%s %s",
												typeCap, striped.stringof
											);
										ret["data"] ~=
											typeToJsonImpl!(striped,T,type)();
										break l;
									}
								}}
								default: break;
							}
						}
					}
				}
				graphql.defaultResolverLog.logf("__Type.interfaces result %s",
						ret
					);
				return ret;
			}
		);

	graphql.setResolver("__Type", "possibleTypes",
			delegate(string name, Json parent, Json args, ref Con context) @safe
			{
				graphql.defaultResolverLog.logf("name %s, parent %s, args %s",
						name, parent, args
					);
				Json ret = Json.emptyObject();
				if("possibleTypesNames" !in parent) {
					ret["data"] = Json(null);
					return ret;
				}
				Json pTypesNames = parent["possibleTypesNames"];
				if(pTypesNames.type == Json.Type.array) {
					graphql.defaultResolverLog.log();
					ret["data"] = Json.emptyArray();
					foreach(Json it; pTypesNames.byValue()) {
						string typeName = it.get!string();
						string typeCap = capitalize(typeName);
						l: switch(typeCap) {
							static foreach(type; collectTypes!(T)) {
								//if(typeCap == typeToTypeName!(type)) {
								case typeToTypeName!(type): {
									alias striped = stripArrayAndNullable!type;
									graphql.defaultResolverLog.logf("%s %s",
											typeCap, striped.stringof
										);
									ret["data"] ~=
										typeToJsonImpl!(striped,T,type)();
									break l;
								}
							}
							default: {
								break;
							}
						}
					}
				} else {
					graphql.defaultResolverLog.log();
					ret["data"] = Json(null);
				}
				return ret;
			}
		);
}
