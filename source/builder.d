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

Selections resolveFragments(ref FixedSizeArray!(Selections,32) stack, 
		Document doc) 
{
	if(stack.back.sel.ruleSelection == SelectionEnum.Field) {
		return stack.back;
	} else if(stack.back.sel.ruleSelection == SelectionEnum.Spread) {
		Fragment f = findFragment(doc, stack.back.sel.frag.name);
		enforce(f !is null);
		Selections fs = f.ss.sel;
		stack.insertBack(fs);

		Selections ret = resolveFragments(stack, doc);
		return ret;
	}
	assert(false);
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
	Definitions defs;

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
		return FieldRange(this.f.ss.sel, this.defs);
	}
}

struct FieldRange {
	FixedSizeArray!(Selections,32) cur;
	Definitions defs;

	this(Selections cur, Definitions defs) {
		this.defs = defs;
		this.cur.insertBack(cur);
	}

	this(ref FieldRange old) {
		this.cur = old.cur;
		this.defs = defs;
	}

	@property bool empty() const pure {
		return this.cur.length == 0;
	}

	@property FieldRangeItem front() {
		return FieldRangeItem(this.cur.back.sel.field, this.defs);
	}

	void popFront() {
		this.cur.back = this.cur.back.follow;
		if(this.cur.back is null) {
			this.cur.removeBack();
		}
	}

	@property FieldRange save() {
		return FieldRange(this);
	}
}

FieldRange fieldRange(OperationDefinition od, Definitions defs) {
	return FieldRange(od.ss.sel, defs);
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

	FieldRange r = fieldRange(d.defs.def.op, d.defs);
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
