module builder;

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
