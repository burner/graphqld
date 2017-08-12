module parsertests;

import lexer;
import parser;

unittest {
	string s = `
{
  human(id: "1000") {
    name
    height
  }
}`;
	auto l = Lexer(s);
	auto p = Parser(l);
	auto d = p.parseDefinitions();
}
