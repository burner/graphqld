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
			static foreach(type; collectTypes!(Type)) {{
				Json tmp = typeToJson!type();
				ret["data"]["types"] ~= tmp;
			}}
			ret["data"]["directives"] = Json.emptyArray();
			ret["data"]["queryType"] = typeToJson!(typeof(
					__traits(getMember, Type, "query")))();
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
			if("name" in args) {
				typeName = args["name"].get!string();
			}
			if("typenameOrig" in parent) {
				typeName = parent["typenameOrig"].get!string();
			} else if("name" in parent) {
				typeName = parent["name"].get!string();
			}
			string typeCap;
			if(typeName.empty) {
				ret["error"] ~= Json(format("unknown type"));
				goto retLabel;
			} else {
				typeCap = firstCharUpperCase(typeName);
			}
			pragma(msg, "collectTypes ", collectTypes!(Type));
			static foreach(type; collectTypes!(Type)) {{
				enum typeConst = typeToTypeName!(type);
				if(typeCap == typeConst) {
					ret["data"] = typeToJson!type();
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

GQLDSchema!(Type, Con) toSchema2(Type, Con)() {
	typeof(return) ret = new typeof(return)();

	pragma(msg, __traits(allMembers, Type));
	static foreach(qms; ["query", "mutation", "subscription"]) {{
		GQLDMap!(Con) cur = new GQLDMap!Con();
		cur.name = qms;
		ret.member[qms] = cur;
		if(qms == "query") {
			cur.member["__schema"] = ret.__schema;
			cur.member["__type"] = ret.__nonNullType;
		}
		static if(__traits(hasMember, Type, qms)) {
			alias QMSType = typeof(__traits(getMember, Type, qms));
			static foreach(mem; __traits(allMembers, QMSType)) {{
				alias MemType = typeof(__traits(getMember, QMSType, mem));
				static if(isCallable!(MemType)) {{
					GQLDOperation!(Con) op = qms == "query"
						? new GQLDQuery!Con()
						: qms == "mutation" ? new GQLDMutation!Con()
						: qms == "subscription" ? new GQLDSubscription!Con()
						: null;
					cur.member[mem] = op;
					assert(op !is null);
					op.returnType = typeToGQLDType!(ReturnType!(MemType), Con)(
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
							typeToGQLDType!(paraTypes[idx], Con)(ret);
					}
				}}
			}}
		}
	}}
	return ret;
}
