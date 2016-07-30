from __future__ import division

from libc.string cimport memset

from generator cimport Generator
from buffernode cimport BufferNode
from bufferiter cimport BufferIter
from c_util cimport imax, imin, dmin, dmax

#from compose import Compose

include "constants.pxi"

cdef class Layer(Generator):
    cdef object inputs
    cdef object input_iters
    cdef double C

    def __cinit__(self, inputs=None):
        self.input_iters = []
        self.inputs = []
        self.C = 0
        if inputs:
            for x in inputs:
                self.add(x)

    def add(self, input):
        cdef Generator gen
        if isinstance(input, Generator):
            gen = input
            self.inputs.append(gen)
            self.input_iters.append(gen.get_iter())
            self.mlength = dmax(self.mlength, gen.mlength)
        else:
            self.C += input

    cdef bint is_stereo(self) except -1:
        if not self.inputs:
            raise IndexError('Layer object has no inputs')

        # We need to have the input Generators saved in self.inputs in order to preserve them
        # as self.input_iters is emptied out by generate()
        for x in self.inputs:
            if (<Generator?>x).is_stereo():
                return True

        return False

    cdef generate(self, BufferNode buf):
        cdef BufferIter I_iter
        cdef BufferNode I_buf

        first = True
        max_length = 0
        done_iters = []

        L = buf.get_left()
        R = buf.get_right()

        # Add in the input signals.
        for I_iter in self.input_iters:
            I_buf = I_iter.get_next()

            AL = I_buf.get_left()
            AR = I_buf.get_right()

            max_length = imax(max_length, I_buf.length)

            if first:
                first = False
                buf.copy_from(I_buf)
            else:
                if buf.stereo:
                    for i in range(I_buf.length):
                        L[i] += AL[i]
                        R[i] += AR[i]
                else:
                    for i in range(I_buf.length):
                        L[i] += AL[i]

            if not I_buf.has_more:
                done_iters.append(I_iter)

        # Add in the constant offset.
        if self.C != 0:
            if buf.stereo:
                for i in range(max_length):
                    L[i] += self.C
                    R[i] += self.C
            else:
                for i in range(max_length):
                    L[i] += self.C

        # Remove the done inputs.
        for x in done_iters:
            self.input_iters.remove(x)

        buf.length = max_length
        buf.has_more = len(self.input_iters) > 0


def mul(a, b):
    a_gen = isinstance(a, Generator)
    b_gen = isinstance(b, Generator)
    if a_gen and b_gen:
        return Multiply(a, b)
    elif a_gen:
        return ConstMultiply(a, b)
    elif b_gen:
        return ConstMultiply(b, a)
    else:
        raise TypeError


cdef class ConstMultiply(Generator):
    cdef BufferIter A
    cdef double C

    def __init__(self, Generator input, double const_factor):
        self.A = input.get_iter()
        self.C = const_factor
        self.mlength = input.mlength

    cdef bint is_stereo(self) except -1:
        return self.A.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        cdef BufferNode A_buf

        A_buf = self.A.get_next()

        # Get pointers.
        L = buf.get_left()
        R = buf.get_right()
        AL = A_buf.get_left()
        AR = A_buf.get_right()

        # Do multiply.
        if buf.stereo:
            for i in range(A_buf.length):
                L[i] = self.C * AL[i]
                R[i] = self.C * AR[i]
        else:
            for i in range(A_buf.length):
                L[i] = self.C * AL[i]

        buf.length = A_buf.length
        buf.has_more = A_buf.has_more


cdef class Multiply(Generator):
    cdef BufferIter A
    cdef BufferIter B

    def __init__(self, Generator a, Generator b):
        self.A = a.get_iter()
        self.B = b.get_iter()
        if a.mlength == 0:
            self.mlength = b.mlength
        elif b.mlength == 0:
            self.mlength = a.mlength
        else:
            self.mlength = dmin(a.mlength, b.mlength)

    cdef bint is_stereo(self) except -1:
        return self.A.generator.is_stereo() or self.B.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        cdef BufferNode A_buf, B_buf

        A_buf = self.A.get_next()
        B_buf = self.B.get_next()

        # Get pointers.
        L = buf.get_left()
        R = buf.get_right()
        AL = A_buf.get_left()
        AR = A_buf.get_right()
        BL = B_buf.get_left()
        BR = B_buf.get_right()

        length = imin(A_buf.length, B_buf.length)

        # Do multiply.
        if buf.stereo:
            for i in range(length):
                L[i] = AL[i] * BL[i]
                R[i] = AR[i] * BR[i]
        else:
            for i in range(length):
                L[i] = AL[i] * BL[i]

        buf.length = length
        buf.has_more = A_buf.has_more and B_buf.has_more
