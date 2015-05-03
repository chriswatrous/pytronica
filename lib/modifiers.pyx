from __future__ import division
#from math import cos, pi
from libc.math cimport cos, sqrt

from generator cimport Generator
from buffernode cimport BufferNode

include "constants.pxi"

# Measured at 91us/s with NoOp as input.
cdef class Pan(Generator):
    cdef BufferNode inp_buf
    cdef double left_gain, right_gain

    def __cinit__(self, Generator inp, double pan):
        if pan < -1 or pan > 1:
            raise ValueError('Pan must be between -1 and 1.')

        self.inp_buf = inp.get_starter()

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

    cdef bint is_stereo(self) except -1:
        return True

    cdef generate(self, BufferNode buf):
        cdef int i
        cdef double *left
        cdef double *right
        cdef BufferNode inp_buf

        self.inp_buf = self.inp_buf.get_next()

        # Get pointers to the buffers.
        left = buf.get_left()
        right = buf.get_right()
        inp_left = self.inp_buf.get_left()
        inp_right = self.inp_buf.get_right()

        # Fill the buffers.
        for i in range(self.inp_buf.length):
            left[i] = inp_left[i] * self.left_gain
            right[i] = inp_right[i] * self.right_gain

        buf.length = self.inp_buf.length
        buf.has_more = self.inp_buf.has_more
