#!/bin/bash

set -e

cd /cysimdjson

rm -rf build cysimdjson.egg-info
/opt/python/cp39-cp39/bin/pip3 install Cython wheel
/opt/python/cp39-cp39/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp310-cp310/bin/pip3 install Cython wheel
/opt/python/cp310-cp310/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp311-cp311/bin/pip3 install Cython wheel
/opt/python/cp311-cp311/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp312-cp312/bin/pip3 install Cython wheel
/opt/python/cp312-cp312/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp313-cp313/bin/pip3 install setuptools Cython wheel
/opt/python/cp313-cp313/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp314-cp314/bin/pip3 install setuptools Cython wheel
/opt/python/cp314-cp314/bin/python3 setup.py sdist
/opt/python/cp314-cp314/bin/python3 setup.py bdist_wheel

cd /cysimdjson/dist
find . -name "cysimdjson-*-linux_x86_64.whl" | xargs -n 1 auditwheel repair -w /cysimdjson/dist
rm cysimdjson-*-linux_x86_64.whl
