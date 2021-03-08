#include "simdjson/simdjson.h"
#include <Python.h>

using namespace simdjson;

// To avoid naming collisions between dom::object and python namespace
using simdjson_object = dom::object;
using simdjson_element_type = dom::element_type;
using simdjson_element = dom::element;
using simdjson_array = dom::array;
using simdjson_parser = dom::parser;


inline int getitem_from_element(dom::element & element, const std::string & key, dom::element & value) {
	auto error = element[key].get(value);
	if (error) {
		return -1;
	}
	return 0;
}


inline int getitem_from_array(dom::array & array, int key, dom::element & value) {
	// TODO: Handle negative key
	auto error = array.at(key).get(value);
	if (error) {
		return -1;
	}
	return 0;
}


inline int at_pointer_element(dom::element & element, std::string & key, dom::element & value) {
	auto error = element.at_pointer(key).get(value);
	if (error) {
		return -1;
	}
	return 0;
}


inline int at_pointer_array(dom::array & array, std::string & key, dom::element & value) {
	auto error = array.at_pointer(key).get(value);
	if (error) {
		return -1;
	}
	return 0;
}


inline bool compare_type(dom::element_type a, dom::element_type b) {
	return a == b;
}


inline PyObject * to_string(dom::element & value, int * ok) {
	std::string_view dst;
	auto error = value.get_string().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return NULL;
	}

	*ok = 0;
	return PyUnicode_FromStringAndSize(
		dst.data(),
		dst.length()
	);
}


inline PyObject * to_int64(dom::element & value, int * ok) {
	int64_t dst;
	auto error = value.get_int64().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return NULL;
	}

	*ok = 0;
	return PyLong_FromLongLong(dst);
}


inline PyObject * to_double(dom::element & value, int * ok) {
	double dst;
	auto error = value.get_double().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return NULL;
	}

	*ok = 0;
	return PyFloat_FromDouble(dst);
}


inline PyObject * to_uint64(dom::element & value, int * ok) {
	uint64_t dst;
	auto error = value.get_uint64().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return NULL;
	}

	*ok = 0;
	return PyLong_FromUnsignedLongLong(dst);
}


inline PyObject * to_bool(dom::element & value, int * ok) {
	bool dst;
	auto error = value.get_bool().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return NULL;
	}

	*ok = 0;
	if (dst)
		{ Py_RETURN_TRUE; }
	else
		{ Py_RETURN_TRUE; }
}


inline dom::array to_array(dom::element & value, int * ok) {
	dom::array dst;
	auto error = value.get_array().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return dom::array();
	}
	*ok = 0;
	return dst;
}


inline dom::object to_object(dom::element & value, int * ok) {
	dom::object dst;
	auto error = value.get_object().get(dst);
	if (error) {
		std::cerr << error << std::endl;
		*ok = -1;
		return dom::object();
	}
	*ok = 0;
	return dst;
}


inline std::string string_view_to_string(std::string_view sv) {
	//TODO: This creates a string copy
	return std::string(sv);
}

inline std::string get_active_implementation() {
	return simdjson::active_implementation->description();
}
