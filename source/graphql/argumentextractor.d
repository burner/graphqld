module graphql.argumentextractor;

import std.array : back, empty, popBack;
import std.conv : to;
import std.format : format;
import std.exception : enforce;

import vibe.data.json;

import graphql.visitor;
import graphql.ast;

@safe:

class ArgumentExtractor : ConstVisitor {
	alias enter = ConstVisitor.enter;
	alias exit = ConstVisitor.exit;
	alias accept = ConstVisitor.accept;

	Json arguments;
	Json variables;

	string[] curNames;

	this(Json variables) {
		this.variables = variables;
		this.arguments = Json.emptyObject();
	}

	void assign(Json toAssign) @trusted {
		Json* arg = &this.arguments;
		//logf("%(%s.%) %s %s", this.curNames, this.arguments, toAssign);
		assert(!this.curNames.empty);
		foreach(idx; 0 .. this.curNames.length - 1) {
			enforce(arg !is null);
			arg = &((*arg)[this.curNames[idx]]);
		}

		enforce(arg !is null);

		if(this.curNames.back in (*arg)
				&& ((*arg)[this.curNames.back]).type == Json.Type.array)
		{
			((*arg)[this.curNames.back]) ~= toAssign;
		} else if((*arg).type == Json.Type.object) {
			((*arg)[this.curNames.back]) = toAssign;
		} else {
			((*arg)[this.curNames.back]) = toAssign;
		}
	}

	override void enter(const(Argument) arg) {
		this.curNames ~= arg.name.value;
	}

	override void exit(const(Argument) arg) {
		this.curNames.popBack();
	}

	override void accept(const(ObjectValues) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ObjectValuesEnum.V:
				this.curNames ~= obj.name.value;
				obj.val.visit(this);
				this.curNames.popBack();
				break;
			case ObjectValuesEnum.Vsc:
				this.curNames ~= obj.name.value;
				obj.val.visit(this);
				this.curNames.popBack();
				obj.follow.visit(this);
				break;
			case ObjectValuesEnum.Vs:
				this.curNames ~= obj.name.value;
				obj.val.visit(this);
				this.curNames.popBack();
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	override void enter(const(Variable) var) {
		string varName = var.name.value;
		enforce(varName in this.variables,
				format("Variable with name %s required", varName)
			);
		this.assign(this.variables[varName]);
	}

	override void enter(const(Value) val) {
		final switch(val.ruleSelection) {
			case ValueEnum.STR:
				this.assign(Json(val.tok.value));
				break;
			case ValueEnum.INT:
				this.assign(Json(to!long(val.tok.value)));
				break;
			case ValueEnum.FLOAT:
				this.assign(Json(to!double(val.tok.value)));
				break;
			case ValueEnum.T:
				this.assign(Json(true));
				break;
			case ValueEnum.F:
				this.assign(Json(false));
				break;
			case ValueEnum.ARR:
				this.assign(Json.emptyArray());
				break;
			case ValueEnum.O:
				this.assign(Json.emptyObject());
				break;
			case ValueEnum.E:
				this.assign(Json(val.tok.value));
				break;
		}
	}
}

