module builder;

import std.experimental.allocator;
import std.experimental.logger : logf;
import std.experimental.allocator.mallocator : Mallocator;
import std.exception : enforce;

import fixedsizearray;

import helper;
import ast;
import parser;
import lexer;

Selections findFragment(Document doc, string name, string[] typenames) {
	import std.algorithm.searching : canFind;
	import std.experimental.logger : logf;
	Definitions cur = doc.defs;
	logf("New search for %s", name);
	while(cur !is null) {
		enforce(cur.def !is null);
		if(cur.def.ruleSelection == DefinitionEnum.F) {
			enforce(cur.def.frag !is null);
			logf("%s == %s && %s in %s", cur.def.frag.name.value, name,
					cur.def.frag.tc.value, typenames
				);
			if(cur.def.frag.name.value == name
					&& canFind(typenames, cur.def.frag.tc.value))
			{
				logf("found it");
				return cur.def.frag.ss.sel;
			} else {
				logf("not found");
			}
		}
		cur = cur.follow;
	}

	logf("search failed");
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
	auto p = Parser(l);
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
	auto p = Parser(l);
	auto d = p.parseDocument();

	auto f = findFragment(d, "fooo", "Hero");
	assert(f !is null);
	assert(f.ss.sel.sel.field.name.name.value == "name");

	f = findFragment(d, "fooo", "Villian");
	assert(f is null);
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

	FieldRange selectionSet(string[] typenames) {
		return FieldRange(this.f.ss.sel, this.doc, typenames);
	}

}

struct FieldRange {
	FixedSizeArray!(Selections,32) cur;
	Document doc;
	string[] typenames;

	void test() {
		import std.format : format;
		import std.conv : to;
		import std.algorithm.iteration : map;
		//logf("%s", this.cur[].map!(i => format("nn %s, ft %s", i !is null,
		//		i !is null ? to!string(i.sel.ruleSelection) : "null"))
		//	);
		foreach(it; this.cur[]) {
			assert(it !is null);
			assert(it.sel.ruleSelection == SelectionEnum.Field);
		}
	}

	this(Selections sels, Document doc, string[] typenames) {
		this.doc = doc;
		this.typenames = typenames;
		this.cur.insertBack(sels);
		this.build();
		this.test();
	}

	this(ref FieldRange old) {
		this.cur = old.cur;
		this.doc = doc;
	}

	@property FieldRange save() {
		return FieldRange(this);
	}

	@property bool empty() const pure {
		return this.cur.length == 0;
	}

	@property FieldRangeItem front() {
		enforce(!this.cur.empty);
		enforce(this.cur.back !is null);
		enforce(this.cur.back.sel !is null);
		enforce(this.cur.back.sel.field !is null);
		return FieldRangeItem(this.cur.back.sel.field, this.doc);
	}

	void popFront() {
		this.cur.back = this.cur.back.follow;
		this.build();
		this.test();
	}

	void build() {
		if(this.cur.empty) {
			return;
		}
		if(this.cur.back is null) {
			this.cur.removeBack();
			this.build();
			this.test();
			return;
		}
		if(this.cur.back.sel.ruleSelection == SelectionEnum.Field) {
			return;
		} else if(this.cur.back.sel.ruleSelection == SelectionEnum.Spread
				|| this.cur.back.sel.ruleSelection == SelectionEnum.IFrag)
		{
			Selections follow = this.cur.back.follow;
			Selections f;
			if(this.cur.back.sel.ruleSelection == SelectionEnum.Spread) {
				f = findFragment(doc,
						this.cur.back.sel.frag.name.value, this.typenames
					);
			} else {
				f = resolveInlineFragment(this.cur.back.sel.ifrag,
						this.typenames
					);
			}

			this.cur.removeBack();

			if(follow !is null) {
				this.cur.insertBack(follow);
				this.build();
				this.test();
			}
			if(f !is null) {
				this.cur.insertBack(f);
				this.build();
				this.test();
			}
		}
	}
}

Selections resolveInlineFragment(InlineFragment ilf, string[] typenames) {
	import std.algorithm.searching : canFind;
	final switch(ilf.ruleSelection) {
		case InlineFragmentEnum.TDS:
			goto case InlineFragmentEnum.TS;
		case InlineFragmentEnum.TS:
			return canFind(typenames, ilf.tc.value) ? ilf.ss.sel : null;
		case InlineFragmentEnum.DS:
			return ilf.ss.sel;
		case InlineFragmentEnum.S:
			return ilf.ss.sel;
	}
}

FieldRange fieldRange(OperationDefinition od, Document doc,
		string[] typenames)
{
	return FieldRange(od.accessNN!(["ss", "sel"]), doc, typenames);
}

FieldRange fieldRange(SelectionSet ss, Document doc, string[] typenames) {
	return FieldRange(ss.sel, doc, typenames);
}

FieldRangeItem[] fieldRangeArr(Selections sel, Document doc,
		string[] typenames)
{
	import std.array : array;
	return FieldRange(sel, doc, typenames).array;
}

struct OpDefRangeItem {
	Document doc;
	Definition def;

	FieldRange fieldRange(string[] typenames) {
		return .fieldRange(accessNN!(["op", "ss"])(this.def), this.doc,
				typenames
			);
	}
}

struct OpDefRange {
	Document doc;
	Definitions defs;

	this(Document doc) {
		this.doc = doc;
		this.defs = doc.defs;
		this.advance();
	}

	private void advance() {
		while(this.defs !is null
				&& this.defs.def.ruleSelection != DefinitionEnum.O)
		{
			this.defs = this.defs.follow;
		}
	}

	@property bool empty() const {
		return this.defs is null;
	}

	@property OpDefRangeItem front() {
		return OpDefRangeItem(this.doc, this.defs.def);
	}

	void popFront() {
		this.defs = this.defs.follow;
		this.advance();
	}

	@property typeof(this) save() {
		OpDefRange ret;
		ret.doc = this.doc;
		ret.defs = this.defs;
		return ret;
	}
}

OpDefRange opDefRange(Document doc) {
	return OpDefRange(doc);
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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
	auto p = Parser(l);
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
	auto fss = r.front.selectionSet();
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

unittest {
	import std.format : format;
	import std.stdio;

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
	auto p = Parser(l);
	auto d = p.parseDocument();

	auto nn = ["hello", "name", "zzzz", "age", "args"];
	size_t cnt = 0;
	foreach(it; opDefRange(d)) {
		++cnt;
		long idx;
		foreach(jt; it.fieldRange()) {
			writef("%s(", jt.name);
			foreach(var; jt.arguments()) {
				writef("%s, ", var.name());
			}
			writeln(")");
			foreach(kt; jt.selectionSet()) {
				writeln("\t", kt.name);
				assert(kt.name == nn[idx],
						format("%s == %d(%s)", kt.name, idx, nn[idx])
					);
				++idx;
			}
		}
	}
	assert(cnt == 1);
}
