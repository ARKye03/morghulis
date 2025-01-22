#pragma once
#include "parser.h"

typedef struct {
	double value;
	const char* error;
} EvalResult;

EvalResult create_result(double value);
EvalResult create_error(const char* error);
EvalResult evaluate_node(ASTNode* node);
EvalResult evaluate_expression(const char* input);
