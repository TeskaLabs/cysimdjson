#include "simdjson/simdjson.h"
#include <Python.h>

using namespace simdjson;

inline PyObject * string_view_to_python_string(std::string_view & sv) {
	return PyUnicode_FromStringAndSize(
		sv.data(),
		sv.length()
	);
}

inline std::string get_active_implementation() {
	return simdjson::active_implementation->description();
}


inline void parser_helper_iterate(ondemand::document & document, ondemand::parser & parser, char * data_ptr, Py_ssize_t pysize, Py_ssize_t padding) {
	document = parser.iterate(data_ptr, pysize, padding);
}


inline void document_helper_to_object(ondemand::document & document, ondemand::object & obj) {
	obj = document.get_object();
}

inline void document_helper_to_array(ondemand::document & document, ondemand::array & arr) {
	arr = document.get_array();
}

inline void value_helper_to_object(ondemand::value & value, ondemand::object & obj) {
	obj = value.get_object();
}

inline void value_helper_to_array(ondemand::value & value, ondemand::array & arr) {
	arr = value.get_array();
}


inline PyObject * value_helper_to_py_string(ondemand::value & value) {
	std::string_view dst = value.get_string();
	return PyUnicode_FromStringAndSize(
		dst.data(),
		dst.length()
	);
}

inline PyObject * document_helper_to_py_string(ondemand::document & value) {
	std::string_view dst = value.get_string();
	return PyUnicode_FromStringAndSize(
		dst.data(),
		dst.length()
	);
}


inline PyObject * value_helper_to_py_number(ondemand::value & value) {
	try {
		int64_t vi64 = value.get_int64();
		return PyLong_FromLongLong(vi64);
	} catch(...) {
		double dbl = value.get_double();
		return PyFloat_FromDouble(dbl);
	}
}

inline PyObject * document_helper_to_py_number(ondemand::document & value) {
	try {
		int64_t vi64 = value.get_int64();
		return PyLong_FromLongLong(vi64);
	} catch(...) {
		double dbl = value.get_double();
		return PyFloat_FromDouble(dbl);
	}
}
