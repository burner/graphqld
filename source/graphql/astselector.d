module graphql.astselector;

import std.array : back, empty, front, popBack;
import std.exception : enforce;

import graphql.ast;
import graphql.visitor : ConstVisitor;

/* Sometimes you need to select a specific part of the ast,
this module allows to do that.
*/

@safe:

const(T) astSelect(T,S)(const(S) input, string path) {
	auto astsel = new AstSelector(path);
	static if(is(S == Document)) {
		return astsel.get!T(input, input);
	} else {
		return astsel.get!T(input);
	}
}

const(T) astSelect(T,S)(const(S) input, const(Document) doc, string path) {
	auto astsel = new AstSelector(path);
	return astsel.get!T(input, doc);
}

class AstSelector : ConstVisitor {
	import std.format : format;
	import std.typecons : rebindable, Rebindable;
	alias enter = ConstVisitor.enter;
	alias exit = ConstVisitor.exit;
	alias accept = ConstVisitor.accept;

	Rebindable!(const(Document)) document;

	const(string[]) sp;
	size_t spPos;

	Rebindable!(const(Node)) result;
	Rebindable!(const(Node))[] stack;

	this(string p) {
		import std.string : split;
		this.sp = p.split('.');
	}

	const(T) get(T,S)(const(S) input, const(Document) doc) {
		this.document = doc;
		this.accept(input);
		return cast(typeof(return))this.result.get();
	}

	const(T) get(T,S)(const(S) input) {
		return this.get!T(input, null);
	}

	bool takeName(string name, const(Node) nn) {
		if(this.spPos < this.sp.length && name == this.sp[this.spPos]) {
			this.stack ~= rebindable(nn);
		} else {
			return false;
		}

		++this.spPos;
		if(this.spPos == this.sp.length) {
			enforce(this.result.get() is null);
			this.result = this.stack.back;
		}
		return true;
	}

	void popStack(bool shouldPop) {
		enforce(this.stack.length == this.spPos,
				format("stack.length %s, spPos %s", this.stack.length,
					this.spPos));
		enforce(shouldPop ? this.stack.length > 0 : true,
				"should pop put stack is empty");
		if(shouldPop) {
			this.stack.popBack();
			--this.spPos;
		}
	}

	override void accept(const(OperationDefinition) obj) {
		bool shouldPop;
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_VD:
				shouldPop = this.takeName(obj.name.value, obj);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				this.popStack(shouldPop);
				break;
			case OperationDefinitionEnum.OT_N_V:
				shouldPop = this.takeName(obj.name.value, obj);
				obj.vd.visit(this);
				obj.ss.visit(this);
				this.popStack(shouldPop);
				break;
			case OperationDefinitionEnum.OT_N_D:
				shouldPop = this.takeName(obj.name.value, obj);
				obj.d.visit(this);
				obj.ss.visit(this);
				this.popStack(shouldPop);
				break;
			case OperationDefinitionEnum.OT_N:
				shouldPop = this.takeName(obj.name.value, obj);
				obj.ss.visit(this);
				this.popStack(shouldPop);
				break;
			case OperationDefinitionEnum.OT_VD:
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_V:
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_D:
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT:
				obj.ss.visit(this);
				break;
		}
	}

	override void accept(const(Field) obj) {
		bool shouldPop;

		scope(exit) {
			this.popStack(shouldPop);
		}

		final switch(obj.ruleSelection) {
			case FieldEnum.FADS:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.args.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FAS:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.args.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FAD:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.args.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FDS:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case FieldEnum.FS:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.ss.visit(this);
				break;
			case FieldEnum.FD:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FA:
				shouldPop = this.takeName(obj.name.name.value, obj);
				obj.args.visit(this);
				break;
			case FieldEnum.F:
				shouldPop = this.takeName(obj.name.name.value, obj);
				break;
		}
	}

	override void accept(const(InlineFragment) obj) {
		bool shouldPop;
		final switch(obj.ruleSelection) {
			case InlineFragmentEnum.TDS:
				shouldPop = this.takeName(obj.tc.value, obj);
				obj.tc.visit(this);
				obj.dirs.visit(this);
				obj.ss.visit(this);
				this.popStack(shouldPop);
				break;
			case InlineFragmentEnum.TS:
				shouldPop = this.takeName(obj.tc.value, obj);
				obj.ss.visit(this);
				this.popStack(shouldPop);
				break;
			case InlineFragmentEnum.DS:
				obj.dirs.visit(this);
				obj.ss.visit(this);
				break;
			case InlineFragmentEnum.S:
				obj.ss.visit(this);
				break;
		}
	}

	override void accept(const(FragmentSpread) fragSpread) {
		import graphql.builder : findFragment;
		const(FragmentDefinition) frag = findFragment(this.document.get(),
				fragSpread.name.value
			);
		bool shouldPop = this.takeName(fragSpread.name.value, frag);
		frag.visit(this);
		this.popStack(shouldPop);
	}
}

import graphql.helper : lexAndParse;

unittest {
	string s = `
query foo {
	a
}`;

	auto d = lexAndParse(s);
	auto foo = d.astSelect!OperationDefinition("foo");
	assert(foo !is null);
	assert(foo.name.value == "foo");
}

unittest {
	string s = `
query foo {
	a
}

mutation bar {
	b
}

`;

	auto d = lexAndParse(s);
	auto bar = d.astSelect!OperationDefinition("bar");
	assert(bar !is null);
	assert(bar.name.value == "bar");
}

unittest {
	string s = `
query foo {
	a {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto a = d.astSelect!Field("foo.a");
	assert(a !is null);
	assert(a.name.name.value == "a");
}

unittest {
	string s = `
query foo {
	a {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto a = d.astSelect!Document("foo.a");
	assert(a is null);
}

unittest {
	string s = `
query foo {
	a {
		b
	}
}

mutation a {
	foo {
		b
	}
}

`;

	auto d = lexAndParse(s);
	auto foo = d.astSelect!Field("a.foo");
	assert(foo !is null);
}

unittest {
	string s = `
fragment Foo on Bar {
	a @skip(if: true)
}

query foo {
	...Foo
}

`;

	auto d = lexAndParse(s);
	auto a = d.astSelect!Field("foo.a");
	assert(a !is null);
	assert(a.dirs !is null);
	assert(a.dirs.dir.name.value == "skip");
}
