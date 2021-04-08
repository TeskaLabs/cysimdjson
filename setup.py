import re
import os
import pathlib
import subprocess

import glob

from setuptools import setup, Extension
from setuptools.command.build_py import build_py

from Cython.Build import cythonize


extensions = [
	Extension(
		"cysimdjson",
		[
			'cysimdjson/cysimdjson.pyx',
			'cysimdjson/simdjson/simdjson.cpp',
			'cysimdjson/pysimdjson/errors.cpp',
		],
		language="c++",
		extra_compile_args=[
			"-std=c++17",  # for std::string_view class that became standard in C++17
			"-O3"
		],
	)
]

setup(
	name='cysimdjson',
	version="21.4a4",
	description='Cython-based wrapper for SIMDJSON',
	author='TeskaLabs Ltd',
	author_email='info@teskalabs.com',
	platforms='any',
	classifiers=[
		'Programming Language :: Python :: 3.7',
		'Programming Language :: Python :: 3.8',
		'Programming Language :: Python :: 3.9',
	],
	packages=[
		"cysimdjson",
	],
	project_urls={
		"Source": "https://github.com/TeskaLabs/cysimdjson",
	},
	install_requires=[
	],
	ext_modules=cythonize(extensions),
)
