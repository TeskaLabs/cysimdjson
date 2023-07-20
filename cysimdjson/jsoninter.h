#include "simdjson/simdjson.h"
#include <Python.h>

using namespace simdjson;


inline bool object_contains(dom::object & obj, const char * key) {
	auto err = obj.at_key(key).error();
	return err == SUCCESS;
}


inline bool object_get(dom::object & obj, const char * key, dom::element & value) {
	simdjson_result<dom::element> ret = obj.at_key(key);
	error_code error = ret.get(value);
	return (error == SUCCESS);
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


inline std::string obtain_active_implementation() {
	return simdjson::get_active_implementation()->description();
}


inline dom::element extract_element(void * p) {
	dom::element * element = static_cast<dom::element *>(p);
	return *element;
}

inline size_t element_addrof(dom::element & element) {
	return (size_t)&element;
}
