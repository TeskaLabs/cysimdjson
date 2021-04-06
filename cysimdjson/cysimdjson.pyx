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

	cdef enum simdjson_json_type "simdjson::ondemand::json_type":
		json_type_array "simdjson::ondemand::json_type::array",
		json_type_object "simdjson::ondemand::json_type::object",
		json_type_number "simdjson::ondemand::json_type::number",
		json_type_string "simdjson::ondemand::json_type::string",
		json_type_boolean "simdjson::ondemand::json_type::boolean",
		json_type_null "simdjson::ondemand::json_type::null"


cdef extern from "simdjson/simdjson.h" namespace "simdjson::ondemand":


	cdef cppclass simdjson_value "simdjson::ondemand::value":

		simdjson_value()

		simdjson_json_type type() except +simdjson_error_handler
		bool get_bool() except +simdjson_error_handler


	cdef cppclass simdjson_array "simdjson::ondemand::array":

		simdjson_array()

		simdjson_array_iterator begin()
		simdjson_array_iterator end()


	cdef cppclass simdjson_array_iterator "simdjson::ondemand::array_iterator":

		simdjson_array_iterator()
		
		operator++()
		bint operator!=(simdjson_array_iterator)
		bint operator==(simdjson_array_iterator)
		simdjson_value operator*()


	cdef cppclass simdjson_object "simdjson::ondemand::object":

		simdjson_object()

		simdjson_value find_field(const char *key) except +simdjson_error_handler


	cdef cppclass simdjson_document "simdjson::ondemand::document":

		simdjson_document()

		simdjson_json_type type() except +simdjson_error_handler
		bool get_bool() except +simdjson_error_handler


	cdef cppclass simdjson_parser "simdjson::ondemand::parser":

		simdjson_parser()
		simdjson_parser(size_t max_capacity)

		simdjson_document iterate(const char * buf, size_t len, bool realloc_if_needed) except + simdjson_error_handler


cdef extern from "jsoninter.h":

	PyObject * string_view_to_python_string(string_view & sv)
	string get_active_implementation()

	void parser_helper_iterate(simdjson_document document, simdjson_parser Parser, char * data_ptr, Py_ssize_t pysize, Py_ssize_t padding)
	
	void document_helper_to_object(simdjson_document document, simdjson_object obj) except + simdjson_error_handler
	void document_helper_to_array(simdjson_document document, simdjson_array arr) except + simdjson_error_handler
	cdef object document_helper_to_py_string(simdjson_document & document) except + simdjson_error_handler
	cdef object document_helper_to_py_number(simdjson_document & document) except + simdjson_error_handler

	void value_helper_to_object(simdjson_value & value, simdjson_object obj) except + simdjson_error_handler
	void value_helper_to_array(simdjson_value & value, simdjson_array arr) except + simdjson_error_handler
	cdef object value_helper_to_py_string(simdjson_value & value) except + simdjson_error_handler
	cdef object value_helper_to_py_number(simdjson_value & value) except + simdjson_error_handler


cdef class JSONArray:

	cdef:
		JSONDocument Document
		simdjson_array Array
		int Length


	def __cinit__(self, document):
		self.Document = document
		self.Length = -1


	def __iter__(JSONArray self):

		cdef simdjson_array_iterator it = self.Array.begin()
		cdef simdjson_array_iterator it_end = self.Array.end()

		cdef simdjson_value value

		while it != it_end:
			value = dereference(it)
			yield _unwrap_value(self.Document, value)
			preincrement(it)


	def __contains__(JSONArray self, item):
		# Full scan
		for i in self:
			if i == item:
				return True
		return False


	def __len__(JSONArray self):
		#TODO: Once ready in SIMDJSON: return self.Array.size()

		if self.Length >= 0:
			return self.Length

		cdef int cnt = 0
	
		cdef simdjson_array_iterator it = self.Array.begin()
		cdef simdjson_array_iterator it_end = self.Array.end()
		while it != it_end:
			cnt += 1
			preincrement(it)

		self.Length = cnt

		return cnt


cdef class JSONObject:

	cdef:
		JSONDocument Document
		simdjson_object Object


	def __cinit__(self, document):
		self.Document = document


	def __getitem__(JSONObject self, key):
		key_raw = key.encode('utf-8')

		cdef simdjson_value value
		value = self.Object.find_field(key_raw)

		return _unwrap_value(self.Document, value)


cdef class JSONDocument:

	cdef:
		simdjson_document Document


	cdef get(JSONDocument self):
		'''
		Get top-level object
		'''
		cdef simdjson_json_type json_type = self.Document.type()

		if json_type == json_type_object:
			json_object = JSONObject(self)
			document_helper_to_object(self.Document, json_object.Object)
			return json_object

		if json_type == json_type_array:
			json_array = JSONArray(self)
			document_helper_to_array(self.Document, json_array.Array)
			return json_array

		if json_type == json_type_number:
			return document_helper_to_py_number(self.Document)

		if json_type == json_type_string:
			return document_helper_to_py_string(self.Document)

		if json_type == json_type_boolean:
			return self.Document.get_bool()

		if json_type == json_type_null:
			return None

		raise ValueError("Unknown JSON type")


cdef class JSONParser:

	cdef:
		simdjson_parser Parser


	def __cinit__(self):
		pass


	def parse(self, json):
		json = json + b' ' * SIMDJSON_PADDING

		cdef Py_ssize_t pysize
		cdef char * data_ptr
		cdef int rc = PyBytes_AsStringAndSize(json, &data_ptr, &pysize)
		if rc == -1:
			raise RuntimeError("Failed to get raw data")

		doc = JSONDocument()
		parser_helper_iterate(doc.Document, self.Parser, data_ptr, pysize, SIMDJSON_PADDING)
		return doc.get()


	def parse_in_place(self, json,  padding: int):
		'''
		Skip the reallocation of the input event buffer.
		This method is little bit faster than parse() but you have to ensure proper padding of the event.
		'''
		cdef Py_ssize_t pysize
		cdef char * data_ptr
		cdef int rc = PyBytes_AsStringAndSize(json, &data_ptr, &pysize)
		if rc == -1:
			raise RuntimeError("Failed to get raw data")

		doc = JSONDocument()
		parser_helper_iterate(doc.Document, self.Parser, data_ptr, pysize, padding)
		return doc.get()


	def active_implementation(self):
		return get_active_implementation()


cdef inline object _unwrap_value(document, simdjson_value v):

	cdef simdjson_json_type json_type = v.type()

	if json_type == json_type_object:
		json_object = JSONObject(document)
		value_helper_to_object(v, json_object.Object)
		return json_object

	if json_type == json_type_array:
		json_array = JSONArray(document)
		value_helper_to_array(v, json_array.Array)
		return json_array

	if json_type == json_type_number:
		return value_helper_to_py_number(v)

	if json_type == json_type_string:
		return value_helper_to_py_string(v)

	if json_type == json_type_boolean:
		return v.get_bool()

	if json_type == json_type_null:
		return None

	raise ValueError("Unknown JSON type")


MAXSIZE_BYTES = SIMDJSON_MAXSIZE_BYTES
PADDING = SIMDJSON_PADDING

SIMDJSON_VERSION = "{}.{}.{}".format(
	SIMDJSON_VERSION_MAJOR,
	SIMDJSON_VERSION_MINOR,
	SIMDJSON_VERSION_REVISION
)
