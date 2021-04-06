# cython: language_level=3

from libc.stdint cimport uint32_t
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
			uint32_t key_length()
			const char *key_c_str()
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
		size_t number_of_slots()

		# simd_element at(int) except +simdjson_error_handler
		# simd_element at_pointer(const char*) except +simdjson_error_handler


	cdef cppclass simdjson_element "simdjson::dom::element":

		simdjson_element()

		simdjson_element_type type() except +simdjson_error_handler

		const char *get_c_str() except +simdjson_error_handler
		size_t get_string_length() except +simdjson_error_handler

		simdjson_array get_array() except +simdjson_error_handler
		simdjson_element get_object() except +simdjson_error_handler


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

	cdef int getitem_from_object(simdjson_object & object, string & key, simdjson_element & value) except + simdjson_error_handler
	cdef int getitem_from_array(simdjson_array & array, int key, simdjson_element & value) except + simdjson_error_handler

	cdef int at_pointer_object(simdjson_object & element, string & key, simdjson_element & value) except + simdjson_error_handler
	cdef int at_pointer_array(simdjson_array & array, string & key, simdjson_element & value) except + simdjson_error_handler

	cdef bool compare_type(simdjson_element_type a, simdjson_element_type b) except + simdjson_error_handler
	cdef object to_string(simdjson_element & value, int * ok) except + simdjson_error_handler
	cdef object to_int64(simdjson_element & value, int * ok) except + simdjson_error_handler
	cdef object to_uint64(simdjson_element & value, int * ok) except + simdjson_error_handler
	cdef object to_double(simdjson_element & value, int * ok) except + simdjson_error_handler
	cdef object to_bool(simdjson_element & value, int * ok) except + simdjson_error_handler

	cdef simdjson_array to_array(simdjson_element & value, int * ok) except + simdjson_error_handler
	cdef simdjson_object to_object(simdjson_element & value, int * ok) except + simdjson_error_handler

	PyObject * string_view_to_python_string(string_view & sv)
	string get_active_implementation()


cdef class JSONArray:

	cdef simdjson_array Array


	def __cinit__(JSONArray self):
		self.Array = simdjson_array()


	@staticmethod
	cdef inline JSONArray build_JSONArray(simdjson_element value):
		cdef JSONArray self = JSONArray.__new__(JSONArray)
		cdef int ok
		self.Array = to_array(value, &ok)
		if ok != 0:
			raise ValueError()
		return self


	def __contains__(JSONArray self, item):
		# This is a full scan
		for i in range(len(self)):
			if self[i] == item:
				return True
		return False


	def __getitem__(JSONArray self, key: int):
		cdef simdjson_element v
		ok = getitem_from_array(self.Array, key, v)
		if ok != 0:
			raise IndexError("Not found '{}'".format(key))
		return _wrap_element(v)


	def __len__(JSONArray self):
		return self.Array.size()


	def __iter__(JSONArray self):

		cdef simdjson_array.iterator it = self.Array.begin()
		cdef simdjson_array.iterator it_end = self.Array.end()

		cdef simdjson_element element

		while it != it_end:
			element = dereference(it)
			yield _wrap_element(element)
			preincrement(it)


	def at_pointer(JSONArray self, key):
		cdef simdjson_element v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = at_pointer_array(self.Array, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		return _wrap_element(v)


cdef class JSONObject:

	cdef simdjson_object Object


	def __cinit__(JSONObject self):
		self.Object = simdjson_object()


	@staticmethod
	cdef inline JSONObject build_JSONObject(simdjson_element value):
		cdef JSONObject self = JSONObject.__new__(JSONObject)
		cdef int ok
		self.Object = to_object(value, &ok)
		if ok != 0:
			raise ValueError()
		return self


	def __contains__(JSONObject self, key):
		cdef simdjson_element v
		cdef int ok
		key_raw = key.encode('utf-8')
		ok = getitem_from_object(self.Object, key_raw, v)
		return ok == 0


	def __iter__(self):
		for _key in self.keys():
			yield _key


	def items(self):
		cdef int ok
		cdef string_view sv
		cdef simdjson_element v

		cdef simdjson_object.iterator it = self.Object.begin()
		while it != self.Object.end():
			sv = it.key()
			v = it.value()

			yield <object> string_view_to_python_string(sv), _wrap_element(v)
			preincrement(it)


	def __getitem__(JSONObject self, key):
		cdef simdjson_element v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = getitem_from_object(self.Object, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		return _wrap_element(v)


	def __len__(JSONObject self):
		cdef int ok
		cdef string_view sv

		return self.Object.size()


	def keys(JSONObject self):
		cdef int ok
		cdef string_view sv

		cdef simdjson_object.iterator it = self.Object.begin()
		while it != self.Object.end():
			sv = it.key()
			yield <object> string_view_to_python_string(sv)
			preincrement(it)


	def at_pointer(JSONObject self, key):
		cdef simdjson_element v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = at_pointer_object(self.Object, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		return _wrap_element(v)


cdef class JSONObjectDocument(JSONObject):
	'''
	Represents a top-level JSON object (dictionary).
	'''

	cdef object Data
	cdef simdjson_element Element


	def __cinit__(JSONObjectDocument self):
		self.Data = None


cdef inline JSONObjectDocument _build_JSONObjectDocument(simdjson_element element, object data):
	cdef JSONObjectDocument self = JSONObjectDocument.__new__(JSONObjectDocument)

	cdef int ok
	self.Object = to_object(element, &ok)
	if ok != 0:
		raise ValueError("Not an JSON object.")

	self.Element = element
	self.Data = data

	return self


cdef class JSONArrayDocument(JSONArray):
	'''
	Represents a top-level JSON array.
	'''

	cdef object Data
	cdef simdjson_element Element


	def __cinit__(JSONArrayDocument self):
		self.Data = None


cdef inline JSONArrayDocument _build_JSONArrayDocument(simdjson_element element, object data):
	cdef JSONArrayDocument self = JSONArrayDocument.__new__(JSONArrayDocument)

	cdef int ok
	self.Array = to_array(element, &ok)
	if ok != 0:
		raise ValueError("Not an JSON array.")

	self.Element = element
	self.Data = data

	return self


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
		return self._build(element, event)


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
		return self._build(element, event)


	def load(self, path):
		cdef simdjson_element element = self.Parser.load(path)
		return self._build(element, None)


	cdef _build(self, simdjson_element element, event):
		cdef simdjson_element_type et = element.type()
		
		if compare_type(et, OBJECT):
			return _build_JSONObjectDocument(element, event)

		elif compare_type(et, ARRAY):
			return _build_JSONArrayDocument(element, event)

		else:
			return _wrap_element(element)


	def active_implementation(self):
		return get_active_implementation()


cdef inline object _wrap_element(simdjson_element v):
	cdef int ok
	cdef simdjson_element_type et = v.type()

	# String
	if compare_type(et, STRING):
		o = to_string(v, &ok)
		if ok != 0:
			raise ValueError()
		return o

	# INT64
	if compare_type(et, INT64):
		o = to_int64(v, &ok)
		if ok != 0:
			raise ValueError()
		return o

	# DOUBLE
	if compare_type(et, DOUBLE):
		o = to_double(v, &ok)
		if ok != 0:
			raise ValueError()
		return o

	# NULL / None
	if compare_type(et, NULL_VALUE):
		return None

	# UINT64
	if compare_type(et, UINT64):
		o = to_uint64(v, &ok)
		if ok != 0:
			raise ValueError()
		return o

	# BOOL
	if compare_type(et, BOOL):
		o = to_bool(v, &ok)
		if ok != 0:
			raise ValueError()
		return o

	if compare_type(et, OBJECT):
		return JSONObject.build_JSONObject(v)

	if compare_type(et, ARRAY):
		return JSONArray.build_JSONArray(v)

	raise ValueError()


MAXSIZE_BYTES = SIMDJSON_MAXSIZE_BYTES
PADDING = SIMDJSON_PADDING

SIMDJSON_VERSION = "{}.{}.{}".format(
	SIMDJSON_VERSION_MAJOR,
	SIMDJSON_VERSION_MINOR,
	SIMDJSON_VERSION_REVISION
)
