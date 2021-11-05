#!/bin/sh

docker run --rm -it \
	-v $(pwd):/cysimdjson \
	quay.io/pypa/manylinux2014_x86_64 \
	/bin/bash /cysimdjson/build-linux-wheel.sh
