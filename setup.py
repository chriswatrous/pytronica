#!  /usr/bin/python

import sys, numpy
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

extensions = [Extension('synth', ['synth.pyx', 'audiohelpers.c'])]

setup(
    ext_modules = cythonize(extensions),
    include_dirs = numpy.get_include(),
)
