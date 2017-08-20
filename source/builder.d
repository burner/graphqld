module builder;

import std.experimental.allocator;
import std.experimental.allocator.mallocator : Mallocator;
import std.exception : enforce;

import fixedsizearray;

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

struct Fragment {
	string name;
	string tc;
	Directives dirs;
	Selections sels;
}

FragmentDefinition findFragment(Document doc, string name) {
	Definitions cur = doc.defs;
	while(cur !is null) {
		if(cur.def.ruleSelection == DefinitionEnum.F) {
			if(cur.def.frag.name.value == name) {
				return cur.def.frag;
			}
		}
		cur = cur.follow;
	}

	return null;
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

	auto f = findFragment(d, "fooo");
	assert(f is null);
}

unittest {
	string s = `
fragment fooo on Hero {
  name
}`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "fooo");
	assert(f !is null);
	assert(f.ss.sel.sel.field.name.name.value == "name");
}

void resolveFragments(ref FixedSizeArray!(Selections,32) stack, Document doc) {
	if(stack.length == 0) {
		return;
	}
	if(stack.back.sel.ruleSelection == SelectionEnum.Field) {
		return;
	} else if(stack.back.sel.ruleSelection == SelectionEnum.Spread) {
		FragmentDefinition f = findFragment(doc, stack.back.sel.frag.name.value);
		enforce(f !is null);

		Selections fs = f.ss.sel;
		stack.insertBack(fs);
		resolveFragments(stack, doc);
	}
}

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
	Document doc;

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
		return FieldRange(this.f.ss.sel, this.doc);
	}
}

struct FieldRange {
	FixedSizeArray!(Selections,32) cur;
	Document doc;

	this(Selections sels, Document doc) {
		this.doc = doc;
		this.cur.insertBack(sels);
		resolveFragments(this.cur, this.doc);
	}

	this(ref FieldRange old) {
		this.cur = old.cur;
		this.doc = doc;
	}

	@property bool empty() const pure {
		return this.cur.length == 0;
	}

	@property FieldRangeItem front() {
		return FieldRangeItem(this.cur.back.sel.field, this.doc);
	}

	void popFront() {
		while(this.cur.length > 0) {
			this.cur.back = this.cur.back.follow;
			if(this.cur.back is null) {
				this.cur.removeBack();
				continue;
			} else {
				resolveFragments(this.cur, this.doc);
				break;
			}
		}
	}

	@property FieldRange save() {
		return FieldRange(this);
	}
}

FieldRange fieldRange(OperationDefinition od, Document doc) {
	return FieldRange(od.ss.sel, doc);
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

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	r.popFront();
	assert(r.empty);
}

unittest {
	string s = `{
 user(id: 1) {
	 ...foo
 }
}

fragment foo on User {
	name
	age
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "foo");
	assert(f !is null);

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	assert(fss.front.name == "name", fss.front.name);
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(fss.empty);
	r.popFront();
	assert(r.empty);
}

unittest {
	string s = `{
 user(id: 1) {
	 ...foo
	 ...bar
 }
}

fragment foo on User {
	name
}

fragment bar on User {
	age
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "foo");
	assert(f !is null);

	auto f2 = findFragment(d, "bar");
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	assert(fss.front.name == "name", fss.front.name);
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(fss.empty);
	r.popFront();
	assert(r.empty);
}

unittest {
	string s = `{
 user(id: 1) {
	 ...foo
	 ...bar
	 hello
 }
}

fragment foo on User {
	name
}

fragment bar on User {
	age
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "foo");
	assert(f !is null);

	auto f2 = findFragment(d, "bar");
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	assert(fss.front.name == "name", fss.front.name);
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "hello");
	fss.popFront();
	assert(fss.empty);
	r.popFront();
	assert(r.empty);
}

unittest {
	string s = `{
 user(id: 1) {
	 hello
	 ...foo
	 ...bar
 }
}

fragment foo on User {
	name
}

fragment bar on User {
	age
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "foo");
	assert(f !is null);

	auto f2 = findFragment(d, "bar");
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	assert(fss.front.name == "hello", fss.front.name);
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "name");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(fss.empty);
	r.popFront();
	assert(r.empty);
}

unittest {
	string s = `{
 user(id: 1) {
	 hello
	 ...foo
	 ...bar
 }
}

fragment foo on User {
	name
}

fragment bar on User {
	age
	...baz
}

fragment baz on User {
	args
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "foo");
	assert(f !is null);

	auto f2 = findFragment(d, "bar");
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	assert(fss.front.name == "hello", fss.front.name);
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "name");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "args");
	fss.popFront();
	assert(fss.empty);
	r.popFront();
	assert(r.empty);
}

unittest {
	string s = `{
 user(id: 1) {
	 hello
	 ...foo
	 zzzz
	 ...bar
 }
}

fragment foo on User {
	name
}

fragment bar on User {
	age
	...baz
}

fragment baz on User {
	args
}
`;
	auto l = Lexer(s);
	IAllocator a = allocatorObject(Mallocator.instance);
	auto p = Parser(l, a);
	auto d = p.parseDocument();

	auto f = findFragment(d, "foo");
	assert(f !is null);

	auto f2 = findFragment(d, "bar");
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d);
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
	assert(fss.front.name == "hello", fss.front.name);
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "name");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "zzzz");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "age");
	fss.popFront();
	assert(!fss.empty);
	assert(fss.front.name == "args");
	fss.popFront();
	assert(fss.empty);
	r.popFront();
	assert(r.empty);
}
