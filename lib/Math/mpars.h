#pragma once
#include "glib-2.0/glib.h"

#ifdef __cplusplus
extern "C" {
#endif

double mpars_evaluate(const char* expression, char** error);

#ifdef __cplusplus
}
#endif
