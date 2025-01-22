#pragma once
#include "parser.h"

typedef struct {
    double value;
    const char* error;
} EvalResult;

// Add helper function declarations
static EvalResult create_result(double value);
static EvalResult create_error(const char* error);

EvalResult evaluate_expression(const char* input);