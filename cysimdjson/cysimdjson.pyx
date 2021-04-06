# cython: language_level=3

from libc.stdint cimport int64_t, uint64_t, uint32_t
from libcpp cimport bool
from libcpp.string cimport string
from cpython.bytes cimport PyBytes_AsStringAndSize
from cython.operator cimport preincrement
from cython.operator cimport dereference
from cpython.ref cimport PyObject


cdef extern from "string_view" namespace "std":
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


	cdef cppclass simdjson_parser "simdjson::dom::parser":

		simdjson_parser()
		simdjson_parser(size_t max_capacity)

		simdjson_element load(string) except + simdjson_error_handler
		simdjson_element parse(const char * buf, size_t len, bool realloc_if_needed) except + simdjson_error_handler


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


cdef extern from "jsoninter.h":

	cdef bool object_contains(simdjson_object & obj, const char * key) except + simdjson_error_handler

	cdef object element_to_py_string(simdjson_element & value) except + simdjson_error_handler

	PyObject * string_view_to_python_string(string_view & sv)
	string get_active_implementation()


cdef class JSONObject:

	cdef simdjson_object Object
	cdef readonly JSONParser Parser
	cdef object Data


	def __cinit__(JSONObject self, JSONParser parser, data):
		self.Parser = parser
		self.Data = data


	def __contains__(JSONObject self, key):
		key_raw = key.encode('utf-8')
		return object_contains(self.Object, key_raw)


	def __iter__(self):
		for _key in self.keys():
			yield _key


	def items(self):
		cdef string_view sv
		cdef simdjson_element v

		cdef simdjson_object.iterator it = self.Object.begin()
		while it != self.Object.end():
			sv = it.key()
			v = it.value()

			yield <object> string_view_to_python_string(sv), _wrap_element(v, self.Parser, self.Data)
			preincrement(it)


	def __getitem__(JSONObject self, key):
		cdef simdjson_element v

		key_raw = key.encode('utf-8')
		v = self.Object[key_raw]

		return _wrap_element(v, self.Parser, self.Data)


	def __len__(JSONObject self):
		return self.Object.size()


	def keys(JSONObject self):
		cdef string_view sv

		cdef simdjson_object.iterator it = self.Object.begin()
		while it != self.Object.end():
			sv = it.key()
			yield <object> string_view_to_python_string(sv)
			preincrement(it)


	def at_pointer(JSONObject self, key):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Object.at_pointer(key_raw)
		return _wrap_element(v, self.Parser, self.Data)


cdef class JSONArray:

	cdef simdjson_array Array
	cdef readonly JSONParser Parser
	cdef object Data

	def __cinit__(JSONArray self, JSONParser parser, data):
		self.Parser = parser
		self.Data = data


	def __contains__(JSONArray self, item):
		# This is a full scan
		for i in range(len(self)):
			if self[i] == item:
				return True
		return False


	def __getitem__(JSONArray self, key: int):
		cdef simdjson_element v = self.Array.at(key)
		return _wrap_element(v, self.Parser, self.Data)


	def __len__(JSONArray self):
		return self.Array.size()


	def __iter__(JSONArray self):

		cdef simdjson_array.iterator it = self.Array.begin()
		cdef simdjson_array.iterator it_end = self.Array.end()

		cdef simdjson_element element

		while it != it_end:
			element = dereference(it)
			yield _wrap_element(element, self.Parser, self.Data)
			preincrement(it)


	def at_pointer(JSONArray self, key):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Array.at_pointer(key_raw)
		return _wrap_element(v, self.Parser, self.Data)


cdef class JSONParser:

	cdef:
		simdjson_parser Parser


	def __cinit__(self, max_capacity=None):
		if max_capacity is not None:
			self.Parser = simdjson_parser.simdjson_parser(int(max_capacity))
		else:
			self.Parser = simdjson_parser.simdjson_parser()


	def parse(self, event):
		cdef Py_ssize_t pysize
		cdef char * data_ptr
		cdef int rc = PyBytes_AsStringAndSize(event, &data_ptr, &pysize)
		if rc == -1:
			raise RuntimeError("Failed to get raw data")

		cdef simdjson_element element = self.Parser.parse(data_ptr, pysize, 1)
		return _wrap_element(element, self, event)


	def parse_in_place(self, event):
		'''
		Skip the reallocation of the input event buffer.
		This method is little bit faster than parse() but you have to ensure proper padding of the event.
		'''
		cdef Py_ssize_t pysize
		cdef char * data_ptr
		cdef int rc = PyBytes_AsStringAndSize(event, &data_ptr, &pysize)
		if rc == -1:
			raise RuntimeError("Failed to get raw data")

		cdef simdjson_element element = self.Parser.parse(data_ptr, pysize, 0)
		return _wrap_element(element, self, event)


	def load(self, path):
		cdef simdjson_element element = self.Parser.load(path)
		return _wrap_element(element, self, None)


	def active_implementation(self):
		return get_active_implementation()


cdef inline object _wrap_element(simdjson_element v, JSONParser parser, event):
	cdef simdjson_element_type et = v.type()

	if et == OBJECT:
		obj = JSONObject(parser, event)
		obj.Object = v.get_object()
		return obj

	elif et == ARRAY:
		arr = JSONArray(parser, event)
		arr.Array = v.get_array()
		return arr

	elif et == STRING:
		return element_to_py_string(v)

	elif et == INT64:
		return v.get_int64()

	elif et == UINT64:
		return v.get_uint64()

	elif et == DOUBLE:
		return v.get_double()

	elif et == NULL_VALUE:
		return None

	elif et == BOOL:
		return v.get_bool()

	else:
		raise ValueError("Unknown element type")


MAXSIZE_BYTES = SIMDJSON_MAXSIZE_BYTES
PADDING = SIMDJSON_PADDING

SIMDJSON_VERSION = "{}.{}.{}".format(
	SIMDJSON_VERSION_MAJOR,
	SIMDJSON_VERSION_MINOR,
	SIMDJSON_VERSION_REVISION
)
