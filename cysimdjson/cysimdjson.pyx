# cython: language_level=3

from libcpp cimport bool
from libcpp.string cimport string
from cpython.bytes cimport PyBytes_AsStringAndSize
from cython.operator cimport preincrement

cdef extern from "string_view" namespace "std":
	cppclass string_view:
		pass


cdef extern from "jsoninter.h" namespace "simdjson_element_type":
	cdef simdjson_element_type STRING
	cdef simdjson_element_type INT64
	cdef simdjson_element_type DOUBLE
	cdef simdjson_element_type UINT64
	cdef simdjson_element_type NULL_VALUE
	cdef simdjson_element_type BOOL
	cdef simdjson_element_type OBJECT
	cdef simdjson_element_type ARRAY


cdef extern from "jsoninter.h":

	cppclass simdjson_object:
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

	cppclass simdjson_element_type:
		pass

	cppclass simdjson_element:
		simdjson_element()
		simdjson_element_type type()

	cppclass simdjson_array:
		cppclass iterator:
			iterator()
			simdjson_array operator*()
			iterator operator++()
			bint operator==(iterator)
			bint operator!=(iterator)

			string_view key()
			simdjson_element value()

		simdjson_array()
		iterator begin()
		iterator end()

		size_t size()

	cppclass simdjson_parser:
		simdjson_parser()
		simdjson_parser(size_t max_capacity)
		simdjson_element load(string)
		simdjson_element parse(const char * buf, size_t len, bool realloc_if_needed)

	cdef int getitem_from_element(simdjson_element & element, string & key, simdjson_element & value)
	cdef int getitem_from_array(simdjson_array & array, int key, simdjson_element & value)

	cdef int at_pointer_element(simdjson_element & element, string & key, simdjson_element & value)
	cdef int at_pointer_array(simdjson_array & array, string & key, simdjson_element & value)

	cdef bool compare_type(simdjson_element_type a, simdjson_element_type b)
	cdef object to_string(simdjson_element & value, int * ok)
	cdef object to_int64(simdjson_element & value, int * ok)
	cdef object to_uint64(simdjson_element & value, int * ok)
	cdef object to_double(simdjson_element & value, int * ok)
	cdef object to_bool(simdjson_element & value, int * ok)

	cdef simdjson_array to_array(simdjson_element & value, int * ok)
	cdef simdjson_object to_object(simdjson_element & value, int * ok)

	string string_view_to_string(string_view sv)
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


	def __contains__(JSONElement self, item):
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

		cdef simdjson_object.iterator it = self.Array.begin()
		cdef simdjson_object.iterator it_end = self.Array.end()

		while it != it_end:
			yield _wrap_element(it.value())
			preincrement(it)


	def at_pointer(JSONElement self, key):
		cdef simdjson_element v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = at_pointer_array(self.Array, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		return _wrap_element(v)


cdef class JSONElement:

	cdef simdjson_element Document


	def __cinit__(JSONElement self):
		self.Document = simdjson_element()


	@staticmethod
	cdef inline JSONElement build_JSONElement(simdjson_element document):
		cdef JSONElement self = JSONElement.__new__(JSONElement)
		self.Document = document
		return self


	def __contains__(JSONElement self, key):
		cdef simdjson_element v
		cdef int ok
		key_raw = key.encode('utf-8')
		ok = getitem_from_element(self.Document, key_raw, v)
		return ok == 0


	def __iter__(self):

		for _key in self.keys():
			yield _key


	def items(self):

		cdef simdjson_element v

		for _key in self.keys():
			getitem_from_element(self.Document, _key.encode('utf-8'), v)
			yield _key, _wrap_element(v)


	def __getitem__(JSONElement self, key):
		cdef simdjson_element v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = getitem_from_element(self.Document, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		return _wrap_element(v)


	def __len__(JSONElement self):
		cdef int ok
		cdef string_view sv

		cdef simdjson_object obj = to_object(self.Document, &ok)
		if ok != 0:
			raise ValueError()

		return obj.size()


	def keys(JSONElement self):
		cdef int ok
		cdef string_view sv

		cdef simdjson_object obj = to_object(self.Document, &ok)
		if ok != 0:
			raise ValueError()

		cdef simdjson_object.iterator it = obj.begin()
		while it != obj.end():
			sv = it.key()
			yield string_view_to_string(sv).decode("utf-8")
			preincrement(it)


	def at_pointer(JSONElement self, key):
		cdef simdjson_element v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = at_pointer_element(self.Document, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		return _wrap_element(v)


cdef class JSONDocument(JSONElement):

	cdef object Data


	def __cinit__(JSONDocument self):
		self.Data = None


	@staticmethod
	cdef inline JSONDocument build_JSONDocument(simdjson_element document, object data):
		cdef JSONDocument self = JSONDocument.__new__(JSONDocument)
		self.Document = document
		self.Data = data
		return self


cdef class JSONParser:

	cdef:
		simdjson_parser Parser


	def __cinit__(self, max_capacity = None):
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

		cdef simdjson_element doc = self.Parser.parse(data_ptr, pysize, 1)

		return JSONDocument.build_JSONDocument(doc, event)


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

		cdef simdjson_element doc = self.Parser.parse(data_ptr, pysize, 0)

		return JSONDocument.build_JSONDocument(doc, event)

	def load(self, path):
		cdef simdjson_element doc = self.Parser.load(path)
		return JSONDocument.build_JSONDocument(doc, None)


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
		return JSONElement.build_JSONElement(v)

	if compare_type(et, ARRAY):
		return JSONArray.build_JSONArray(v)

	raise ValueError()
