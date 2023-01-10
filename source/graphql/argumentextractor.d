module graphql.argumentextractor;

import std.array : back, empty, popBack;
import std.conv : to;
import std.format : format;
import std.exception : enforce;
import std.stdio : writefln;

import vibe.data.json;

import graphql.visitor;
import graphql.ast;
import graphql.builder : FieldRangeItem;

@safe:

Json getArguments(Selections sels, Json variables) {
	//writefln("%s", variables);
	auto ae = new ArgumentExtractor(variables);
	ae.accept(cast(const(Selections))sels);
	return ae.arguments;
}

Json getArguments(InlineFragment ilf, Json variables) {
	auto ae = new ArgumentExtractor(variables);
	ae.accept(cast(const(InlineFragment))ilf);
	return ae.arguments;
}

Json getArguments(FragmentSpread fs, Json variables) {
	auto ae = new ArgumentExtractor(variables);
	ae.accept(cast(const(FragmentSpread))fs);
	return ae.arguments;
}

Json getArguments(const(Directive) dir, Json variables) {
	auto ae = new ArgumentExtractor(variables);
	ae.accept(dir);
	return ae.arguments;
}

Json getArguments(FieldRangeItem item, Json variables) {
	auto ae = new ArgumentExtractor(variables);
	ae.accept(cast(const(Field))item.f);
	return ae.arguments;
}

Json getArguments(Field field, Json variables) {
	auto ae = new ArgumentExtractor(variables);
	ae.accept(cast(const(Field))field);
	return ae.arguments;
}

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
		//logf("%s", this.arguments);
	}

	override void accept(const(Field) obj) {
		final switch(obj.ruleSelection) {
			case FieldEnum.FADS:
				obj.args.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FAS:
				obj.args.visit(this);
				break;
			case FieldEnum.FAD:
				obj.args.visit(this);
				obj.dirs.visit(this);
				break;
			case FieldEnum.FDS:
				obj.dirs.visit(this);
				break;
			case FieldEnum.FS:
				break;
			case FieldEnum.FD:
				obj.dirs.visit(this);
				break;
			case FieldEnum.FA:
				obj.args.visit(this);
				break;
			case FieldEnum.F:
				break;
		}
	}

	override void enter(const(Argument) arg) {
		this.curNames ~= arg.name.value;
	}

	override void exit(const(Argument) arg) {
		this.curNames.popBack();
	}

	override void accept(const(ValueOrVariable) obj) {
		import graphql.validation.exception : VariablesUseException;
		final switch(obj.ruleSelection) {
			case ValueOrVariableEnum.Val:
				obj.val.visit(this);
				break;
			case ValueOrVariableEnum.Var:
				string varName = obj.var.name.value;
				enforce!VariablesUseException(varName in this.variables,
						format("Variable with name '%s' required available '%s'",
							varName, this.variables)
					);
				//writefln("%s %s", varName, this.variables);
				this.assign(this.variables[varName]);
				break;
		}
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
			case ValueEnum.N:
				this.assign(Json(null));
				break;
		}
	}
}

import graphql.helper : lexAndParse;

unittest {
	string s = `
{
	starships(overSize: 10) {
		name
	}
}
`;

	const auto d = lexAndParse(s);
}
