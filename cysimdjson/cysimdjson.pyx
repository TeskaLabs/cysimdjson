# cython: language_level=3

from libc.stdint cimport int64_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from cpython.bytes cimport PyBytes_AsStringAndSize

from cython.operator cimport preincrement
from cython.operator cimport dereference


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

		simdjson_element load(string) except + simdjson_error_handler nogil
		simdjson_element parse(const char * buf, size_t len, bool realloc_if_needed) except + simdjson_error_handler nogil


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
	cdef bool object_get(simdjson_object & obj, const char * key, simdjson_element & value)

	cdef object element_to_py_string(simdjson_element & value) except + simdjson_error_handler

	cdef object string_view_to_python_string(string_view & sv)
	cdef string obtain_active_implementation()

	cdef const char * PyUnicode_AsUTF8AndSize(object, Py_ssize_t *)

	cdef simdjson_element extract_element(void *) except + simdjson_error_handler
	cdef size_t element_addrof(simdjson_element & value)


cdef class JSONObject:

	cdef:
		simdjson_element Element
		simdjson_object Object


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

			elem = JSONElement.from_element(v)
			yield string_view_to_python_string(sv), elem.get_value()
			preincrement(it)


	def __getitem__(JSONObject self, str key):
		cdef simdjson_element v

		key_raw = key.encode('utf-8')
		v = self.Object[key_raw]

		return JSONElement.from_element(v).get_value()


	def get(JSONObject self, str key, default=None):
		cdef simdjson_element v

		key_raw = key.encode('utf-8')
		cdef bool found = object_get(self.Object, key_raw, v)
		if not found:
			return default
		return JSONElement.from_element(v).get_value()
	

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
		return JSONElement.from_element(v).get_value()


	def get_value(JSONElement self):
		'''
		Get the python value
		'''
		return self


	def export(self):
		'''
		Export the JSON object to a Python dictionary.
		WARNING: This is expensive operation.
		'''
		return _export_object(self.Object)


	def get_addr(JSONElement self):
		return element_addrof(self.Element)


cdef class JSONArray:

	cdef:
		simdjson_element Element
		simdjson_array Array


	def __contains__(JSONArray self, item):
		# This is a full scan
		for i in range(len(self)):
			if self[i] == item:
				return True
		return False


	def __getitem__(JSONArray self, key: int):
		cdef simdjson_element v = self.Array.at(key)

		return JSONElement.from_element(v).get_value()


	def __len__(JSONArray self):
		return self.Array.size()


	def __iter__(JSONArray self):

		cdef simdjson_array.iterator it = self.Array.begin()
		cdef simdjson_array.iterator it_end = self.Array.end()

		cdef simdjson_element element

		while it != it_end:
			elem = JSONElement.from_element(dereference(it))
			yield elem.get_value()
			preincrement(it)


	def at_pointer(JSONArray self, key):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Array.at_pointer(key_raw)
		return JSONElement.from_element(v).get_value()


	def get_value(JSONElement self):
		'''
		Get the python value
		'''
		return self


	def export(self):
		'''
		Export the JSON array to a Python list.
		WARNING: This is expensive operation.
		'''
		return _export_array(self.Array)


	def get_addr(JSONElement self):
		return element_addrof(self.Element)


cdef class JSONElement:

	cdef:
		simdjson_element Element

	@staticmethod
	cdef inline from_element(simdjson_element element):
		'''
		This is the correct factory method
		'''
		cdef simdjson_element_type et = element.type()

		if et == OBJECT:
			new_object = JSONObject()
			new_object.Element = element
			new_object.Object = element.get_object()
			return new_object

		elif et == ARRAY:
			new_array = JSONArray()
			new_array.Element = element
			new_array.Array = element.get_array()
			return new_array

		else:
			new_element = JSONElement()
			new_element.Element = element
			return new_element



	def at_pointer(JSONElement self, key: str):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Element.at_pointer(key_raw)
		return JSONElement.from_element(v)


	def get_value(JSONElement self):
		return _get_element(self.Element)


	def export(JSONElement self):
		return _export_element(self.Element)


	def get_addr(JSONElement self):
		return element_addrof(self.Element)


cdef inline object _export_element(simdjson_element v):
	cdef simdjson_element_type et = v.type()

	if et == OBJECT:
		return _export_object(v.get_object())

	elif et == ARRAY:
		return _export_array(v.get_array())

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


cdef inline object _get_element(simdjson_element v):
	cdef simdjson_element_type et = v.type()

	if et == STRING:
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

	elif et == OBJECT:
		return _export_object(v.get_object())

	elif et == ARRAY:
		return _export_array(v.get_array())

	else:
		raise ValueError("Unknown element type")


cdef class JSONParser:

	cdef:
		simdjson_parser Parser


	def __cinit__(JSONParser self, max_capacity=None):
		if max_capacity is not None:
			self.Parser = simdjson_parser.simdjson_parser(int(max_capacity))
		else:
			self.Parser = simdjson_parser.simdjson_parser()


	def parse(JSONParser self, event: bytes):
		cdef Py_ssize_t pysize
		cdef char * data_ptr
		cdef int rc = PyBytes_AsStringAndSize(event, &data_ptr, &pysize)
		if rc == -1:
			raise RuntimeError("Failed to get raw data")

		cdef simdjson_element element = self.Parser.parse(data_ptr, pysize, 1)
		return JSONElement.from_element(element)


	def parse_in_place(JSONParser self, event: bytes):
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
		return JSONElement.from_element(element)


	def parse_string(JSONParser self, event: str):

		cdef Py_ssize_t pysize
		cdef const char * data_ptr = PyUnicode_AsUTF8AndSize(event, &pysize)

		cdef simdjson_element element = self.Parser.parse(data_ptr, pysize, 1)
		return JSONElement.from_element(element)


	def load(JSONParser self, path: str):
		'''
		This is a Pythonic API, as close to `json.load()` as possible/practical.
		This means that the result of the load() is not the element but final value.
		'''
		path_bytes = path.encode('utf-8')
		cdef simdjson_element element = self.Parser.load(path_bytes)
		return JSONElement.from_element(element).get_value()


	def loads(JSONParser self, content: str):
		'''
		This is a Pythonic API, as close to `jsons.load()` as possible/practical.
		This means that the result of the loads() is not the element but final value.
		'''
		path_bytes = content.encode('utf-8')
		cdef simdjson_element element = self.Parser.parse(path_bytes, len(path_bytes), 1)
		return JSONElement.from_element(element).get_value()


	def active_implementation(JSONParser self):
		return obtain_active_implementation()


cdef public api object cysimdjson_addr_to_element(void * element):
	'''
	Used by C-level callers who want to wrap `simdjson::dom::element`
	into a cysimdjson JSONElement instance.
	'''
	cdef simdjson_element v = extract_element(element)
	return JSONElement.from_element(v)


def addr_to_element(element_addr: int):
	cdef simdjson_element v = extract_element(<void *><size_t>element_addr)
	return JSONElement.from_element(v)


cdef inline object _export_object(simdjson_object obj):
	cdef simdjson_object.iterator it_obj

	result = {}
	it_obj = obj.begin()
	while it_obj != obj.end():
		sv = it_obj.key()
		result[<object>string_view_to_python_string(sv)] = _export_element(it_obj.value())
		preincrement(it_obj)

	return result


cdef inline object _export_array(simdjson_array arr):
	cdef simdjson_array.iterator it

	it = arr.begin()

	result = []
	while it != arr.end():
		result.append(
			_export_element(
				dereference(it)
			)
		)
		preincrement(it)

	return result


MAXSIZE_BYTES = SIMDJSON_MAXSIZE_BYTES
PADDING = SIMDJSON_PADDING

SIMDJSON_VERSION = "{}.{}.{}".format(
	SIMDJSON_VERSION_MAJOR,
	SIMDJSON_VERSION_MINOR,
	SIMDJSON_VERSION_REVISION
)
