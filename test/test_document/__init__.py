import pprint
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


	def test_parser_resut(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'r') as fo:
			json_parsed = parser.parse_string(fo.read())

		self.assertEqual(
			json_parsed.export(),
			{'document': {
				'key1': 1,
				'key2': '2',
				'key3': '3',
				'key4': 40,
				'key5': '50',
			}}
		)

		with open(os.path.join(THIS_DIR, 'document.json'), 'r') as fo:
			json_parsed1 = parser.parse_string(fo.read())

		self.assertEqual(
			json_parsed1.export(),
			{'document': {
				'key1': 1,
				'key2': '2',
				'key3': '3',
				'key4': 40,
				'key5': '50',
			}}
		)


	def test_get_01(self):

		parser = cysimdjson.JSONParser()

		with open(os.path.join(THIS_DIR, 'document.json'), 'r') as fo:
			json_parsed = parser.parse_string(fo.read())

		v1 = json_parsed.get('document')
		self.assertEqual(
			v1.export(),
			{
				'key1': 1,
				'key2': '2',
				'key3': '3',
				'key4': 40,
				'key5': '50',
			}
		)

		v2 = json_parsed.get('not-present', 'miss')
		self.assertEqual(v2, 'miss')

		v3 = json_parsed.get('not-present')
		self.assertEqual(v3, None)


	def test_loads_01(self):

		parser = cysimdjson.JSONParser()
		json_parsed = parser.loads('''{"foo":"bar"}''')

		self.assertEqual(json_parsed['foo'], 'bar')


