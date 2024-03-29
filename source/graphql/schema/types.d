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
		this.typeKind = TypeKind.SCALAR;
	}
}

class GQLDLeaf : GQLDScalar {
	this(string name) {
		super(GQLDKind.CustomLeaf);
		super.name = name;
		super.typeKind = TypeKind.SCALAR;
	}

	override string toString() const {
		return format("GQLDCustomLeaf(%s)", this.name);
	}
}

class GQLDString : GQLDScalar {
	this() {
		super(GQLDKind.String);
		super.name = "String";
		super.typeKind = TypeKind.SCALAR;
	}

	override string toString() const {
		return "String";
	}
}

class GQLDFloat : GQLDScalar {
	this() {
		super(GQLDKind.Float);
		super.name = "Float";
		super.typeKind = TypeKind.SCALAR;
	}

	override string toString() const {
		return "Float";
	}
}

class GQLDInt : GQLDScalar {
	this() {
		super(GQLDKind.Int);
		super.name = "Int";
		super.typeKind = TypeKind.SCALAR;
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
		super.name = enumName;
		super.typeKind = TypeKind.SCALAR;
		this.enumName = enumName;
		this.memberNames = memberNames;
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
		this.typeKind = TypeKind.OBJECT;
	}
	this(GQLDKind kind) {
		super(kind);
		this.typeKind = TypeKind.OBJECT;
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
		this.typeKind = TypeKind.OBJECT;
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
		this.typeKind = TypeKind.UNION;
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
		this.typeKind = TypeKind.LIST;
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
		this.typeKind = TypeKind.NON_NULL;
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
		this.typeKind = TypeKind.OBJECT;
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
	Json defaultParameter;

	this(GQLDKind kind) {
		super(kind);
		this.typeKind = TypeKind.OBJECT;
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
		this.typeKind = TypeKind.OBJECT;
		super.name = "Query";
	}
}

class GQLDMutation : GQLDOperation {
	this() {
		super(GQLDKind.Mutation);
		this.typeKind = TypeKind.OBJECT;
		super.name = "Mutation";
	}
}

class GQLDSubscription : GQLDOperation {
	this() {
		super(GQLDKind.Subscription);
		this.typeKind = TypeKind.OBJECT;
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
	GQLDOperation __typeIntrospection;

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
	GQLDType __nnStr;

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
	}

	void createIntrospectionTypes() {
		// build base types
		auto str = new GQLDString();
		this.__nnStr = new GQLDNonNull(str);
		this.__nnStr.typeKind = TypeKind.NON_NULL;
		auto nllStr = new GQLDNullable(str);

		auto b = new GQLDBool();
		b.typeKind = TypeKind.SCALAR;
		auto nnB = new GQLDNonNull(b);
		this.__schema = new GQLDObject(Constants.__schema);
		this.__schema.typeKind = TypeKind.OBJECT;
		this.__type = new GQLDObject(Constants.__Type);
		this.__type.typeKind = TypeKind.OBJECT;
		this.types["__Type"] = this.__type;
		this.__nullableType = new GQLDNullable(this.__type);
		this.__nullableType.typeKind = TypeKind.OBJECT;
		this.__schema.member["mutationType"] = this.__nullableType;
		this.__schema.member["subscriptionType"] = this.__nullableType;

		this.__type.member[Constants.ofType] = this.__nullableType;
		this.types["__TypeKind"] = new GQLDEnum(Constants.__TypeKind);
		this.__type.member[Constants.kind] = this.types["__TypeKind"];
		this.__type.member[Constants.kind].typeKind = TypeKind.ENUM;
		this.__type.member[Constants.name] = nllStr;
		this.__type.member[Constants.description] = nllStr;

		this.__nonNullType = new GQLDNonNull(this.__type);
		this.__nonNullType.typeKind = TypeKind.NON_NULL;
		this.__schema.member["queryType"] = this.__nonNullType;
		auto lNNTypes = new GQLDList(this.__nonNullType);
		lNNTypes.typeKind = TypeKind.LIST;
		auto nlNNTypes = new GQLDNullable(lNNTypes);
		this.__listOfNonNullType = new GQLDNullable(lNNTypes);
		this.__listOfNonNullType.typeKind = TypeKind.OBJECT;
		this.__type.member[Constants.interfaces] = new GQLDNonNull(lNNTypes);
		this.__type.member[Constants.interfaces].typeKind = TypeKind.NON_NULL;
		this.__type.member["possibleTypes"] = nlNNTypes;

		this.__nonNullListOfNonNullType = new GQLDNonNull(lNNTypes);
		this.__nonNullListOfNonNullType.typeKind = TypeKind.NON_NULL;
		this.__schema.member["types"] = this.__nonNullListOfNonNullType;

		this.__field = new GQLDObject("__Field");
		this.__field.typeKind = TypeKind.OBJECT;
		this.__field.member[Constants.name] = this.__nnStr;
		this.__field.member[Constants.description] = nllStr;
		this.__field.member[Constants.type] = this.__nonNullType;
		this.__field.member[Constants.isDeprecated] = nnB;
		this.__field.member[Constants.deprecationReason] = nllStr;

		this.__nonNullField = new GQLDNonNull(this.__field);
		this.__nonNullField.typeKind = TypeKind.NON_NULL;
		auto lNNFields = new GQLDList(this.__nonNullField);
		this.__listOfNonNullField = new GQLDNullable(lNNFields);
		this.__listOfNonNullField.typeKind = TypeKind.OBJECT;
		//this.__type.member[Constants.fields] = this.__listOfNonNullField;
		auto fieldTmp = new GQLDQuery();
		fieldTmp.returnType = this.__listOfNonNullField;
		fieldTmp.parameters["includeDeprecated"] = new GQLDNullable(new GQLDBool());
		this.__type.member[Constants.fields] = fieldTmp;

		this.__inputValue = new GQLDObject(Constants.__InputValue);
		this.types["__InputValue"] = this.__inputValue;
		this.__inputValue.typeKind = TypeKind.INPUT_OBJECT;
		this.__inputValue.member[Constants.name] = this.__nnStr;
		this.__inputValue.member[Constants.description] = nllStr;
		this.__inputValue.member["defaultValue"] = nllStr;
		this.__inputValue.member[Constants.type] = this.__nonNullType;

		this.__nonNullInputValue = new GQLDNonNull(this.__inputValue);
		this.__nonNullInputValue.typeKind = TypeKind.NON_NULL;
		this.__listOfNonNullInputValue = new GQLDList(
				this.__nonNullInputValue
			);
		this.__listOfNonNullInputValue.typeKind = TypeKind.LIST;
		auto nlNNInputValue = new GQLDNullable(
				this.__listOfNonNullInputValue
			);

		this.__type.member["inputFields"] = nlNNInputValue;

		this.__enumValue = new GQLDObject(Constants.__EnumValue);
		this.__enumValue.typeKind = TypeKind.ENUM;
		this.__enumValue.member[Constants.name] = this.__nnStr;
		this.__enumValue.member[Constants.description] = nllStr;
		this.__enumValue.member[Constants.isDeprecated] = nnB;
		this.__enumValue.member[Constants.deprecationReason] = nllStr;

		auto enumTmp = new GQLDQuery();
		enumTmp.returnType = new GQLDNullable(new GQLDList(this.__enumValue));
		enumTmp.parameters["includeDeprecated"] = new GQLDNullable(new GQLDBool());
		this.__type.member["enumValues"] = enumTmp;

		this.__nonNullListOfNonNullInputValue = new GQLDNonNull(
				this.__listOfNonNullInputValue
			);

		this.__nonNullListOfNonNullInputValue.typeKind = TypeKind.NON_NULL;

		this.__field.member[Constants.args] = this.__nonNullListOfNonNullInputValue;

		this.__listOfNonNullEnumValue = new GQLDList(new GQLDNonNull(
				this.__enumValue
			));
		this.__listOfNonNullEnumValue.typeKind = TypeKind.LIST;
		this.__listOfNonNullEnumValue.elementType.typeKind = TypeKind.NON_NULL;

		auto nnListOfNonNullEnumValue = new GQLDNullable(
				this.__listOfNonNullEnumValue
			);
		nnListOfNonNullEnumValue.typeKind = TypeKind.OBJECT;

		//this.__type.member[Constants.enumValues] = this.__listOfNonNullEnumValue;
		//this.__type.member[Constants.enumValues] = nnListOfNonNullEnumValue;

		this.__directives = new GQLDObject(Constants.__Directive);
		this.__directives.typeKind = TypeKind.OBJECT;
		this.__directives.member[Constants.name] = this.__nnStr;
		this.__directives.member[Constants.description] = str;
		this.__directives.member[Constants.args] =
			this.__nonNullListOfNonNullInputValue;
		this.__directives.member[Constants.locations] = new GQLDNonNull(
				new GQLDList(new GQLDNonNull(new GQLDEnum("__DirectiveLocation")))
			);
		this.__directives.typeKind = TypeKind.OBJECT;

		this.__schema.member[Constants.directives] = new GQLDNonNull(
				new GQLDList(new GQLDNonNull(this.__directives))
			);
		this.__schema.member[Constants.directives].typeKind = TypeKind.NON_NULL;

		this.__typeIntrospection = new GQLDOperation(GQLDKind.Object_);
		this.__typeIntrospection.typeKind = TypeKind.OBJECT;
		this.__typeIntrospection.returnType = this.__type;
		this.__typeIntrospection.parameters["name"] = this.__nnStr;

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
		//writefln("%s %s", t.name, field);
		GQLDType ret;
		GQLDObject ob = t.toObject();
		//if(auto s = t.toScalar()) {
		//	ret = s;
		//	goto retLabel;
		//} else
		if(auto op = t.toOperation()) {
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
		//} else {
		//	ret = t;
		}
		retLabel:
		//writefln("%s %s", __LINE__, ret);
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
		alias TypeU = Unqual!Type;
		static if(is(TypeU : Nullable!F, F)) {
			return typeToTypeEnum!F(uda);
		} else static if(isCallable!TypeU) {
			return typeToTypeEnum!(ReturnType!TypeU)(uda);
		} else static if(is(TypeU == enum)) {
			return TypeKind.ENUM;
		} else static if(is(TypeU == bool)) {
			return TypeKind.SCALAR;
		} else static if(is(TypeU : GQLDCustomLeaf!Fs, Fs...)) {
			return TypeKind.SCALAR;
		} else static if(isFloatingPoint!(TypeU)) {
			return TypeKind.SCALAR;
		} else static if(isIntegral!(TypeU)) {
			return TypeKind.SCALAR;
		} else static if(isSomeString!TypeU) {
			return TypeKind.SCALAR;
		} else static if(isArray!TypeU) {
			return typeToTypeEnum!(ElementEncodingType!TypeU)(uda);
		} else static if(is(TypeU == void)) {
			return TypeKind.SCALAR;
		} else static if(is(TypeU == union)) {
			return TypeKind.UNION;
		} else static if(isAggregateType!TypeU) {
			return TypeKind.OBJECT;
		} else {
			static assert(false, TypeU.stringof ~ " not handled");
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
				: new GQLDObject(Type.stringof, typeToTypeEnum!Type(tuda));
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
						alias parDef = ParameterDefaultValueTuple!(
								__traits(getMember, Type, mem)
							);

						Json dfArgs = Json.emptyObject();
						static foreach(i; 0 .. paraNames.length) {
							static if(!is(parDef[i] == void)) {
								dfArgs[paraNames[i]] = serializeToJson(parDef[i]);
							}
						}
						op.defaultParameter = dfArgs;
						static foreach(idx; 0 .. paraNames.length) {{
							GQLDType p = typeToGQLDType!(paraTypes[idx])(ret, true);
							p.typeKind = typeToTypeEnum!(paraTypes[idx])(GQLDUdaData.init);
							static if(idx < paraNames.length) {
								enum udaPAS = filterGQLDUdaParameter!(__traits(getAttributes, paraTypes[idx .. idx + 1]));
								static if(udaPAS.length == 0) {
									enum GQLDUdaData udaP = GQLDUdaData.init;
								} else {
									enum GQLDUdaData udaP = udaPAS[0];
								}
								p.udaData = udaP;
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
	retValue.udaData = tuda;
	retValue.typeKind = typeToTypeEnum!Type(tuda);
	if(wrapInNonNull) {
		assert(retValue.typeKind != TypeKind.UNDEFINED, format("%s", retValue));
		auto realRet = new GQLDNonNull(retValue);
		return realRet;
	} else {
		assert(retValue.typeKind != TypeKind.UNDEFINED, format("%s", retValue));
		return retValue;
	}
}

GQLDType unpack(GQLDType t) {
	if(GQLDNonNull nn = toNonNull(t)) {
		return nn.elementType;
	}
	return t;
}

GQLDType unpackNullable(GQLDType t) {
	if(GQLDNullable nn = toNullable(t)) {
		return nn.elementType;
	}
	return t;
}

GQLDType unpack2(GQLDType t) {
	if(GQLDNonNull nn = toNonNull(t)) {
		return unpack2(nn.elementType);
	} else if(GQLDNullable nn = toNullable(t)) {
		return unpack2(nn.elementType);
	} else if(GQLDOperation nn = toOperation(t)) {
		return unpack2(nn.returnType);
	} else if(GQLDList nn = toList(t)) {
		return unpack2(nn.elementType);
	}
	return t;
}

GQLDType unpackNonList(GQLDType t) {
	if(GQLDNonNull nn = toNonNull(t)) {
		return unpackNonList(nn.elementType);
	} else if(GQLDNullable nn = toNullable(t)) {
		return unpackNonList(nn.elementType);
	} else if(GQLDOperation nn = toOperation(t)) {
		return unpackNonList(nn.returnType);
	}
	return t;
}

unittest {
	int a;
	GQLDType i = typeToGQLDType!(int)(a, true);
}
