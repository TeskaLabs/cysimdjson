# cysimdjson

Fast JSON parsing library for Python / bindings for the simdjson using Cython


## Performance tests


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
