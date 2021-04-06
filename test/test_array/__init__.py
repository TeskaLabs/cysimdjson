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

		self.assertEqual(list(i for i in ar), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
		self.assertEqual(list(i for i in ar), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])


	def test_iter_02(self):

		parser = cysimdjson.JSONParser()
		
		with open(os.path.join(THIS_DIR, 'top_array.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		for i, n in enumerate(json_parsed, 1):
			self.assertEqual(i, n)


	def test_len_01(self):

		parser = cysimdjson.JSONParser()
		
		with open(os.path.join(THIS_DIR, 'array.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		ar = json_parsed['array']
		self.assertEqual(len(ar), 10)
		self.assertEqual(len(ar), 10)
