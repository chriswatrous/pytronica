import cython
cimport cython
import numpy as np
cimport numpy as np
from math import pi

cimport audiohelpers as ah

srate = 48000

def simple_saw_osc(double freq, double length):
    cdef int array_length = int(srate * length)
    cdef np.ndarray[np.double_t, ndim=1] clip = np.empty(array_length, dtype=np.double)
    cdef double step = 2 * freq / srate
    ah.simple_saw_helper(&clip[0], array_length, step)
    return clip

def sin_osc(double freq, double length):
    cdef int array_length = int(srate * length)
    cdef np.ndarray[np.double_t, ndim=1] clip = np.empty(array_length, dtype=np.double)
    cdef double step = 2 * pi * freq / srate
    ah.sin_helper(&clip[0], array_length, step)
    return clip
