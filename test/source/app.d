import vibe.vibe;

void main() {
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	runApplication();
}

void hello(HTTPServerRequest req, HTTPServerResponse res) {
	import std.stdio;
	import parser;
	import builder;
	import lexer;
	import ast;
	import treevisitor;
	writeln(req.toString());
	writeln(cast(char[])req.bodyReader.peek());
	Json j = req.json;
	string toParse;
	if("query" in j) {
		toParse = j["query"].get!string();
	} else {
		toParse = j["mutation"].get!string();
	}
	writeln(toParse);
	auto l = Lexer(toParse);
	auto p = Parser(l);
	Document d;
	try {
		d = p.parseDocument();
		writeln("Parse worked");
	} catch(Throwable e) {
		writeln(e.toString());
		res.writeBody("Failed to parse " ~ e.toString());
		return;
	}

	auto tv = new TreeVisitor(0);
	tv.accept(cast(const(Document))d);

	auto dr = opDefRange(d);
	writeln(dr.empty);
	foreach(it; dr) {
		writeln(it.fieldRange().empty);
		foreach(jt; it.fieldRange()) {
			writeln(jt.hasSelectionSet());
			if(jt.hasSelectionSet()) {
				foreach(kt; jt.selectionSet()) {
					writeln(kt.name());
				}
			}
		}
	}

	res.writeBody(toParse);
}
