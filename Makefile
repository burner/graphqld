handWrittenFiles=source/graphql/argumentextractor.d \
	source/graphql/constants.d \
	source/graphql/helper.d \
	source/graphql/testschema.d \
	source/graphql/parsertests.d \
	source/graphql/tokenmodule.d \
	source/graphql/uda.d \
	source/graphql/builder.d \
	source/graphql/graphql.d \
	source/graphql/traits.d \
	source/graphql/schema/directives.d \
	source/graphql/schema/helper.d \
	source/graphql/schema/introspectiontypes.d \
	source/graphql/schema/package.d \
	source/graphql/schema/resolver.d \
	source/graphql/schema/typeconversions.d \
	source/graphql/schema/types.d \
	source/graphql/validation/exception.d \
	source/graphql/validation/querybased.d \
	source/graphql/validation/schemabased.d \
	source/graphql/astselector.d \
	source/graphql/directives.d

gen:
	../Darser/darser --dod -i graphql.yaml \
	-a source/graphql/ast.d -b "graphql" \
	-p source/graphql/parser.d -q "graphql" \
	-e source/graphql/exception.d -g "graphql" \
	-v source/graphql/visitor.d -w "graphql" \
	-t source/graphql/treevisitor.d -r "graphql" \
	-u "graphql" -s "graphql" \
	--safe

	cat exeexcp >> source/graphql/exception.d

style_lint:
	#@echo "Enforce braces on the same line"
	#grep -nrE '^[\t ]*{' $$(find source -name '*.d'); test $$? -eq 1

	@echo "Check for whitespace indentation"
	grep -nr '^[ ]' source ; test $$? -eq 1

	@echo "Enforce whitespace before opening parenthesis"
	grep -nrE "\<(for|foreach|foreach_reverse|if|while|switch|catch|version) \(" $$(find source -name '*.d') ; test $$? -eq 1

	@echo "Enforce no whitespace after opening parenthesis"
	grep -nrE "\<(version) \( " $$(find source -name '*.d') ; test $$? -eq 1

	@echo "Enforce whitespace between colon(:) for import statements (doesn't catch everything)"
	grep -nr 'import [^/,=]*:.*;' $$(find source -name '*.d') | grep -vE "import ([^ ]+) :\s"; test $$? -eq 1

	@echo "Check for package wide std.algorithm imports"
	grep -nr 'import std.algorithm : ' $$(find source -name '*.d') ; test $$? -eq 1

	@echo "Enforce no space between assert and the opening brace, i.e. assert("
	grep -nrE 'assert \(' $$(find source -name '*.d') ; test $$? -eq 1

	@echo "Enforce space between a .. b"
	grep -nrE '[[:alnum:]][.][.][[:alnum:]]|[[:alnum:]] [.][.][[:alnum:]]|[[:alnum:]][.][.] [[:alnum:]]' $$(find source -name '*.d' | grep -vE 'std/string.d|std/uni.d') ; test $$? -eq 1

	@echo "Enforce space between binary operators"
	grep -nrE "[[:alnum:]](==|!=|<=|<<|>>|>>>|^^)[[:alnum:]]|[[:alnum:]] (==|!=|<=|<<|>>|>>>|^^)[[:alnum:]]|[[:alnum:]](==|!=|<=|<<|>>|>>>|^^) [[:alnum:]]" $$(find source -name '*.d'); test $$? -eq 1

	@echo "Check line length"
	grep -nr '.\{81\}' $(handWrittenFiles) ; test $$? -eq 1
