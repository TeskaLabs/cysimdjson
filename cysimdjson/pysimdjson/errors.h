#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include "../simdjson/simdjson.h"

#ifndef _PY_SIMDJSON_ERRORS
#define _PY_SIMDJSON_ERRORS
    void simdjson_error_handler();
#endif
