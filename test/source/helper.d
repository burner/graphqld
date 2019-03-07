module helper;
import vibe.data.json;

@safe:

string firstCharUpperCase(string input) {
	import std.conv : to;
	import std.uni : isUpper, toUpper;
	import std.array : front, popFront;
	if(isUpper(input.front)) {
		return input;
	}

	dchar f = input.front;
	input.popFront();

	return to!string(toUpper(f)) ~ input;
}

Json returnTemplate() {
	Json ret = Json.emptyObject();
	ret["data"] = Json.emptyObject();
	ret["error"] = Json.emptyArray();
	return ret;
}

void insertPayload(ref Json result, string field, Json data) {
	import std.algorithm.searching : canFind;
	import std.exception : enforce;
	enum d = "data";
	enum e = "error";
	if(d in data) {
		enforce(result[d].type == Json.Type.object);
		result[d][field] = data[d];
	}
	if(e in data) {
		enforce(result[e].type == Json.Type.array);
		if(!canFind(result[e].byValue(), data[e])) {
			result[e] ~= data[e];
		}
	}
}

bool isScalar(ref const(Json) data) {
	return data.type == Json.Type.bigInt
			|| data.type == Json.Type.bool_
			|| data.type == Json.Type.float_
			|| data.type == Json.Type.int_
			|| data.type == Json.Type.string;
}

bool dataIsEmpty(ref const(Json) data) {
	import std.experimental.logger;
	if(data.type == Json.Type.object) {
		foreach(key, value; data.byKeyValue()) {
			if(key != "error" && !value.dataIsEmpty()) {
				return false;
			}
		}
	} else if(data.type == Json.Type.null_
			|| data.type == Json.Type.undefined
		)
	{
		return true;
	} else if(data.type == Json.Type.array) {
		foreach(item; data.byValue()) {
			if(!item.dataIsEmpty()) {
				return false;
			}
		}
	} else if(data.type == Json.Type.bigInt
			|| data.type == Json.Type.bool_
			|| data.type == Json.Type.float_
			|| data.type == Json.Type.int_
			|| data.type == Json.Type.string
		)
	{
		return false;
	}

	return true;
}

unittest {
	string t = `{
              "kind": {},
              "fields": null,
              "name": {}
            }`;
	Json j = parseJsonString(t);
	assert(j.dataIsEmpty());
}
