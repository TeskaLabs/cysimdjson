import unittest
import os

import cysimdjson

THIS_DIR = os.path.dirname(os.path.abspath(__file__))


class JSONScalarTestCases(unittest.TestCase):

	def test_scalar_01(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'scalar_01.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		self.assertEqual(json_parsed.get_value(), 1)


	def test_scalar_02(self):

		parser = cysimdjson.JSONParser()

		json_loaded = parser.load(os.path.join(THIS_DIR, 'scalar_01.json'))
		self.assertEqual(json_loaded, 1)
