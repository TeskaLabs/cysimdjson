# cython: language_level=3

from libc.stdint cimport int64_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string


cdef extern from "<string_view>" namespace "std":
	cppclass string_view:
		pass


cdef extern from "pysimdjson/errors.h":
	cdef void simdjson_error_handler()


cdef extern from "simdjson/simdjson.h" namespace "simdjson":

	cdef size_t SIMDJSON_MAXSIZE_BYTES
	cdef size_t SIMDJSON_PADDING

	cdef enum:
		SIMDJSON_VERSION_MAJOR
		SIMDJSON_VERSION_MINOR
		SIMDJSON_VERSION_REVISION


cdef extern from "simdjson/simdjson.h" namespace "simdjson::dom":

	cdef cppclass simdjson_object "simdjson::dom::object":

		cppclass iterator:
			iterator()

			simdjson_object operator*()
			iterator operator++()
			bint operator==(iterator)
			bint operator!=(iterator)

			string_view key()
			simdjson_element value()

		simdjson_object()

		iterator begin()
		iterator end()

		size_t size()

		simdjson_element at_pointer(const char*) except +simdjson_error_handler
		simdjson_element operator[](const char*) except +simdjson_error_handler


	cdef cppclass simdjson_array "simdjson::dom::array":

		cppclass iterator:
			iterator()

			operator++()
			bint operator!=(iterator)
			simdjson_element operator*()

		simdjson_array()

		iterator begin()
		iterator end()

		size_t size()

		simdjson_element at(int) except +simdjson_error_handler
		simdjson_element at_pointer(const char*) except +simdjson_error_handler


	cdef cppclass simdjson_element "simdjson::dom::element":

		simdjson_element()

		simdjson_element_type type() except +simdjson_error_handler

		bool get_bool() except +simdjson_error_handler
		int64_t get_int64() except +simdjson_error_handler
		uint64_t get_uint64() except +simdjson_error_handler
		double get_double() except +simdjson_error_handler
		simdjson_array get_array() except +simdjson_error_handler
		simdjson_object get_object() except +simdjson_error_handler

		simdjson_element at_pointer(const char*) except +simdjson_error_handler


	cdef cppclass simdjson_parser "simdjson::dom::parser":

		simdjson_parser()
		simdjson_parser(size_t max_capacity)

		simdjson_element load(string) except +simdjson_error_handler nogil
		simdjson_element parse(const char * buf, size_t len, bool realloc_if_needed) except +simdjson_error_handler nogil


cdef extern from "simdjson/simdjson.h" namespace "simdjson::dom::element_type":
	cdef enum simdjson_element_type "simdjson::dom::element_type":
		OBJECT,
		ARRAY,
		STRING,
		INT64,
		UINT64,
		DOUBLE,
		BOOL,
		NULL_VALUE


cdef class JSONObject:

	cdef:
		simdjson_element Element
		simdjson_object Object

	cpdef object at_pointer(self, key)
	cpdef object get_value(self)
	cpdef object export(self)


cdef class JSONArray:

	cdef:
		simdjson_element Element
		simdjson_array Array

	cpdef object at_pointer(self, key)
	cpdef object get_value(self)
	cpdef object export(self)


cdef class JSONElement:

	cdef:
		simdjson_element Element

	@staticmethod
	cdef from_element(simdjson_element element)

	cpdef object at_pointer(self, key)
	cpdef object get_value(self)
	cpdef object export(self)


cdef class JSONParser:

	cdef:
		simdjson_parser Parser

	cpdef object parse(self, bytes event)
	cpdef object parse_in_place(self, bytes event)
	cpdef object parse_string(self, str event)
