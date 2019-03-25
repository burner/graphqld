module schema.helper;

import schema.types;

@safe:

string toString(Con)(ref GQLDType!(Con)[string] all) {
	import std.array : appender;
	import std.format : formattedWrite;
	auto app = appender!string();
	foreach(key, value; all) {
		formattedWrite(app, "%20s: %s\n", key, value.toString());
	}
	return app.data;
}
