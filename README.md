# cysimdjson

Fast JSON parsing library for Python, 7-12 times faster than standard Python JSON parser.  
It is Python bindings for the [simdjson](https://simdjson.org) using [Cython](https://cython.org).

Standard [Python JSON parser](https://docs.python.org/3/library/json.html) (`json.load()` etc.) is relatively slow,
and if you need to parse large JSON files or a large number of small JSON files,
it may represent a significant bottleneck.

Whilst there are other fast Python JSON parsers, such as [pysimdjson](https://github.com/TkTech/pysimdjson), [libpy_simdjson](https://github.com/gerrymanoim/libpy_simdjson) or [orjson](https://github.com/ijl/orjson), they don't reach the raw speed that is provided by the brilliant [SIMDJSON](https://simdjson.org) project. SIMDJSON is C++ JSON parser based on [SIMD instructions](https://en.wikipedia.org/wiki/SIMD), reportedly the fastest JSON parser on the planet.

[![Test in Python 3.7](https://github.com/TeskaLabs/cysimdjson/actions/workflows/py37.yaml/badge.svg)](https://github.com/TeskaLabs/cysimdjson/actions/workflows/py37.yaml)
[![Test in Python 3.8](https://github.com/TeskaLabs/cysimdjson/actions/workflows/py38.yaml/badge.svg)](https://github.com/TeskaLabs/cysimdjson/actions/workflows/py38.yaml)
[![Test in Python 3.9](https://github.com/TeskaLabs/cysimdjson/actions/workflows/py39.yaml/badge.svg)](https://github.com/TeskaLabs/cysimdjson/actions/workflows/py39.yaml)


## Usage

```python
import cysimdjson

json_bytes = b'''
{
  "foo": [1,2,[3]]
}
'''

parser = cysimdjson.JSONParser()
json_element = parser.parse(json_bytes)

# Access using JSON Pointer
print(json_element.at_pointer("/foo/2/0"))
```

_Note: `parser` object can be reused for maximum performance._


### Pythonic drop-in API

```python
parser = cysimdjson.JSONParser()
json_parsed = parser.loads(json_bytes)

# Access using JSON Pointer
print(json_parsed.json_parsed['foo'])
```

The `json_parsed` is a read-only dictionary-like object, that provides an access to JSON data.


## Trade-offs

The speed of `cysimdjson` is based on these assumptions:

1) The output of the parser is read-only, you cannot modify it
2) The output of the parser is not Python dictionary, but lazily evaluated dictionary-like object
3) If you convert the parser output into a Python dictionary, you will lose the speed

If your design is not aligned with these assumptions, `cysimdjson` is not a good choice.


## Documentation

`JSONParser.parse(json_bytes)`

Parse JSON `json_bytes`, represented as `bytes`.


`JSONParser.parse_in_place(bytes)`

Parse JSON `json_bytes`, represented as `bytes`, assuming that there is a padding expected by SIMDJSON.
This is the fastest parsing variant.


`JSONParser.parse_string(string)`

Parse JSON `json_bytes`, represented as `str` (string).


`JSONParser.load(path)`


## Installation

```
pip3 install cysimdjson
```

Project `cysimdjson` is distributed via PyPI: https://pypi.org/project/cysimdjson/ .

If you want to install `cysimdjson` from source, you need to install Cython first: `pip3 install cython`.


## Performance

```
----------------------------------------------------------------
# 'jsonexamples/test.json' 2397 bytes
----------------------------------------------------------------
* cysimdjson parse          510291.81 EPS (  1.00)  1223.17 MB/s
* libpy_simdjson loads      374615.54 EPS (  1.36)   897.95 MB/s
* pysimdjson parse          362195.46 EPS (  1.41)   868.18 MB/s
* orjson loads              110615.70 EPS (  4.61)   265.15 MB/s
* python json loads          72096.80 EPS (  7.08)   172.82 MB/s
----------------------------------------------------------------

SIMDJSON: 543335.93 EPS, 1241.52 MB/s
```

```
----------------------------------------------------------------
# 'jsonexamples/twitter.json' 631515 bytes
----------------------------------------------------------------
* cysimdjson parse            2556.10 EPS (  1.00)  1614.22 MB/s
* libpy_simdjson loads        2444.53 EPS (  1.05)  1543.76 MB/s
* pysimdjson parse            2415.46 EPS (  1.06)  1525.40 MB/s
* orjson loads                 387.11 EPS (  6.60)   244.47 MB/s
* python json loads            278.63 EPS (  9.17)   175.96 MB/s
----------------------------------------------------------------

SIMDJSON: 2536.16 EPS,  1527.28 MB/s
```

```
----------------------------------------------------------------
# 'jsonexamples/canada.json' 2251051 bytes
----------------------------------------------------------------
* cysimdjson parse             284.67 EPS (  1.00)   640.81 MB/s
* pysimdjson parse             284.62 EPS (  1.00)   640.70 MB/s
* libpy_simdjson loads         277.13 EPS (  1.03)   623.84 MB/s
* orjson loads                  81.80 EPS (  3.48)   184.13 MB/s
* python json loads             22.52 EPS ( 12.64)    50.68 MB/s
----------------------------------------------------------------

SIMDJSON: 307.95 EPS, 661.08 MB/s
```

```
----------------------------------------------------------------
# 'jsonexamples/gsoc-2018.json' 3327831 bytes
----------------------------------------------------------------
* cysimdjson parse             775.61 EPS (  1.00)  2581.09 MB/s
* pysimdjson parse             743.67 EPS (  1.04)  2474.81 MB/s
* libpy_simdjson loads         654.15 EPS (  1.19)  2176.88 MB/s
* orjson loads                 166.67 EPS (  4.65)   554.66 MB/s
* python json loads            113.72 EPS (  6.82)   378.43 MB/s
----------------------------------------------------------------

SIMDJSON: 703.59 EPS, 2232.92 MB/s
```

```
----------------------------------------------------------------
# 'jsonexamples/verysmall.json' 7 bytes
----------------------------------------------------------------
* cysimdjson parse         3972376.53 EPS (  1.00)    27.81 MB/s
* orjson loads             3637369.63 EPS (  1.09)    25.46 MB/s
* libpy_simdjson loads     1774211.19 EPS (  2.24)    12.42 MB/s
* pysimdjson parse          977530.90 EPS (  4.06)     6.84 MB/s
* python json loads         527932.65 EPS (  7.52)     3.70 MB/s
----------------------------------------------------------------

SIMDJSON: 3799392.10 EPS
```

CPU: AMD EPYC 7452

More performance testing:

 * [Apple M1](https://github.com/TeskaLabs/cysimdjson/wiki/Performance-on-Apple-M1): > 1M EPS, > 3GB/s



### Tests are reproducible

```
pip3 install orjson
pip3 install pysimdjson
pip3 install libpy_simdjson
python3 setup.py build_ext --inplace
PYTHONPATH=. python3 ./perftest/test_benchmark.py
```

## Manual build

```
python3 setup.py build_ext --inplace
```
