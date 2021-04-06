import unittest
import os

import cysimdjson

THIS_DIR = os.path.dirname(os.path.abspath(__file__))


class JSONDocumentTestCases(unittest.TestCase):


	def test_simple_01(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		self.assertEqual(json_parsed['foo'], 'bar')
		self.assertEqual(json_parsed['true'], True)
		self.assertEqual(json_parsed['false'], False)
		self.assertEqual(json_parsed['null'], None)
		self.assertEqual(json_parsed['int64'], -1234567890)
		self.assertEqual(json_parsed['double'], -1234567890.11)

		self.assertEqual(json_parsed['foo'], 'bar')


	def test_simple_02(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		with self.assertRaises(KeyError):
			json_parsed['missing']


	def test_simple_03(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		self.assertEqual(json_parsed['document']['key4'], 40)


	def test_iter_01(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		_document = json_parsed['document']
		_dict = {}

		for key, value in _document.items():
			_dict[key] = value

		self.assertEqual({
			"key1": 1,
			"key2": "2",
			"key3": "3",
			"key4": 40,
			"key5": "50",
		}, _dict)



	def test_parser_failure_01(self):

		parser = cysimdjson.JSONParser()
		with self.assertRaises(ValueError) as context:
			json_parsed = parser.parse(b"Definitively not a JSON")
