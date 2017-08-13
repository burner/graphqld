module parsertests;

import lexer;
import parser;

unittest {
	string s = 
`{
  query name {
	  foo
  }
}`;
	auto l = Lexer(s);
	auto p = Parser(l);
	auto d = p.parseDocument();
}

__EOF__

unittest {
	string s = `
{
  query human {
    name
    height
  }
}`;
	auto l = Lexer(s);
	auto p = Parser(l);
	auto d = p.parseDocument();
}

unittest {
	string s = `
{
  query human(id: "1000") {
    name
    height
  }
}`;
	auto l = Lexer(s);
	auto p = Parser(l);
	auto d = p.parseDocument();
}
