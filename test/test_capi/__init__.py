import ctypes
import unittest

import cysimdjson


class CySIMDJSONCAPITestCases(unittest.TestCase):


	def test_capi_01(self):

		ctypes.pythonapi.cysimdjson_parser_new.restype = ctypes.c_void_p
		ctypes.pythonapi.cysimdjson_parser_del.argtypes = [ctypes.c_void_p]

		parser = ctypes.pythonapi.cysimdjson_parser_new()

		ctypes.pythonapi.cysimdjson_parser_del(parser)


	def test_capi_02(self):
		ctypes.pythonapi.cysimdjson_parser_new.restype = ctypes.c_int
		element_sizeof = ctypes.pythonapi.cysimdjson_element_sizeof()
		print("element_sizeof:", element_sizeof)


	def test_capi_03(self):
		ctypes.pythonapi.cysimdjson_parser_test()
