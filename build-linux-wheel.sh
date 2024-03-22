cd /cysimdjson

rm -rf build cysimdjson.egg-info
/opt/python/cp36-cp36m/bin/pip3 install Cython wheel
/opt/python/cp36-cp36m/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp37-cp37m/bin/pip3 install Cython wheel
/opt/python/cp37-cp37m/bin/python3 setup.py bdist_wheel

rm -rf build cysimdjson.egg-info
/opt/python/cp38-cp38/bin/pip3 install Cython wheel
/opt/python/cp38-cp38/bin/python3 setup.py bdist_wheel

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

cd /cysimdjson/dist
find . -name "cysimdjson-*-linux_x86_64.whl" | xargs -n 1 auditwheel repair -w /cysimdjson/dist
rm cysimdjson-*-linux_x86_64.whl
