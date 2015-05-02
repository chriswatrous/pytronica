from __future__ import division
from sig cimport Signal, BufferSignal
#from math import cos, pi
from libc.math cimport cos, sqrt

include "constants.pxi"

cdef class Pan(BufferSignal):
    cdef Signal inp
    cdef double left_gain, right_gain

    def __cinit__(self, Signal inp, double pan):
        self.make_stereo()

        if pan < -1 or pan > 1:
            raise ValueError('Pan must be between -1 and 1.')

        self.inp = inp

        # "Circualar" panning law. -3dB in the middle.
        # This one sounds better than triangle.
        self.left_gain = cos((1 + pan)*PI/4) * sqrt(2)
        self.right_gain = cos((1 - pan)*PI/4) * sqrt(2)

        # "Triangle" panning law. -6dB in the middle
        #self.left_gain = 1 - pan
        #self.right_gain = 1 + pan

        # 0 dB in the middle.
        # This one sounds the best and is cheap.
        # Changed my mind. Cirular sounds better.
        #if pan >= 0:
            #self.left_gain = 1 - pan
            #self.right_gain = 1
        #else:
            #self.left_gain = 1
            #self.right_gain = 1 + pan

    cdef int generate(self) except -1:
        cdef int i, length

        length = self.inp.generate()

        for i in range(length):
            self.left[i] = self.inp.left[i] * self.left_gain
            self.right[i] = self.inp.right[i] * self.right_gain

        return length
