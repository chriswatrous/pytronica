from __future__ import division

from libc.string cimport memset

from generator cimport Generator
from buffernode cimport BufferNode
from c_util cimport imax, imin

#from compose import Compose

include "constants.pxi"

cdef class Layer(Generator):
    cdef object inputs
    cdef double C

    cdef object _input_bufs

    def __cinit__(self, inputs=None):
        self.inputs = []
        self._input_bufs = []
        self.C = 0
        if inputs:
            map(self.add, inputs)

    def add(self, input):
        cdef Generator gen
        cdef Layer layer

        if issubclass(type(input), Generator):
            gen = input
            self.inputs.append(gen)
            self._input_bufs.append(gen.get_starter())
        else:
            self.C += input

    cdef bint is_stereo(self) except -1:
        cdef Generator gen

        if not self.inputs:
            raise IndexError('Layer object has no inputs')

        for gen in self.inputs:
            if gen.is_stereo():
                return True

        return False

    cdef generate(self, BufferNode buf):
        cdef BufferNode input_buf

        first = True
        max_length = 0
        done_bufs = []

        L = buf.get_left()
        R = buf.get_right()

        # Get next set of input bufers.
        for i in range(len(self._input_bufs)):
            self._input_bufs[i] = self._input_bufs[i].get_next()

        # Add in the input signals.
        for input_buf in self._input_bufs:
            max_length = imax(max_length, input_buf.length)

            AL = input_buf.get_left()
            AR = input_buf.get_right()

            if first:
                first = False
                buf.copyfrom(input_buf)
            else:
                if buf.channels == 2:
                    for i in range(input_buf.length):
                        L[i] += AL[i]
                        R[i] += AR[i]
                else:
                    for i in range(input_buf.length):
                        L[i] += AL[i]

            if not input_buf.has_more:
                done_bufs.append(input_buf)

        # Add in the constant offset.
        if self.C != 0:
            if buf.channels == 2:
                for i in range(max_length):
                    L[i] += self.C
                    R[i] += self.C
            else:
                for i in range(max_length):
                    L[i] += self.C

        # Remove the done inputs.
        for x in done_bufs:
            self._input_bufs.remove(x)

        buf.length = max_length
        buf.has_more = len(self._input_bufs) > 0


def mul(a, b):
    a_gen = issubclass(type(a), Generator)
    b_gen = issubclass(type(b), Generator)
    if a_gen and b_gen:
        return Multiply(a, b)
    elif a_gen:
        return ConstMultiply(a, b)
    elif b_gen:
        return ConstMultiply(b, a)
    else:
        raise TypeError


cdef class ConstMultiply(Generator):
    cdef BufferNode A
    cdef double C

    def __init__(self, input, const_factor):
        self.A = input.get_starter()
        self.C = const_factor

    cdef bint is_stereo(self) except -1:
        return self.A.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        self.A = self.A.get_next()

        # Get pointers.
        L = buf.get_left()
        R = buf.get_right()
        AL = self.A.get_left()
        AR = self.A.get_right()

        # Do multiply.
        if buf.channels == 2:
            for i in range(self.A.length):
                L[i] = self.C * AL[i]
                R[i] = self.C * AR[i]
        else:
            for i in range(self.A.length):
                L[i] = self.C * AL[i]

        buf.length = self.A.length
        buf.has_more = self.A.has_more


cdef class Multiply(Generator):
    cdef BufferNode A
    cdef BufferNode B

    def __init__(self, a, b):
        self.A = a.get_starter()
        self.B = b.get_starter()

    cdef bint is_stereo(self) except -1:
        return self.A.generator.is_stereo() or self.B.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        self.A = self.A.get_next()
        self.B = self.B.get_next()

        # Get pointers.
        L = buf.get_left()
        R = buf.get_right()
        AL = self.A.get_left()
        AR = self.A.get_right()
        BL = self.B.get_left()
        BR = self.B.get_right()

        length = imin(self.A.length, self.B.length)

        # Do multiply.
        if buf.channels == 2:
            for i in range(length):
                L[i] = AL[i] * BL[i]
                R[i] = AR[i] * BR[i]
        else:
            for i in range(length):
                L[i] = AL[i] * BL[i]

        buf.length = length
        buf.has_more = self.A.has_more and self.B.has_more


#cdef class Chain(Signal):
    #cdef Signal comp
#
    #def __init__(self, inputs=None):
        #self.comp = Compose()
        #self.mlength = 0
#
        #if inputs:
            #for input in inputs:
                #self.add(input)
#
    #def add(self, Signal input):
        #if input.mlength == None:
            #raise ValueError('mlength not set')
        #self.comp.add(input, self.mlength)
        #self.mlength += input.mlength
#
        ## The Compose might switch from mono to stereo after adding a stereo Signal.
        #self.left = self.comp.left
        #self.right = self.comp.right
#
    #cdef int generate(self) except -1:
        #return self.comp.generate()
