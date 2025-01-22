#include "evaluator.h"
#include <stddef.h>

static EvalResult evaluate_node(ASTNode* node) {
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

static EvalResult create_result(double value) {
	EvalResult result = { .value = value, .error = NULL };

	return result;
}

static EvalResult create_error(const char* error) {
	EvalResult result = { .value = 0, .error = error };

	return result;
}
