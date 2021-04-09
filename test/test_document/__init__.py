import unittest
import os

import cysimdjson

THIS_DIR = os.path.dirname(os.path.abspath(__file__))


class JSONDocumentTestCases(unittest.TestCase):

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



	def test_contains_01(self):
		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'rb') as fo:
			json_parsed = parser.parse(fo.read())

		self.assertEqual("notdocument" in json_parsed, False)
		self.assertEqual("document" in json_parsed, True)


	def test_parser_failure_01(self):

		parser = cysimdjson.JSONParser()
		with self.assertRaises(ValueError) as context:
			json_parsed = parser.parse(b"Definitively not a JSON")



	def test_string_01(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'r') as fo:
			json_parsed = parser.parse_string(fo.read())
