import timeit
import pathlib

jsonpath = pathlib.Path(__file__).parent / "jsonexamples"

def benchmark(name, what, number):
	dt = timeit.timeit(what, number=number)
	return (name, number, dt)


def print_results(jsonfile, results):
	jsonfile_size = jsonfile.stat().st_size

	print("-" * 64)
	print("# '{}' {} bytes".format(jsonfile, jsonfile_size))
	print("-" * 64)
	maxeps = max(number / dt for _, number, dt in results)
	results = sorted(results, key=lambda x: x[1] / x[2], reverse=True)

	for name, number, dt in results:
		eps = number / dt
		print("* {:<20} {:>18} ({:6.2f}) {:8.2f} MB/s".format(
			name,
			"{:0.2f} EPS".format(eps),
			maxeps / eps,
			(eps * jsonfile_size) / (1000 * 1000)
		))

	print("-" * 64)
	print("")


def perftest_orjson_parser(jsonfile, number):
	import orjson

	with open(jsonfile, 'rb') as f:
		jsonb = f.read()

	return benchmark(
		"orjson loads",
		lambda: orjson.loads(jsonb),
		number=number
	)


def perftest_pysimdjson_parser(jsonfile, number):
	import simdjson

	with open(jsonfile, 'rb') as f:
		jsonb = f.read()

	parser = simdjson.Parser()

	return benchmark(
		"pysimdjson parse",
		lambda: parser.parse(jsonb),
		number=number
	)


def perftest_libpy_simdjson_parser(jsonfile, number):
	import libpy_simdjson

	with open(jsonfile, 'rb') as f:
		jsonb = f.read()

	return benchmark(
		"libpy_simdjson loads",
		lambda: libpy_simdjson.loads(jsonb),
		number=number
	)


def perftest_pythonjson_loads(jsonfile, number):
	import json

	with open(jsonfile, 'r') as f:
		jsons = f.read()

	return benchmark(
		"python json loads",
		lambda: json.loads(jsons),
		number=number
	)


def perftest_cysimdjson_parse(jsonfile, number):
	import cysimdjson

	with open(jsonfile, 'rb') as f:
		jsonb = f.read()

	parser = cysimdjson.JSONParser()

	return benchmark(
		"cysimdjson parse",
		lambda: parser.parse(jsonb),
		number=number
	)


def main():
	test_set = [
		perftest_orjson_parser,
		perftest_pysimdjson_parser,
	#	perftest_libpy_simdjson_parser,
		perftest_pythonjson_loads,
		perftest_cysimdjson_parse,
	#	perftest_cysimdjson_pad_parse,
	]

	jsonfile = jsonpath / "test.json"
	number = 50_000
	results = list(test(jsonfile, number) for test in test_set)
	print_results(jsonfile, results)

	jsonfile = jsonpath / "twitter.json"
	number = 3_000
	results = list(test(jsonfile, number) for test in test_set)
	print_results(jsonfile, results)

	jsonfile = jsonpath / "canada.json"
	number = 500
	results = list(test(jsonfile, number) for test in test_set)
	print_results(jsonfile, results)

	jsonfile = jsonpath / "gsoc-2018.json"
	number = 50
	results = list(test(jsonfile, number) for test in test_set)
	print_results(jsonfile, results)

	jsonfile = jsonpath / "verysmall.json"
	number = 400_000
	results = list(test(jsonfile, number) for test in test_set)
	print_results(jsonfile, results)


if __name__ == '__main__':
	main()
