import cython
cimport cython
import numpy as np
cimport numpy as np
import math
from numbers import Number
import re

cimport audiohelpers as ah

from clip import Clip, srate


def simple_saw_osc(double freq, double length):
    cdef int array_length = int(srate * length)
    cdef np.ndarray[np.double_t, ndim=1] data = np.empty(array_length, dtype=np.double)
    cdef double step = 2 * freq / srate
    ah.simple_saw_helper(&data[0], array_length, step)
    return Clip(data)


def sin_osc(double freq, double length):
    cdef int array_length = int(srate * length)
    cdef np.ndarray[np.double_t, ndim=1] data = np.empty(array_length, dtype=np.double)
    cdef double step = 2 * math.pi * freq / srate
    ah.sin_helper(&data[0], array_length, step)
    return Clip(data)


#def compose(clips_and_offsets):
    #clips_and_offsets = ((x, 0) if type(x) == np.ndarray else x for x in clips_and_offsets)
    #clips_and_offsets = ((clip, int(offset * srate)) for (clip, offset) in clips_and_offsets)
    #total_length = max(clip.size + offset for (clip, offset) in clips_and_offsets)
    #result = np.zeros(total_length)
    #for clip, offset in clips_and_offsets:
        #result[offset : offset + clip.size] += clip
    #return result


#def compose(A, B, offset=0):
    #offset = int(offset * srate)
    #if A == None:
        #new_clip = np.zeros(B.size)
        #new_clip[offset : B.size + offset] = B
        #return new_clip
    #else:
        #new_clip = np.zeros(max(A.size, B.size + offset))
        #new_clip[0 : A.size] = A
        #new_clip[offset : B.size + offset] += B
        #return new_clip


def normalize(clip):
    return clip / np.max(np.abs(clip))
