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
    clips_and_offsets = [(x, 0) if type(x) == np.ndarray else x for x in clips_and_offsets]
    clips_and_offsets = [(clip, int(offset * srate)) for (clip, offset) in clips_and_offsets]
    total_length = max(clip.size + offset for (clip, offset) in clips_and_offsets)
    result = np.zeros(total_length)
    for clip, offset in clips_and_offsets:
        result[offset : offset + clip.size] += clip
    return result


def normalize(clip):
    return clip / np.max(np.abs(clip))


def ptof(pitch):
    return 440 * math.pow(2.0, (pitch - 69.0) / 12.0)


def ftop(freq):
    return math.log(freq / 440.0, 2) * 12 + 69


def ps(pitch_string):
    return [_pname_to_pnum(x) for x in pitch_string.split()]


pitch_classes = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11,
                 'cb': -1, 'db': 1, 'eb': 3, 'fb': 4, 'gb': 6, 'ab': 8, 'bb': 10,
                 'c#': 1, 'd#': 3, 'e#': 5, 'f#': 6, 'g#': 8, 'a#': 10, 'b#': 12}

def _pname_to_pnum(pname):
    match = re.match('([a-zA-Z#]+)(-?[0-9]+)', pname)
    if not match:
        raise SynthError("Bad pitch name '{}'".format(pname))
    pitch_class, octave = match.groups()
    return pitch_classes[pitch_class.lower()] + 12 * int(octave) + 12

class SynthError(Exception):
    pass
