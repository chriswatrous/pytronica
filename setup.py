#!  /usr/bin/python

import sys, numpy
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

if len(sys.argv) == 1:
    sys.argv.extend(['build_ext', '--inplace'])

extensions = [Extension('audio', ['audio.pyx', 'audiohelpers.c'])]

setup(
    ext_modules = cythonize(extensions),
    include_dirs = numpy.get_include(),
)
