from __future__ import division
from sig cimport Signal, BufferSignal 
#from math import cos, pi
from libc.math cimport cos, sqrt

include "constants.pxi"

cdef class Mul(BufferSignal):
    cdef Signal inp
    cdef double amount

    def __init__(self, inp, amount):
        self.inp = inp
        self.amount = amount

    cdef int generate(self) except -1:
        cdef int i, length

        length = self.inp.generate()

        for i in range(length):
            self.left[i] = self.inp.left[i] * self.amount

        return length


cdef class Pan(BufferSignal):
    cdef Signal inp
    cdef double left_gain, right_gain

    def __cinit__(self, Signal inp, double pan):
        self.make_stereo()
        
        if pan < -1 or pan > 1:
            raise ValueError('Pan must be between -1 and 1.')

        self.inp = inp

        self.left_gain = cos((1 + pan)*PI/4) * sqrt(2)
        self.right_gain = cos((1 - pan)*PI/4) * sqrt(2)

    cdef int generate(self) except -1:
        cdef int i, length

        length = self.inp.generate()

        for i in range(length):
            self.left[i] = self.inp.left[i] * self.left_gain
            self.right[i] = self.inp.right[i] * self.right_gain

        return length
