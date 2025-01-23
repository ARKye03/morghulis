#include "evaluator.h"
#include "parser.h"
#include <stddef.h>

EvalResult evaluate_expression(const char* input) {
	if (!input) {
		return create_error("Null input");
	}

	Parser* parser = parser_create(input);
	if (!parser) {
		return create_error("Failed to create parser");
	}

	ParseResult parse_result = parser_parse(parser);

	if (parse_result.error) {
		parser_destroy(parser);
		return create_error(parse_result.error);
	}

	EvalResult result = evaluate_node(parse_result.node);

	free_ast_node(parse_result.node);
	parser_destroy(parser);

	return result;
}

EvalResult evaluate_node(ASTNode* node) {
	switch (node->type) {
		case NODE_NUMBER:
			return create_result(node->data.number);

		case NODE_BINARY_OP: {
			EvalResult left = evaluate_node(node->data.binary.left);
			if (left.error) {
				return left;
			}

			EvalResult right = evaluate_node(node->data.binary.right);
			if (right.error) {
				return right;
			}

			switch (node->data.binary.op) {
				case OP_ADD: return create_result(left.value + right.value);

				case OP_SUBTRACT: return create_result(left.value - right.value);

				case OP_MULTIPLY: return create_result(left.value * right.value);

				case OP_DIVIDE:
					if (right.value == 0) {
						return create_error("Division by zero");
					}
					return create_result(left.value / right.value);
			}
		}
	}
	return create_error("Unknown node type");
}

EvalResult create_result(double value) {
	EvalResult result = { .value = value, .error = NULL };

	return result;
}

EvalResult create_error(const char* error) {
	EvalResult result = { .value = 0, .error = error };

	return result;
}
