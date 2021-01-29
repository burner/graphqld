module graphql.builder;

import std.experimental.allocator;
import std.experimental.logger : logf;
import std.experimental.allocator.mallocator : Mallocator;
import std.exception : enforce;
import std.format : format;

import vibe.data.json;

import fixedsizearray;

import graphql.argumentextractor;
import graphql.helper;
import graphql.ast;
import graphql.parser;
import graphql.lexer;
import graphql.directives;

@safe:

const(FragmentDefinition) findFragment(const(Document) doc, string name) {
	import std.algorithm.searching : canFind;
	import std.experimental.logger : logf;
	enforce(doc !is null);
	const(Definitions) cur = doc.defs;
	return findFragmentImpl(cur, name);
}

const(FragmentDefinition) findFragmentImpl(const(Definitions) cur,
		string name)
{
	if(cur is null) {
		return null;
	} else {
		enforce(cur.def !is null);
		if(cur.def.ruleSelection == DefinitionEnum.F) {
			enforce(cur.def.frag !is null);
			if(cur.def.frag.name.value == name) {
				return cur.def.frag;
			}
		}
		return findFragmentImpl(cur.follow, name);
	}
}

Selections findFragment(Document doc, string name, string[] typenames) {
	import std.algorithm.searching : canFind;
	import std.experimental.logger : logf;
	if(doc is null) {
		return null;
	}
	Definitions cur = doc.defs;
	while(cur !is null) {
		enforce(cur.def !is null);
		if(cur.def.ruleSelection == DefinitionEnum.F) {
			enforce(cur.def.frag !is null);
			//logf("%s == %s && %s in %s", cur.def.frag.name.value, name,
			//		cur.def.frag.tc.value, typenames
			//	);
			if(cur.def.frag.name.value == name
					&& canFind(typenames, cur.def.frag.tc.value))
			{
				//logf("found it");
				return cur.def.frag.ss.sel;
			} else {
				//logf("not found");
			}
		}
		cur = cur.follow;
	}

	//logf("search failed");
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

	const f = findFragment(d, "fooo", ["user"]);
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

	auto f = findFragment(d, "fooo", ["Hero"]);
	assert(f !is null);
	assert(f.sel.field.name.name.value == "name");

	f = findFragment(d, "fooo", ["Villian"]);
	assert(f is null);
}

struct FieldRangeItem {
	import std.array : empty;
	Field f;
	Document doc;

	@property string name() {
		return f.name.name.value;
		//return f.name.aka.value.empty ? f.name.name.value : f.name.aka.value;
	}

	@property string aka() {
		return f.name.aka.value;
	}
}

struct FieldRange {
	FixedSizeArray!(Selections,32) cur;
	Document doc;
	string[] typenames;
	Json vars;

	this(Selections sels, Document doc, string[] typenames, Json vars) {
		this.doc = doc;
		this.typenames = typenames;
		this.vars = vars;
		this.cur.insertBack(sels);
		this.build();
		//this.test();
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

	bool directivesAllowContinue(Selection sel, Json vars) {
		Directives dirs;
		final switch(sel.ruleSelection) {
			case SelectionEnum.Field:
				dirs = sel.field.dirs;
				break;
			case SelectionEnum.Spread:
				dirs = sel.frag.dirs;
				break;
			case SelectionEnum.IFrag:
				dirs = sel.ifrag.dirs;
				break;
		}
		return continueAfterDirectives(dirs, vars);
	}

	void popFront() {
		this.cur.back = this.cur.back.follow;
		this.build();
	}

	void build() {
		if(this.cur.empty) {
			return;
		}
		if(this.cur.back !is null
				&& directivesAllowContinue(this.cur.back.sel, vars))
		{
			const SelectionEnum se = this.cur.back.sel.ruleSelection;
			if(se == SelectionEnum.Field) {
				return;
			} else {
				Selections follow = this.cur.back.follow;
				Selections f = se == SelectionEnum.Spread
					? findFragment(doc, this.cur.back.sel.frag.name.value,
							this.typenames
						)
					: resolveInlineFragment(this.cur.back.sel.ifrag,
							this.typenames
						);

				this.cur.removeBack();

				if(follow !is null) {
					this.cur.insertBack(follow);
					this.build();
					//this.test();
				}
				if(f !is null) {
					this.cur.insertBack(f);
					this.build();
					//this.test();
				}
			}
		} else if(this.cur.back is null) {
			this.cur.removeBack();
			this.build();
		} else {
			this.cur.back = this.cur.back.follow;
			this.build();
		}
	}

	/*void popFront() {
		this.cur.back = this.cur.back.follow;
		this.build();
		this.test();
	}

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
			Selections f =
				this.cur.back.sel.ruleSelection == SelectionEnum.Spread
					? findFragment(doc, this.cur.back.sel.frag.name.value,
							this.typenames
						)
					: resolveInlineFragment(this.cur.back.sel.ifrag,
							this.typenames
						);

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
	}*/
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
	return FieldRange(od.accessNN!(["ss", "sel"]), doc, typenames,
			Json.emptyObject());
}

FieldRange fieldRange(SelectionSet ss, Document doc, string[] typenames) {
	return FieldRange(ss.sel, doc, typenames, Json.emptyObject());
}

FieldRangeItem[] fieldRangeArr(Selections sel, Document doc,
		string[] typenames, Json vars)
{
	import std.array : array;
	return FieldRange(sel, doc, typenames, vars).array;
}

FieldRangeItem[] fieldRangeArr(Selections sel, Document doc,
		string[] typenames)
{
	import std.array : array;
	return fieldRangeArr(sel, doc, typenames, Json.emptyObject());
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

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	const f = findFragment(d, "foo", ["User"]);
	assert(f !is null);

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	const f = findFragment(d, "foo", ["User"]);
	assert(f !is null);

	const f2 = findFragment(d, "bar", ["User"]);
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	const f = findFragment(d, "foo", ["User"]);
	assert(f !is null);

	const f2 = findFragment(d, "bar", ["User"]);
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	const f = findFragment(d, "foo", ["User"]);
	assert(f !is null);

	const f2 = findFragment(d, "bar", ["User"]);
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	const f = findFragment(d, "foo", ["User"]);
	assert(f !is null);

	const f2 = findFragment(d, "bar", ["User"]);
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	const f = findFragment(d, "foo", ["User"]);
	assert(f !is null);

	const f2 = findFragment(d, "bar", ["User"]);
	assert(f2 !is null);

	FieldRange r = fieldRange(d.defs.def.op, d, ["User"]);
	assert(!r.empty);
	assert(r.front.name == "user");
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

	immutable auto nn = ["hello", "name", "zzzz", "age", "args"];
	size_t cnt = 0;
	foreach(it; opDefRange(d)) {
		++cnt;
		long idx;
		foreach(jt; it.fieldRange(["User"])) {
		}
	}
	assert(cnt == 1);
}
