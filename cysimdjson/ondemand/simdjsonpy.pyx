# cython: language_level=3

from libcpp.string cimport string
from libc.stdint cimport int64_t


cdef extern from "simdjson.h" namespace "simdjson":

	cppclass padded_string:
		padded_string()
		padded_string(string)



cdef extern from "simdjson.h" namespace "simdjson::ondemand":

	cppclass simdjson_result:
		simdjson_result get(string_view)

	cppclass value:
		simdjson_result get_string()

	cppclass document:
		pass

	cppclass parser:
		parser()
		document iterate(padded_string)


cdef extern from "jsoninter.h":
	cdef int get(document & document, string & key, value & value)
	cdef int get_string_view(value & value, string_view & dst)
	cdef string to_string(string_view sv)

cdef extern from "string_view" namespace "std":
	cppclass string_view:
		pass


cdef class JSONDocument:

	cdef document Document
	cdef padded_string JSONps

	def __cinit__(JSONDocument self, JSONParser parser, event):
		self.JSONps = padded_string(event)
		self.Document = parser.Parser.iterate(self.JSONps)


	def __contains__(JSONDocument self, key):
		cdef value v
		cdef int ok
		key_raw = key.encode('utf-8')
		ok = get(self.Document, key_raw, v)
		return ok == 0


	def __getitem__(JSONDocument self, key):
		cdef value v
		cdef int ok

		key_raw = key.encode('utf-8')
		ok = get(self.Document, key_raw, v)
		if ok != 0:
			raise KeyError("Not found '{}'".format(key))

		# TODO: Once value has type() method, check the type and decide what to return
		# https://github.com/simdjson/simdjson/pull/1472

		cdef string_view v_str
		ok = get_string_view(v, v_str)
		if ok != 0:
			raise ValueError()

		return to_string(v_str).decode('utf-8')


cdef class JSONParser:

	cdef:
		parser Parser

	def process(self, event):
		return JSONDocument(self, event)
