#! /usr/bin/python
import sys
from distutils.core import setup
from Cython.Build import cythonize

# Set up default arguments if called with no arguments, since setup.py will normally just give an error
# if called with no arguments.
if len(sys.argv) == 1:
    sys.argv.extend(['build_ext', '--inplace'])

setup(ext_modules=cythonize("audio.pyx"))
