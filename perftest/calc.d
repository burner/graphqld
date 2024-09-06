import std;

string[] strs =
[ "Command being timed:"
, "Percent of CPU this job got:"
];

string[] floats =
[ "User time (seconds):"
, "System time (seconds):"
];

string[] floats2 =
[ "Elapsed (wall clock) time (h:mm:ss or m:ss):"
];

string[] longs =
[ "Average shared text size (kbytes):"
, "Average unshared data size (kbytes):"
, "Average stack size (kbytes):"
, "Average total size (kbytes):"
, "Maximum resident set size (kbytes):"
, "Average resident set size (kbytes):"
, "Major (requiring I/O) page faults:"
, "Minor (reclaiming a frame) page faults:"
, "Voluntary context switches:"
, "Involuntary context switches:"
, "Swaps:"
, "File system inputs:"
, "File system outputs:"
, "Socket messages sent:"
, "Socket messages received:"
, "Signals delivered:"
, "Page size (bytes):"
, "Exit status:"
];

string[] perf =
[ "cache-references:u"
, "cache-misses:u"
, "cycles:u"
, "instructions:u"
, "branches:u"
, "faults:u"
, "migrations:u"
, "L1-dcache-loads:u"
, "L1-dcache-load-misses:u"
, "ic_tag_hit_miss.all_instruction_cache_accesses:u"
];

double wallClock(string s) {
	s = s.strip();
	s = s[3 .. $];
	return to!(double)(s);
}

void main(string[] args) {
	long[string] longV;
	double[string] floatV;

	string[] lines = readText("out")
		.splitter("\n")
		.map!(l => l.strip())
		.filter!(l => !l.empty)
		.array;
	o: foreach(l; lines) {
		foreach(p; perf) {
			ptrdiff_t i = l.indexOf(p);
			if(i != -1) {
				long v = l[0 .. i].strip().to!(long)();
				if(p in longV) {
					longV[p] += v;
				} else {
					longV[p] = v;
				}
				continue o;
			}
		}
		foreach(p; longs) {
			ptrdiff_t i = l.indexOf(p);
			if(i != -1) {
				long v = l[i + p.length .. $].strip().to!(long)();
				if(p in longV) {
					longV[p] += v;
				} else {
					longV[p] = v;
				}
				continue o;
			}
		}
		foreach(string p; floats) {
			ptrdiff_t i = l.indexOf(p);
			if(i != -1) {
				string s = l[0 .. i].strip();
				if(s.empty) {
					continue o;
				}
				double v = s.to!(double)();
				if(p in floatV) {
					floatV[p] += v;
				} else {
					floatV[p] = v;
				}
				continue o;
			}
		}
		foreach(string p; floats2) {
			ptrdiff_t i = l.indexOf(p);
			if(i != -1) {
				string s = l[p.length .. $].strip();
				if(s.empty) {
					continue o;
				}
				double v = wallClock(s);
				if(p in floatV) {
					floatV[p] += v;
				} else {
					floatV[p] = v;
				}
				continue o;
			}
		}
	}
	JSONValue j;
	foreach(k, v; longV) {
		j[k] = v;
	}
	foreach(k, v; floatV) {
		j[k] = v;
	}
	j["l1misses"] = ((cast(double)longV["L1-dcache-load-misses:u"] /
			longV["L1-dcache-loads:u"]) * 100);
	j["cache_misses"] = ((cast(double)longV["cache-misses:u"] /
			longV["cache-references:u"]) * 100);
	auto f = File(args[1], "w");
	f.writeln(j.toPrettyString());
}
