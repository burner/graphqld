module schema.resolver;

import std.array : empty;
import std.format : format;
import std.meta;
import std.traits;
import std.typecons : Nullable;
import std.experimental.logger;

import vibe.data.json;

import schema.types;
import schema.typeconversions;
import helper;
import traits;
import constants;

alias QueryResolver(Con) = Json delegate(string name, Json parent,
		Json args, ref Con context) @safe;

QueryResolver!(Con) buildSchemaResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			//logf("%s %s %s", name, args, parent);
			Json ret = returnTemplate();
			ret["data"]["types"] = Json.emptyArray();
			pragma(msg, collectTypes!(Type));
			alias AllTypes = collectTypes!(Type);
			alias NoListOrArray = staticMap!(stripArrayAndNullable, AllTypes);
			alias FixUp = staticMap!(fixupBasicTypes, NoListOrArray);
			static if(hasMember!(Type, Constants.directives)) {
				alias NoDirectives = EraseAll!(
						typeof(__traits(getMember, Type, Constants.directives)),
						FixUp
					);
			} else {
				alias NoDirectives = FixUp;
			}
			alias NoDup = NoDuplicates!(EraseAll!(Type, NoDirectives));
			static foreach(type; NoDup) {{
				Json tmp = typeToJsonImpl!(type,Type)();
				ret["data"]["types"] ~= tmp;
			}}
			static if(hasMember!(Type, Constants.directives)) {
				ret["data"][Constants.directives] =
					directivesToJson!(typeof(
							__traits(getMember, Type, Constants.directives)
						));
			}

			static foreach(tName; ["subscriptionType",
					"queryType", "mutationType"])
			{
				static if(hasMember!(Type, tName)) {
					ret["data"][tName] =
						typeToJsonImpl!(typeof(
								__traits(getMember, Type, tName)
							),Type);
				}
			}
			logf("%s", ret.toPrettyString());
			return ret;
		};
	return ret;
}

QueryResolver!(Con) buildTypeResolver(Type, Con)() {
	QueryResolver!(Con) ret = delegate(string name, Json parent,
			Json args, ref Con context) @safe
		{
			logf("%s %s %s", name, args, parent);
			Json ret = returnTemplate();
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
			if(typeName.empty) {
				ret["error"] ~= Json(format("unknown type"));
				goto retLabel;
			} else {
				//typeCap = firstCharUpperCase(typeName);
				typeCap = typeName;
			}
			pragma(msg, "collectTypes ", collectTypes!(Type));
			static foreach(type; collectTypes!(Type)) {{
				enum typeConst = typeToTypeName!(type);
				if(typeCap == typeConst) {
					ret["data"] = typeToJson!(type,Type)();
					logf("%s %s %s", typeCap, typeConst, ret["data"]);
					goto retLabel;
				} else {
					logf("||||||||||| %s %s", typeCap, typeConst);
				}
			}}
			retLabel:
			logf("%s", ret.toPrettyString());
			return ret;
		};
	return ret;
}

GQLDSchema!(Type) toSchema2(Type)() {
	typeof(return) ret = new typeof(return)();

	pragma(msg, __traits(allMembers, Type));
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
