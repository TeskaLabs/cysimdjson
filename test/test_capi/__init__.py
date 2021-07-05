import ctypes
import unittest

import cysimdjson


class CySIMDJSONCAPITestCases(unittest.TestCase):


	def setUp(self):
		self.cysimdjsonapi = ctypes.cdll.LoadLibrary(cysimdjson.__file__)

	def test_capi_01(self):

		self.cysimdjsonapi.cysimdjson_parser_new.restype = ctypes.c_void_p
		self.cysimdjsonapi.cysimdjson_parser_del.argtypes = [ctypes.c_void_p]

		parser = self.cysimdjsonapi.cysimdjson_parser_new()

		self.cysimdjsonapi.cysimdjson_parser_del(parser)


	def test_capi_02(self):
		self.cysimdjsonapi.cysimdjson_parser_new.restype = ctypes.c_int
		element_sizeof = ctypes.pythonapi.cysimdjson_element_sizeof()
		print("element_sizeof:", element_sizeof)


	def test_capi_03(self):
		self.cysimdjsonapi.cysimdjson_parser_test()
