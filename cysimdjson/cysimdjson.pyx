# cython: language_level=3

from cpython.bytes cimport PyBytes_AsStringAndSize

from cython.operator cimport preincrement
from cython.operator cimport dereference


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


	cpdef object at_pointer(JSONObject self, key):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Object.at_pointer(key_raw)
		return JSONElement.from_element(v).get_value()


	cpdef object get_value(JSONObject self):
		'''
		Get the python value
		'''
		return self


	cpdef object export(JSONObject self):
		'''
		Export the JSON object to a Python dictionary.
		WARNING: This is expensive operation.
		'''
		return _export_object(self.Object)


	def get_addr(JSONObject self):
		return element_addrof(self.Element)


cdef class JSONArray:

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


	cpdef object at_pointer(JSONArray self, key):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Array.at_pointer(key_raw)
		return JSONElement.from_element(v).get_value()


	cpdef object get_value(JSONArray self):
		'''
		Get the python value
		'''
		return self


	cpdef object export(JSONArray self):
		'''
		Export the JSON array to a Python list.
		WARNING: This is expensive operation.
		'''
		return _export_array(self.Array)


	def get_addr(JSONArray self):
		return element_addrof(self.Element)


cdef class JSONElement:

	@staticmethod
	cdef from_element(simdjson_element element):
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



	cpdef object at_pointer(JSONElement self, key):
		key_raw = key.encode('utf-8')
		cdef simdjson_element v = self.Element.at_pointer(key_raw)
		return JSONElement.from_element(v)


	cpdef object get_value(JSONElement self):
		return _get_element(self.Element)


	cpdef object export(JSONElement self):
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

	def __cinit__(JSONParser self, max_capacity=None):
		if max_capacity is not None:
			self.Parser = simdjson_parser.simdjson_parser(int(max_capacity))
		else:
			self.Parser = simdjson_parser.simdjson_parser()


	cpdef object parse(JSONParser self, bytes event):
		cdef Py_ssize_t pysize
		cdef char * data_ptr
		cdef int rc = PyBytes_AsStringAndSize(event, &data_ptr, &pysize)
		if rc == -1:
			raise RuntimeError("Failed to get raw data")

		cdef simdjson_element element = self.Parser.parse(data_ptr, pysize, 1)
		return JSONElement.from_element(element)


	cpdef object parse_in_place(JSONParser self, bytes event):
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


	cpdef object parse_string(JSONParser self, str event):

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
