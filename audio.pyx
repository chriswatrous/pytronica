import cython
cimport cython
import numpy as np
cimport numpy as np
import math
from numbers import Number
import re

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
    cdef double step = 2 * math.pi * freq / srate
    ah.sin_helper(&clip[0], array_length, step)
    return clip


def compose(clips_and_offsets):
    clips_and_offsets = ((x, 0) if type(x) == np.ndarray else x for x in clips_and_offsets)
    clips_and_offsets = ((clip, int(offset * srate)) for (clip, offset) in clips_and_offsets)
    total_length = max(clip.size + offset for (clip, offset) in clips_and_offsets)
    result = np.zeros(total_length)
    for clip, offset in clips_and_offsets:
        result[offset : offset + clip.size] += clip
    return result


def normalize(clip):
    return clip / np.max(np.abs(clip))
