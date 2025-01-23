#include "mpars.h"
#include <stddef.h>
#include "evaluator.h"

double mpars_evaluate(const char* expression, char** error) {
	EvalResult result = evaluate_expression(expression);

	if (result.error) {
		*error = strdup(result.error);
		return 0.0;
	}
	*error = NULL;
	return result.value;
}
