#include "simdjson/simdjson.h"
#include <Python.h>

using namespace simdjson;


inline bool object_contains(dom::object & obj, const char * key) {
	auto err = obj.at_key(key).error();
	return err == SUCCESS;
}


inline PyObject * string_view_to_python_string(std::string_view & sv) {
	return PyUnicode_FromStringAndSize(
		sv.data(),
		sv.length()
	);
}


inline PyObject * element_to_py_string(dom::element & value) {
	std::string_view dst = value.get_string();
	return string_view_to_python_string(dst);
}


inline std::string get_active_implementation() {
	return simdjson::active_implementation->description();
}
