# cysimdjson

Fast JSON parsing library for Python.  
Python bindings for the [simdjson](https://simdjson.org) using [Cython](https://cython.org).

Standard [Python JSON parser](https://docs.python.org/3/library/json.html) (`json.load()` etc.) is relatively slow,
and if you need to parse large JSON files or a large number of small JSON files,
it may represent a significant bottleneck.

Whilst there are other fast Python JSON parsers, such as [pysimdjson](https://github.com/TkTech/pysimdjson), [libpy_simdjson](https://github.com/gerrymanoim/libpy_simdjson) or [orjson](https://github.com/ijl/orjson), they don't reach the raw speed that is provided by the brilliant [SIMDJSON](https://simdjson.org) project. SIMDJSON is C++ JSON parser based on SIMD instructions, reportedly the fastest JSON parser on the planet.


## Usage

```
import cysimdjson

parser = cysimdjson.JSONParser()
json_parsed = parser.parse(json_bytes)
```

_Note: `parser` object can be reused for maximum performance._

The `json_parsed` is a read-only dictionary-like object, that provides an access to JSON data.


## Installation

```
pip3 install cython
pip3 install git+https://github.com/TeskaLabs/cysimdjson.git
```

_Note: cysimdjson will be released to pypi shortly._


## Performance

```
----------------------------------------------------------------
# 'jsonexamples/test.json' 2397 bytes
----------------------------------------------------------------
* cysimdjson parse          511049.33 EPS (  1.00)  1224.99 MB/s
* cysimdjson pad parse      507097.22 EPS (  1.01)  1215.51 MB/s
* pysimdjson parse          363209.57 EPS (  1.41)   870.61 MB/s
* orjson loads              107967.30 EPS (  4.73)   258.80 MB/s
* python json loads          73514.79 EPS (  6.95)   176.21 MB/s
----------------------------------------------------------------
```

```
----------------------------------------------------------------
# 'jsonexamples/twitter.json' 631515 bytes
----------------------------------------------------------------
* cysimdjson pad parse        2677.94 EPS (  1.00)  1691.16 MB/s
* cysimdjson parse            2559.72 EPS (  1.05)  1616.50 MB/s
* pysimdjson parse            2419.89 EPS (  1.11)  1528.20 MB/s
* orjson loads                 393.11 EPS (  6.81)   248.26 MB/s
* python json loads            294.79 EPS (  9.08)   186.16 MB/s
----------------------------------------------------------------
```

```
----------------------------------------------------------------
# 'jsonexamples/canada.json' 2251051 bytes
----------------------------------------------------------------
* cysimdjson pad parse         289.96 EPS (  1.00)   652.72 MB/s
* cysimdjson parse             285.24 EPS (  1.02)   642.10 MB/s
* pysimdjson parse             284.43 EPS (  1.02)   640.27 MB/s
* orjson loads                  82.01 EPS (  3.54)   184.60 MB/s
* python json loads             22.62 EPS ( 12.82)    50.92 MB/s
----------------------------------------------------------------
```

```
----------------------------------------------------------------
# 'jsonexamples/gsoc-2018.json' 3327831 bytes
----------------------------------------------------------------
* cysimdjson pad parse         842.28 EPS (  1.00)  2802.95 MB/s
* cysimdjson parse             760.07 EPS (  1.11)  2529.39 MB/s
* pysimdjson parse             746.99 EPS (  1.13)  2485.86 MB/s
* orjson loads                 168.17 EPS (  5.01)   559.64 MB/s
* python json loads            113.73 EPS (  7.41)   378.48 MB/s
----------------------------------------------------------------
```

```
----------------------------------------------------------------
# 'jsonexamples/verysmall.json' 7 bytes
----------------------------------------------------------------
* cysimdjson parse         4095400.05 EPS (  1.00)    28.67 MB/s
* orjson loads             3652468.43 EPS (  1.12)    25.57 MB/s
* cysimdjson pad parse     2857706.44 EPS (  1.43)    20.00 MB/s
* pysimdjson parse         1014137.32 EPS (  4.04)     7.10 MB/s
* python json loads         535848.69 EPS (  7.64)     3.75 MB/s
----------------------------------------------------------------
```

CPU: AMD EPYC 7452


### Tests are reproducible

```
pip3 install orjson
pip3 install pysimdjson
pip3 install libpy_simdjson
python3 setup.py build_ext --inplace
PYTHONPATH=. python3 ./test/test_benchmark.py
```

## Manual build

```
python3 setup.py build_ext --inplace
```
