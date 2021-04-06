import unittest
import os

import cysimdjson

THIS_DIR = os.path.dirname(os.path.abspath(__file__))


class JSONArrayTestCases(unittest.TestCase):

	def test_iter_01(self):

		parser = cysimdjson.JSONParser()
		
		with open(os.path.join(THIS_DIR, 'array.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		ar = json_parsed['array']
		self.assertEqual(len(ar), 10)
		for i, n in enumerate(ar, 1):
			self.assertEqual(i, n)
