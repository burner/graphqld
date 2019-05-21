module graphql.astselector;

import std.array : back, empty, front, popBack;

import graphql.ast;
import graphql.visitor : ConstVisitor;

@safe:

const(T) astSelect(T,S)(const(S) doc, string path) {
	auto astsel = new AstSelector(path);
	return astsel.get!T(doc);
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

	const(T) get(T,S)(const(S) input) {
		static if(typeof(S) == Document) {
			this.document = input;
		}
		this.accept(input);
		return cast(typeof(return))this.result.get();
	}

	void takeName(string name, const(Node) nn) {
		if(this.spPos < this.sp.length && name == this.sp[this.spPos]) {
			this.stack ~= rebindable(nn);
		} else {
			return;
		}

		++this.spPos;
		if(this.spPos == this.sp.length) {
			this.result = this.stack.back;
		}
	}

	override void accept(const(OperationDefinition) obj) {
		final switch(obj.ruleSelection) {
			case OperationDefinitionEnum.SelSet:
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_VD:
				this.takeName(obj.name.value, obj);
				obj.vd.visit(this);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_V:
				this.takeName(obj.name.value, obj);
				obj.vd.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N_D:
				this.takeName(obj.name.value, obj);
				obj.d.visit(this);
				obj.ss.visit(this);
				break;
			case OperationDefinitionEnum.OT_N:
				this.takeName(obj.name.value, obj);
				obj.ss.visit(this);
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
