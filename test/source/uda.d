module uda;

enum TypeKind {
	UNDEFINED,
	SCALAR,
	OBJECT,
	INTERFACE,
	UNION,
	ENUM,
	INPUT_OBJECT,
	LIST,
	NON_NULL
}

struct GQLDUdaData {
	TypeKind typeKind;
}

GQLDUdaData GQLDUda(Args...)(Args args) {
	GQLDUdaData ret;
	static foreach(mem; __traits(allMembers, GQLDUdaData)) {
		static foreach(arg; args) {
			static if(is(typeof(__traits(getMember, ret, mem)) ==
						typeof(arg)))
			{
				__traits(getMember, ret, mem) = arg;
			}
		}
	}
	return ret;
}
