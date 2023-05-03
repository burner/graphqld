module graphql.schema.types;

import std.conv : to;
import std.array;
import std.meta;
import std.traits;
import std.typecons;
import std.algorithm.iteration : map, joiner;
import std.algorithm.searching : canFind;
import std.container : RedBlackTree;
import std.range : ElementEncodingType;
import std.format;
import std.string : strip;
import std.stdio;

import vibe.data.json;

import nullablestore;

import graphql.helper;
import graphql.traits;
import graphql.constants;
import graphql.uda;

@safe:

enum GQLDKind {
	SimpleScalar,
	String,
	Float,
	Int,
	Bool,
	CustomLeaf,
	Object_,
	List,
	Enum,
	Map,
	Nullable,
	NonNull,
	Union,
	Query,
	Mutation,
	Subscription,
	Schema
}

abstract class GQLDType {
	const GQLDKind kind;
	GQLDDeprecatedData deprecatedInfo;
	string name;
	string description;
	GQLDUdaData udaData;
	TypeKind typeKind;

	this(GQLDKind kind) {
		this.kind = kind;
	}

	override string toString() const {
		return "GQLDType";
	}

	string toShortString() const {
		return this.toString();
	}
}

class GQLDScalar : GQLDType {
	this(GQLDKind kind = GQLDKind.SimpleScalar) {
		super(kind);
	}
}

class GQLDLeaf : GQLDScalar {
	this(string name) {
		super(GQLDKind.CustomLeaf);
		super.name = name;
	}

	override string toString() const {
		return format("GQLDCustomLeaf(%s)", this.name);
	}
}

class GQLDString : GQLDScalar {
	this() {
		super(GQLDKind.String);
		super.name = "String";
	}

	override string toString() const {
		return "String";
	}
}

class GQLDFloat : GQLDScalar {
	this() {
		super(GQLDKind.Float);
		super.name = "Float";
	}

	override string toString() const {
		return "Float";
	}
}

class GQLDInt : GQLDScalar {
	this() {
		super(GQLDKind.Int);
		super.name = "Int";
	}

	override string toString() const {
		return "Int";
	}
}

class GQLDEnum : GQLDScalar {
	string enumName;
	string[] memberNames;
	// should this also grab the values, for integration with something like
	// https://www.apollographql.com/docs/apollo-server/schema/scalars-enums/#internal-values ?
	this(string enumName, string[] memberNames = []) {
		super(GQLDKind.Enum);
		this.enumName = enumName;
		this.memberNames = memberNames;
		super.name = enumName;
	}

	override string toString() const {
		return this.enumName;
	}
}

class GQLDBool : GQLDScalar {
	this() {
		super(GQLDKind.Bool);
		super.name = "Boolean";
	}

	override string toString() const {
		return "Boolean";
	}
}

class GQLDMap : GQLDType {
	GQLDType[string] member;
	RedBlackTree!string outputOnlyMembers;
	GQLDMap[] derivatives;

	this() {
		this(GQLDKind.Map);
	}
	this(GQLDKind kind) {
		super(kind);
		this.outputOnlyMembers = new RedBlackTree!string();
	}

	void addDerivative(GQLDMap d) {
		if(!canFind!((a,b) => a is b)(this.derivatives, d)) {
			this.derivatives ~= d;
		}
	}

	override string toString() const {
		auto app = appender!string();
		foreach(key, value; this.member) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}
		return app.data;
	}
}

class GQLDObject : GQLDMap {
	GQLDObject base;
	TypeKind typeKind;

	this(string name) {
		super(GQLDKind.Object_);
		super.name = name;
	}

	this(string name, TypeKind tk) {
		this(name);
		this.typeKind = tk;
	}

	override string toString() const {
		return format(
				"Object %s(%s))\n\t\t\t\tBase(%s)\n\t\t\t\tDerivaties(%s)",
				this.name,
				this.member
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t"),
				(this.base !is null ? this.base.toShortString() : "null"),
				this.derivatives.map!(d => d.toShortString())
			);
	}

	override string toShortString() const {
		return format("%s", super.name);
	}
}

class GQLDUnion : GQLDMap {
	this(string name) {
		super(GQLDKind.Union);
		super.name = name;
	}

	override string toString() const {
		return format("Union %s(%s))\n\t\t\t\tDerivaties(%s)",
				this.name,
				this.member
					.byKeyValue
					.map!(kv => format("%s %s", kv.key,
							kv.value.toShortString()))
					.joiner(",\n\t\t\t\t"),
				this.derivatives.map!(d => d.toShortString())
			);
	}
}

class GQLDList : GQLDType {
	GQLDType elementType;

	this(GQLDType elemType) {
		super(GQLDKind.List);
		super.name = "List";
		this.elementType = elemType;
	}

	override string toString() const {
		return format("List(%s)", this.elementType.toShortString());
	}

	override string toShortString() const {
		return format("List(%s)", this.elementType.toShortString());
	}
}

class GQLDNonNull : GQLDType {
	GQLDType elementType;

	this(GQLDType elemType) {
		super(GQLDKind.NonNull);
		super.name = "NonNull";
		this.elementType = elemType;
	}

	override string toString() const {
		return format("NonNull(%s)", this.elementType.toShortString());
	}

	override string toShortString() const {
		return format("NonNull(%s)", this.elementType.toShortString());
	}
}

class GQLDNullable : GQLDType {
	GQLDType elementType;

	this(GQLDType elemType) {
		super(GQLDKind.Nullable);
		super.name = "Nullable";
		this.elementType = elemType;
	}

	override string toString() const {
		return format("Nullable(%s)", this.elementType.toShortString());
	}

	override string toShortString() const {
		return format("Nullable(%s)", this.elementType.toShortString());
	}
}

class GQLDOperation : GQLDType {
	GQLDType returnType;
	string returnTypeName;

	GQLDType[string] parameters;

	this(GQLDKind kind) {
		super(kind);
	}

	override string toString() const {
		return format("%s %s(%s)", super.kind, returnType.toShortString(),
				this.parameters
					.byKeyValue
					.map!(kv =>
						format("%s %s", kv.key, kv.value.toShortString())
					)
					.joiner(", ")
				);
	}
}

class GQLDQuery : GQLDOperation {
	this() {
		super(GQLDKind.Query);
		super.name = "Query";
	}
}

class GQLDMutation : GQLDOperation {
	this() {
		super(GQLDKind.Mutation);
		super.name = "Mutation";
	}
}

class GQLDSubscription : GQLDOperation {
	this() {
		super(GQLDKind.Subscription);
		super.name = "Subscription";
	}
}

class GQLDSchema(Type) : GQLDMap {
	GQLDType[string] types;

	GQLDObject __schema;
	GQLDObject __type;
	GQLDObject __field;
	GQLDObject __inputValue;
	GQLDObject __enumValue;
	GQLDObject __directives;

	GQLDNonNull __nonNullType;
	GQLDNullable __nullableType;
	GQLDNullable __listOfNonNullType;
	GQLDNonNull __nonNullListOfNonNullType;
	GQLDNonNull __nonNullField;
	GQLDNullable __listOfNonNullField;
	GQLDNonNull __nonNullInputValue;
	GQLDList __listOfNonNullInputValue;
	GQLDNonNull __nonNullListOfNonNullInputValue;
	GQLDList __listOfNonNullEnumValue;

	this() {
		super(GQLDKind.Schema);
		super.name = "Schema";
		this.createInbuildTypes();
		this.createIntrospectionTypes();
	}

	void createInbuildTypes() {
		this.types["String"] = new GQLDString();
		this.types["Int"] = new GQLDInt();
		this.types["Float"] = new GQLDFloat();
		this.types["Boolean"] = new GQLDBool();
		foreach(t; ["String", "Int", "Float", "Boolean"]) {
			this.types[t].typeKind = TypeKind.SCALAR;
		}
		//	GQLDObject tmp = new GQLDObject(t);
		//	this.types[t] = tmp;
		//	tmp.member[Constants.name] = new GQLDString();
		//	tmp.member[Constants.description] = new GQLDString();
		//	tmp.member[Constants.kind] = new GQLDEnum(Constants.__TypeKind);
		//	//tmp.resolver = buildTypeResolver!(Type,Con)();
		//}
	}

	void createIntrospectionTypes() {
		// build base types
		auto str = new GQLDString();
		auto nnStr = new GQLDNonNull(str);
		auto nllStr = new GQLDNullable(str);

		auto b = new GQLDBool();
		auto nnB = new GQLDNonNull(b);
		this.__schema = new GQLDObject(Constants.__schema);
		this.__type = new GQLDObject(Constants.__Type);
		this.__nullableType = new GQLDNullable(this.__type);
		this.__schema.member["mutationType"] = this.__nullableType;
		this.__schema.member["subscriptionType"] = this.__nullableType;

		this.__type.member[Constants.ofType] = this.__nullableType;
		this.__type.member[Constants.kind] = new GQLDEnum(Constants.__TypeKind);
		this.__type.member[Constants.name] = nllStr;
		this.__type.member[Constants.description] = nllStr;

		this.__nonNullType = new GQLDNonNull(this.__type);
		this.__schema.member["queryType"] = this.__nonNullType;
		auto lNNTypes = new GQLDList(this.__nonNullType);
		auto nlNNTypes = new GQLDNullable(lNNTypes);
		this.__listOfNonNullType = new GQLDNullable(lNNTypes);
		this.__type.member[Constants.interfaces] = new GQLDNonNull(lNNTypes);
		this.__type.member["possibleTypes"] = nlNNTypes;

		this.__nonNullListOfNonNullType = new GQLDNonNull(lNNTypes);
		this.__schema.member["types"] = this.__nonNullListOfNonNullType;

		this.__field = new GQLDObject("__Field");
		this.__field.member[Constants.name] = nnStr;
		this.__field.member[Constants.description] = nllStr;
		this.__field.member[Constants.type] = this.__nonNullType;
		this.__field.member[Constants.isDeprecated] = nnB;
		this.__field.member[Constants.deprecationReason] = nllStr;

		this.__nonNullField = new GQLDNonNull(this.__field);
		auto lNNFields = new GQLDList(this.__nonNullField);
		this.__listOfNonNullField = new GQLDNullable(lNNFields);
		this.__type.member[Constants.fields] = this.__listOfNonNullField;

		this.__inputValue = new GQLDObject(Constants.__InputValue);
		this.__inputValue.member[Constants.name] = nnStr;
		this.__inputValue.member[Constants.description] = nllStr;
		this.__inputValue.member["defaultValue"] = nllStr;
		this.__inputValue.member[Constants.type] = this.__nonNullType;

		this.__nonNullInputValue = new GQLDNonNull(this.__inputValue);
		this.__listOfNonNullInputValue = new GQLDList(
				this.__nonNullInputValue
			);
		auto nlNNInputValue = new GQLDNullable(
				this.__listOfNonNullInputValue
			);

		this.__type.member["inputFields"] = nlNNInputValue;

		this.__nonNullListOfNonNullInputValue = new GQLDNonNull(
				this.__listOfNonNullInputValue
			);

		this.__field.member[Constants.args] = this.__nonNullListOfNonNullInputValue;

		this.__enumValue = new GQLDObject(Constants.__EnumValue);
		this.__enumValue.member[Constants.name] = nnStr;
		this.__enumValue.member[Constants.description] = nllStr;
		this.__enumValue.member[Constants.isDeprecated] = nnB;
		this.__enumValue.member[Constants.deprecationReason] = nllStr;

		this.__listOfNonNullEnumValue = new GQLDList(new GQLDNonNull(
				this.__enumValue
			));

		auto nnListOfNonNullEnumValue = new
			GQLDNullable(this.__listOfNonNullEnumValue);

		//this.__type.member[Constants.enumValues] = this.__listOfNonNullEnumValue;
		this.__type.member[Constants.enumValues] = nnListOfNonNullEnumValue;

		this.__directives = new GQLDObject(Constants.__Directive);
		this.__directives.member[Constants.name] = nnStr;
		this.__directives.member[Constants.description] = str;
		this.__directives.member[Constants.args] =
			this.__nonNullListOfNonNullInputValue;
		this.__directives.member[Constants.locations] = new GQLDNonNull(
				this.__listOfNonNullEnumValue
			);

		this.__schema.member[Constants.directives] = new GQLDNonNull(
				new GQLDList(new GQLDNonNull(this.__directives))
			);


		//foreach(t; ["String", "Int", "Float", "Boolean"]) {
		//	this.types[t].toObject().member[Constants.fields] =
		//		this.__listOfNonNullField;
		//}
	}

	override string toString() const {
		auto app = appender!string();
		formattedWrite(app, "Operation\n");
		foreach(key, value; super.member) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}

		formattedWrite(app, "Types\n");
		foreach(key, value; this.types) {
			formattedWrite(app, "%s: %s\n", key, value.toString());
		}
		return app.data;
	}

	GQLDType getReturnType(GQLDType t, string field) {
		GQLDType ret;
		GQLDObject ob = t.toObject();
		if(auto s = t.toScalar()) {
			ret = s;
			goto retLabel;
		} else if(auto op = t.toOperation()) {
			ret = op.returnType;
			goto retLabel;
		} else if(auto map = t.toMap()) {
			if(field in map.member) {
				auto tmp = map.member[field];
				if(auto op = tmp.toOperation()) {
					GQLDType rt = op.returnType.unpack();
					if(auto u = rt.toUnion()) {
						foreach(key, value; u.member) {
							if(GQLDMap valueM = toMap(value.unpack())) {
								if(field in valueM.member) {
									ret = valueM.member[field];
									writeln(__LINE__);
									goto retLabel;
								}
							}
						}
					}
					ret = rt;
					goto retLabel;
				} else if(auto u = t.unpack().toUnion()) {
					foreach(key, value; u.member) {
						if(GQLDMap valueM = toMap(value.unpack())) {
							if(field in valueM.member) {
								ret = valueM.member[field];
								goto retLabel;
							}
						}
					}
				} else {
					ret = tmp;
					goto retLabel;
				}
			} else if(ob && ob.base && field in ob.base.member) {
				return ob.base.member[field];
			} else if(field == "__typename") {
				// the type of the field __typename is always a string
				ret = this.types["String"];
				goto retLabel;
			} else if(auto u = t.unpack().toUnion()) {
				foreach(key, value; u.member) {
					if(GQLDMap valueM = toMap(value.unpack())) {
						if(field in valueM.member) {
							ret = valueM.member[field];
							goto retLabel;
						}
					}
				}
			} else {
				// if we couldn't find it in the passed map, maybe it is in some
				// of its derivatives
				foreach(deriv; map.derivatives) {
					if(field in deriv.member) {
						return deriv.member[field];
					}
				}
				return null;
			}
		} else {
			ret = t;
		}
		retLabel:
		return ret;
	}
}

GQLDObject toObject(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDMap toMap(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDScalar toScalar(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDOperation toOperation(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDList toList(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDNullable toNullable(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDNonNull toNonNull(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDFloat toFloat(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDInt toInt(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDLeaf toLeaf(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDEnum toEnum(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDBool toBool(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDString toString(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDUnion toUnion(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDQuery toQuery(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDMutation toMutation(GQLDType t) {
	return cast(typeof(return))t;
}

GQLDSubscription toSubscription(GQLDType t) {
	return cast(typeof(return))t;
}

unittest {
	auto str = new GQLDString();
	assert(str.name == "String");

	auto map = str.toMap();
	assert(map is null);
}

string toShortString(const(GQLDType) e) {
	if(auto o = cast(const(GQLDObject))e) {
		return o.name;
	} else if(auto u = cast(const(GQLDUnion))e) {
		return u.name;
	} else {
		return e.toString();
	}
}

TypeKind typeToTypeEnum(Type)(GQLDUdaData uda) {
	if(uda.typeKind != TypeKind.UNDEFINED) {
		return uda.typeKind;
	} else {
		static if(is(Type : Nullable!F, F)) {
			return typeToTypeEnum!F(uda);
		} else static if(isCallable!Type) {
			return typeToTypeEnum!(ReturnType!Type)(uda);
		} else static if(is(Type == enum)) {
			return TypeKind.ENUM;
		} else static if(is(Type == bool)) {
			return TypeKind.SCALAR;
		} else static if(is(Type : GQLDCustomLeaf!Fs, Fs...)) {
			return TypeKind.SCALAR;
		} else static if(isFloatingPoint!(Type)) {
			return TypeKind.SCALAR;
		} else static if(isIntegral!(Type)) {
			return TypeKind.SCALAR;
		} else static if(isSomeString!Type) {
			return TypeKind.SCALAR;
		} else static if(isArray!Type) {
			return typeToTypeEnum!(ElementEncodingType!Type)(uda);
		} else static if(is(Type == void)) {
			return TypeKind.SCALAR;
		} else static if(is(Type == union)) {
			return TypeKind.UNION;
		} else static if(isAggregateType!Type) {
			return TypeKind.OBJECT;
		} else {
			static assert(false, Type.stringof ~ " not handled");
		}
	}
}

GQLDType typeToGQLDType(TypeQ, SCH)(ref SCH ret, bool wrapInNonNull) {
	alias TypeUQ = Unqual!TypeQ;
	alias Type = TypeQ;
	enum tuda = getUdaData!TypeUQ;
	enum tuda2 = getUdaData!Type;
	GQLDType retValue;
	static if(is(Type == enum)) {
		GQLDEnum r;
		if(Type.stringof in ret.types) {
			r = cast(GQLDEnum)ret.types[Type.stringof];
		} else {
			r = new GQLDEnum(Type.stringof, [__traits(allMembers, Type)]);
			ret.types[Type.stringof] = r;
		}
		r.udaData = tuda;
		r.typeKind = typeToTypeEnum!Type(tuda);
		retValue = r;
	} else static if(is(Type == bool) || is(TypeUQ == bool)) {
		retValue = new GQLDBool();
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
	} else static if(isFloatingPoint!(Type) || isFloatingPoint!(TypeUQ)) {
		retValue = new GQLDFloat();
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
	} else static if(isIntegral!(Type) || isIntegral!(TypeUQ)) {
		retValue = new GQLDInt();
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
	} else static if(isSomeString!Type) {
		retValue = new GQLDString();
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
	} else static if(is(Type == union)) {
		GQLDUnion r;
		if(Type.stringof in ret.types) {
			r = cast(GQLDUnion)ret.types[Type.stringof];
		} else {
			r = new GQLDUnion(Type.stringof);
			ret.types[Type.stringof] = r;

			alias fieldNames = FieldNameTuple!(Type);
			alias fieldTypes = Fields!(Type);
			static foreach(idx; 0 .. fieldNames.length) {{
				static if(fieldNames[idx] != Constants.directives) {{
					auto tmp = typeToGQLDType!(fieldTypes[idx])(ret, true);
					r.member[fieldNames[idx]] = tmp;

					if(GQLDMap tmpMap = tmp.toMap()) {
						r.addDerivative(tmpMap);
					}
				}}
			}}
		}
		r.udaData = tuda;
		r.typeKind = typeToTypeEnum!Type(tuda);
		retValue = r;
	} else static if(is(Type : Nullable!F, F)) {
		auto et = typeToGQLDType!(F)(ret, false);
		if(GQLDNullable etN = toNullable(et)) {
			retValue = et;
		} else {
			retValue = new GQLDNullable(et);
		}
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
		wrapInNonNull = false;
	} else static if(is(Type : GQLDCustomLeaf!Fs, Fs...)) {
		retValue = new GQLDLeaf(Fs[0].stringof);
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
	} else static if(is(Type : NullableStore!F, F)) {
		auto et = typeToGQLDType!(F)(ret, false);
		if(GQLDNullable etN = toNullable(et)) {
			retValue = et;
		} else {
			retValue = new GQLDNullable(et);
		}
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
		wrapInNonNull = false;
	} else static if(isArray!Type) {
		retValue = new GQLDList(typeToGQLDType!(ElementEncodingType!Type)(ret, true));
		retValue.udaData = tuda;
		retValue.typeKind = typeToTypeEnum!Type(tuda);
	} else static if(isAggregateType!Type) {
		import graphql.uda;

		if(Type.stringof in ret.types) {
			retValue = cast(GQLDObject)ret.types[Type.stringof];
		} else {
			//debug writefln("%s %s", Type.stringof, tuda);

			GQLDObject r;
			r = tuda.typeKind != TypeKind.UNDEFINED
				? new GQLDObject(Type.stringof, tuda.typeKind)
				: new GQLDObject(Type.stringof);
			r.deprecatedInfo = tuda.deprecationInfo;
			ret.types[Type.stringof] = r;
			r.udaData = tuda;
			r.typeKind = typeToTypeEnum!Type(tuda);

			alias fieldNames = FieldNameTuple!(Type);
			alias fieldTypes = Fields!(Type);
			static foreach(idx; 0 .. fieldNames.length) {{
				enum GQLDUdaData uda = getUdaData!(Type, fieldNames[idx]);
				static if(uda.ignore != Ignore.yes
						&& fieldNames[idx] != "factory"
						&& fieldNames[idx] != "opEquals"
						&& fieldNames[idx] != "opCmp"
						&& fieldNames[idx] != "toHash"
						&& fieldNames[idx] != "toString"
						&& fieldNames[idx] != "__ctor")
				{
					static if (fieldNames[idx] != Constants.directives) {
						auto tmp = typeToGQLDType!(fieldTypes[idx])(ret, true);
						tmp.deprecatedInfo = uda.deprecationInfo;
						tmp.udaData = uda;
						tmp.typeKind = typeToTypeEnum!Type(uda);
						r.member[fieldNames[idx]] = tmp;
						static if(uda.ignoreForInput == IgnoreForInput.yes) {
							r.outputOnlyMembers.insert(fieldNames[idx]);
						}
					}
				}
			}}

			static if(is(Type == class)) {
				alias bct = BaseClassesTuple!(Type);
				static if(bct.length > 1) {
					auto d = cast(GQLDObject)typeToGQLDType!(bct[0])
							(ret, false);
					r.base = d;
					d.addDerivative(r);

				}
				assert(bct.length > 1 ? r.base !is null : true);
			}

			static foreach(mem; __traits(allMembers, Type)) {{
				// not a type
				static if(!is(__traits(getMember, Type, mem))) {
					enum GQLDUdaData uda = getUdaData!(Type, mem);
					alias MemType = typeof(__traits(getMember, Type, mem));
					static if(uda.ignore != Ignore.yes && isCallable!MemType
						&& mem != "factory"
						&& mem != "opEquals"
						&& mem != "opCmp"
						&& mem != "toHash"
						&& mem != "__ctor"
						&& mem != "toString"
					) {
						GQLDOperation op = new GQLDQuery();
						op.udaData = uda;
						op.typeKind = typeToTypeEnum!MemType(uda);
						op.deprecatedInfo = uda.deprecationInfo;

						r.member[mem] = op;
						op.returnType =
							typeToGQLDType!(ReturnType!(MemType))(ret, true);

						alias paraNames = ParameterIdentifierTuple!(
								__traits(getMember, Type, mem)
								);
						alias paraTypes = Parameters!(
								__traits(getMember, Type, mem)
								);
						static foreach(idx; 0 .. paraNames.length) {{
							GQLDType p = typeToGQLDType!(paraTypes[idx])(ret, true);
							static if(idx < paraNames.length) {
								enum udaPAS = filterGQLDUdaParameter!(__traits(getAttributes, paraTypes[idx .. idx + 1]));
								static if(udaPAS.length == 0) {
									enum GQLDUdaData udaP = GQLDUdaData.init;
								} else {
									enum GQLDUdaData udaP = udaPAS[0];
								}
								p.udaData = udaP;
								p.typeKind = typeToTypeEnum!(paraTypes[idx])(udaPAS);
							}
							op.parameters[paraNames[idx]] = p;
						}}
						static if(uda.ignoreForInput == IgnoreForInput.yes) {
							r.outputOnlyMembers.insert(mem);
						}
					}
				}
			}}
			retValue = r;
		}
	} else {
		static assert(false, Type.stringof);
	}
	if(wrapInNonNull) {
		auto realRet = new GQLDNonNull(retValue);
		realRet.udaData = tuda;
		realRet.typeKind = typeToTypeEnum!Type(tuda);
		return realRet;
	} else {
		return retValue;
	}
}

GQLDType unpack(GQLDType t) {
	if(GQLDNonNull nn = toNonNull(t)) {
		return nn.elementType;
	}
	return t;
}

GQLDType unpack2(GQLDType t) {
	if(GQLDNonNull nn = toNonNull(t)) {
		return unpack2(nn.elementType);
	} else if(GQLDNullable nn = toNullable(t)) {
		return unpack2(nn.elementType);
	} else if(GQLDList nn = toList(t)) {
		return unpack2(nn.elementType);
	}
	return t;
}

unittest {
	int a;
	GQLDType i = typeToGQLDType!(int)(a, true);
}
