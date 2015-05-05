from __future__ import division
#from math import cos, pi
from libc.math cimport cos, sqrt

from generator cimport Generator
from buffernode cimport BufferNode

include "constants.pxi"

# Measured at 91us/s with NoOp as input.
cdef class Pan(Generator):
    cdef BufferNode A
    cdef double LC, RC

    def __cinit__(self, Generator inp, double pan):
        if pan < -1 or pan > 1:
            raise ValueError('Pan must be between -1 and 1.')

        self.A = inp.get_starter()

        # "Circualar" panning law. -3dB in the middle.
        # This one sounds better than triangle.
        self.LC = cos((1 + pan)*PI/4) * sqrt(2)
        self.RC = cos((1 - pan)*PI/4) * sqrt(2)

        # "Triangle" panning law. -6dB in the middle
        #self.LC = 1 - pan
        #self.RC = 1 + pan

        # 0 dB in the middle.
        # This one sounds the best and is cheap.
        # Changed my mind. Cirular sounds better.
        #if pan >= 0:
            #self.LC = 1 - pan
            #self.RC = 1
        #else:
            #self.LC = 1
            #self.RC = 1 + pan

    cdef bint is_stereo(self) except -1:
        return True

    cdef generate(self, BufferNode buf):
        self.A = self.A.get_next()

        # Get pointers to the buffers.
        L = buf.get_left()
        R = buf.get_right()
        inputL = self.A.get_left()
        inputR = self.A.get_right()

        # Fill the buffers.
        for i in range(self.A.length):
            L[i] = inputL[i] * self.LC
            R[i] = inputR[i] * self.RC

        buf.length = self.A.length
        buf.has_more = self.A.has_more
