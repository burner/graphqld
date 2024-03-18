import std.format;
import std.stdio;
import std.math : isClose;

enum TokenType : ubyte {
	undefined,
	exclamation,
	dollar,
	lparen,
	rparen,
	dots,
	colon,
	equal,
	at,
	lbrack,
	rbrack,
	lcurly,
	rcurly,
	pipe,
	name,
	intValue,
	floatValue,
	stringValue,
	query,
	mutation,
	subscription,
	fragment,
	on_,
	alias_,
	true_,
	false_,
	null_,
	comment,
	comma,
	union_,
	type,
	typename,
	skip,
	include_,
	input,
	scalar,
	schema,
	schema__,
	directive,
	enum_,
	interface_,
	implements,
	extend,
}

struct Token {
	private ulong value;

	TokenType getTokenType() const {
		return cast(TokenType)(this.value & 63LU);
	}

	void setTokenType(TokenType t) {
		this.value = this.value >> 6;
		this.value = this.value << 6;
		this.value |= t;
	}

	bool hasInternalValue() const {
		return (this.value & (1 << 7)) > 0;
	}

	void setHasInternalValue() {
		this.value |= (1 << 7);
	}

	long getI55() const {
		long v = cast(long)this.value;
		v = v >> 8;
		return v;
	}

	void setI55(long l) {
		l = l << 8;
		ulong ul = cast(ulong)l;
		this.value = this.value << 56;
		this.value = this.value >> 56;
		this.value |= ul;
		this.setHasInternalValue();
	}

	ulong getU55() const {
		ulong v = this.value;
		v = v >> 8;
		return v;
	}

	void setU55(ulong l) {
		l = l << 8;
		this.value = this.value << 56;
		this.value = this.value >> 56;
		this.value |= l;
		this.setHasInternalValue();
	}

	float getF32() const {
		ulong u = this.value >> 8;
		uint i = cast(uint)u;
		return *cast(float*)&i;
	}

	void setF32(float f) {
		uint ui = *cast(uint*)&f;
		ulong ul = cast(ulong)ui;
		ul = ul << 8;
		this.value = this.value << 56;
		this.value = this.value >> 56;
		this.value |= ul;
		this.setHasInternalValue();
	}

	bool getBool() {
		return this.getI55() > 0;
	}

	void setBool(bool b) {
		this.setI55(cast(long)b);
	}
}

unittest {
	static assert(Token.sizeof == 8);
}

unittest {
	Token t;
	t.setHasInternalValue();
	assert(t.hasInternalValue());
}

unittest {
	Token t;
	long v = (1L<<55)-1;
	t.setI55(v);
	foreach(tt; TokenType.min .. TokenType.max) {
		t.setTokenType(tt);
		assert(t.hasInternalValue());
		assert(t.getTokenType() == tt);
		long gv = t.getI55();
		assert(gv == v, format("%s %s", v, gv));
	}
}

unittest {
	Token t;
	ulong v = (1L<<5)-1;
	t.setI55(v);
	foreach(tt; TokenType.min .. TokenType.max) {
		v *= 2;
		t.setU55(v);
		t.setTokenType(tt);
		assert(t.hasInternalValue());
		assert(t.getTokenType() == tt);
		ulong gv = t.getU55();
		assert(gv == v, format("%s %s", v, gv));
	}
}

unittest {
	Token t;
	t.setBool(true);
	foreach(tt; TokenType.min .. TokenType.max) {
		t.setTokenType(tt);
		assert(t.hasInternalValue());
		assert(t.getTokenType() == tt);
		assert(t.getBool());
	}
}

unittest {
	float f = 13.37;
	Token t;
	t.setF32(f);
	foreach(tt; TokenType.min .. TokenType.max) {
		f *= 10.0;
		t.setF32(f);
		t.setTokenType(tt);
		assert(t.hasInternalValue());
		assert(t.getTokenType() == tt);
		assert(isClose(t.getF32(), f), format("%f", t.getF32()));
	}
}
