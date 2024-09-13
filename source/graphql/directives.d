module graphql.directives;

__EOF__

import std.format : format;

import vibe.data.json;

import graphql.ast;
import graphql.helper;
import graphql.astselector;

@safe:

private enum Include {
	undefined = 0,
	yes = 1,
	no = 4
}

private enum Skip {
	undefined = 0,
	yes = 1,
	no = 4
}

T add(T)(T a, T b) {
	immutable int ai = a;
	immutable int bi = b;
	int r = ai + bi;
	if(r == 0) {
		return cast(T)r;
	} else if(r == 1 || r == 2) {
		return T.yes;
	} else if(r == 4 || r == 8) {
		return T.no;
	} else {
		throw new Exception(format("join conflict between '%s' and '%s'",
				a, b));
	}
}

struct SkipInclude {
	Include include;
	Skip skip;

	SkipInclude join(SkipInclude other) {
		SkipInclude ret = this;
		ret.include = add(ret.include, other.include);
		ret.skip = add(ret.skip, other.skip);
		return ret;
	}
}

bool continueAfterDirectives(const(Directives) dirs, Json vars) {
	import graphql.validation.exception;

	SkipInclude si = extractSkipInclude(dirs, vars);
	if(si.include == Include.undefined && si.skip == Skip.undefined) {
		return true;
	} else if(si.include == Include.no && si.skip == Skip.undefined) {
		return false;
	} else if(si.include == Include.yes
			&& (si.skip == Skip.undefined || si.skip == Skip.no))
	{
		return true;
	} else if(si.include == Include.undefined && si.skip == Skip.no) {
		return true;
	} else if(si.include == Include.undefined && si.skip == Skip.yes) {
		return false;
	}
	throw new ContradictingDirectives(format(
			"include %s and skip %s contridict each other", si.include,
			si.skip), __FILE__, __LINE__);
}

SkipInclude extractSkipInclude(const(Directives) dirs, Json vars) {
	import graphql.argumentextractor;

	SkipInclude ret;
	if(dirs is null) {
		return ret;
	}
	Json args = getArguments(dirs.dir, vars);
	immutable bool if_ = args.extract!bool("if");
	ret.include = dirs.dir.name.value == "include"
		? if_
			? Include.yes
			: Include.no
		: Include.undefined;
	ret.skip = dirs.dir.name.value == "skip"
		? if_
			? Skip.yes
			: Skip.no
		: Skip.undefined;

	return ret.join(extractSkipInclude(dirs.follow, vars));
}

unittest {
	string q = `
query a($s: boolean) {
	starships(overSize: 10) {
		name @include(if: $s)
		crew @skip(if: $s) {
		id
		}
	}
}`;

	Json vars = parseJsonString(`{ "s": false }`);

	const(Document) doc = lexAndParse(q);
	assert(doc !is null);
	{
		auto name = astSelect!Field(doc, "a.starships.name");
		assert(name !is null);

		SkipInclude si = extractSkipInclude(name.dirs, vars);
		assert(si.include == Include.no, format("%s", si.include));
		assert(si.skip == Skip.undefined, format("%s", si.skip));
		assert(!continueAfterDirectives(name.dirs, vars));
	}
	{
		auto crew = astSelect!Field(doc, "a.starships.crew");
		assert(crew !is null);

		immutable SkipInclude si = extractSkipInclude(crew.dirs, vars);
		assert(si.include == Include.undefined);
		assert(si.skip == Skip.no);
		assert(continueAfterDirectives(crew.dirs, vars));
	}
}
