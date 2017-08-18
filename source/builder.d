module builder;

import std.experimental.allocator;
import std.experimental.allocator.mallocator : Mallocator;

import ast;
import parser;
import lexer;

string ctor = `

HTTPServerRequest __request;
HTTPServerResponse __response;
Document document;
Parser parser;
this(HTTPServerRequest req, HTTPServerResponse res, IAllocator alloc) {
	this.__resquest = req;
	this.__response = res;

	this.parser = Parser(Lexer(req.bodyReader.readAllUTF8(), alloc));
}

void parse() {
	this.document = this.parser.parseDocument();
}
`;

struct ArgumentRangeItem {
	Argument arg;

	@property string name() const pure {
		return arg.name.value;
	}

	@property ValueOrVariable value() {
		return arg.vv;
	}
}

struct ArgumentRange {
	ArgumentList cur;

	@property bool empty() const pure {
		return this.cur is null;
	}

	@property ArgumentRangeItem front() {
		return ArgumentRangeItem(this.cur.arg);
	}

	void popFront() {
		this.cur = this.cur.follow;
	}

	@property ArgumentRange save() {
		return ArgumentRange(this.cur);
	}
}

struct FieldRangeItem {
	Field f;

	@property string name() {
		return f.name.name.value;
	}

	@property string aka() {
		return f.name.aka.value;
	}

	ArgumentRange arguments() {
		if(this.f.args !is null) {
			return ArgumentRange(f.args.arg);
		} else {
			return ArgumentRange(null);
		}
	}

	bool hasSelectionSet() pure @safe {
		return f.ss !is null;
	}

	FieldRange getSelectionSet() {
		return fieldRange(this.f);
	}
}

struct FieldRange {
	Selections cur;

	@property bool empty() const pure {
		return this.cur is null;
	}

	@property FieldRangeItem front() {
		return FieldRangeItem(this.cur.sel.field);
	}

	void popFront() {
		this.cur = this.cur.follow;
	}

	@property FieldRange save() {
		return FieldRange(this.cur);
	}
}

FieldRange fieldRange(OperationDefinition od) {
	return FieldRange(od.ss.sel);
}

FieldRange fieldRange(Field field) {
	return FieldRange(field.ss.sel);
}

unittest {
	string s = `{
 user(id: 1) {
   friends {
     name
   }
   name
   age
 }
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	FieldRange r = fieldRange(d.defs.def.op);
	assert(!r.empty);
	assert(r.front.name == "user");
	ArgumentRange argL = r.front.arguments();
	assert(!argL.empty);
	auto ari = argL.front;
	assert(ari.name == "id");
	argL.popFront();
	assert(argL.empty);
	assert(r.front.hasSelectionSet());
	auto fss = r.front.getSelectionSet();
	assert(!fss.empty);
	assert(fss.front.name == "friends");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "name");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(fss.empty);
}
