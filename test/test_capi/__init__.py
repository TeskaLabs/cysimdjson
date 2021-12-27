import os
import ctypes
import unittest

import cysimdjson.cysimdjson

THIS_DIR = os.path.dirname(os.path.abspath(__file__))


class CySIMDJSONCAPITestCases(unittest.TestCase):


	def setUp(self):
		self.cysimdjsonapi = ctypes.cdll.LoadLibrary(cysimdjson.cysimdjson.__file__)

		self.cysimdjsonapi.cysimdjson_parser_new.restype = ctypes.c_void_p
		
		self.cysimdjsonapi.cysimdjson_parser_del.argtypes = [ctypes.c_void_p]

		self.cysimdjsonapi.cysimdjson_parser_parse.restype = ctypes.c_bool
		self.cysimdjsonapi.cysimdjson_parser_parse.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t]		

		self.cysimdjsonapi.cysimdjson_element_get_int64_t.restype = ctypes.c_bool
		self.cysimdjsonapi.cysimdjson_element_get_int64_t.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.POINTER(ctypes.c_int64)]

		self.cysimdjsonapi.cysimdjson_element_get.restype = ctypes.c_bool
		self.cysimdjsonapi.cysimdjson_element_get.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_void_p]


	def test_capi_01(self):
		parser = self.cysimdjsonapi.cysimdjson_parser_new()
		self.cysimdjsonapi.cysimdjson_parser_del(parser)


	def test_capi_02(self):
		element_sizeof = self.cysimdjsonapi.cysimdjson_element_sizeof()
		self.assertGreater(element_sizeof, 0)


	def test_capi_03(self):
		res = self.cysimdjsonapi.cysimdjson_parser_test()
		self.assertEqual(res, 0)


	def test_capi_04(self):
		parser = self.cysimdjsonapi.cysimdjson_parser_new()

		element = ctypes.create_string_buffer(
			self.cysimdjsonapi.cysimdjson_element_sizeof()
		)

		with open(os.path.join(THIS_DIR, 'test.json'), 'rb') as fin:
			json_raw = fin.read()
		json_buffer = ctypes.create_string_buffer(json_raw)

		error = self.cysimdjsonapi.cysimdjson_parser_parse(
			parser,
			element,
			json_buffer,
			len(json_raw)
		)
		self.assertFalse(error)

		jsonpointer = ctypes.create_string_buffer(b"/document/key4")
		int64_ptr = ctypes.c_int64()

		error = self.cysimdjsonapi.cysimdjson_element_get_int64_t(
			jsonpointer,
			len(jsonpointer) - 1,  # We don't want terminating '\0'
			element,
			int64_ptr
		)
		self.assertFalse(error)
		self.assertEqual(int64_ptr.value, 40)

		self.cysimdjsonapi.cysimdjson_parser_del(parser)


	def test_capi_05(self):
		parser = self.cysimdjsonapi.cysimdjson_parser_new()

		element = ctypes.create_string_buffer(
			self.cysimdjsonapi.cysimdjson_element_sizeof()
		)

		with open(os.path.join(THIS_DIR, 'test.json'), 'rb') as fin:
			json_raw = fin.read()
		json_buffer = ctypes.create_string_buffer(json_raw)

		error = self.cysimdjsonapi.cysimdjson_parser_parse(
			parser,
			element,
			json_buffer,
			len(json_raw)
		)
		self.assertFalse(error)

		jsonpointer = ctypes.create_string_buffer(b"/document")

		subelement = ctypes.create_string_buffer(
			self.cysimdjsonapi.cysimdjson_element_sizeof()
		)

		error = self.cysimdjsonapi.cysimdjson_element_get(
			jsonpointer,
			len(jsonpointer) - 1,  # We don't want terminating '\0'
			element,
			subelement
		)
		self.assertFalse(error)


		jsonpointer = ctypes.create_string_buffer(b"/key4")
		int64_ptr = ctypes.c_int64()

		error = self.cysimdjsonapi.cysimdjson_element_get_int64_t(
			jsonpointer,
			len(jsonpointer) - 1,  # We don't want terminating '\0'
			subelement,
			int64_ptr
		)
		self.assertFalse(error)
		self.assertEqual(int64_ptr.value, 40)


		self.cysimdjsonapi.cysimdjson_parser_del(parser)


	def test_capi_06(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'test.json'), 'r') as fo:
			json_parsed = parser.parse_string(fo.read())

		# Transition into C API
		element_addr = json_parsed.get_addr()
		self.assertNotEqual(element_addr, 0)

		jsonpointer = ctypes.create_string_buffer(b"/document/key4")
		int64_ptr = ctypes.c_int64()

		error = self.cysimdjsonapi.cysimdjson_element_get_int64_t(
			jsonpointer,
			len(jsonpointer) - 1,  # We don't want terminating '\0'
			element_addr,
			int64_ptr
		)
		self.assertFalse(error)
		self.assertEqual(int64_ptr.value, 40)

		# Transition back to Cython API
		cython_element = cysimdjson.addr_to_element(element_addr)
		val = cython_element.at_pointer("/document/key4")
		self.assertEqual(val, 40)
