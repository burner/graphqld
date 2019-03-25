gen:
	../Darser/darser -i graphql.yaml \
	-a source/graphql/ast.d -b "graphql" \
	-p source/graphql/parser.d -q "graphql" \
	-e source/graphql/exception.d -g "graphql" \
	-v source/graphql/visitor.d -w "graphql" \
	-t source/graphql/treevisitor.d -r "graphql" \
	-u "graphql" -s "graphql" \
	--safe
