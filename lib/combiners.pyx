from __future__ import division

from libc.string cimport memset

#from sig cimport Signal, BufferSignal
from generator cimport Generator
from buffernode cimport BufferNode
from c_util cimport imax, imin

#from compose import Compose

include "constants.pxi"

cdef class Layer(Generator):
    cdef object inputs
    cdef double offset

    cdef object _input_bufs

    def __cinit__(self, inputs=None):
        self.inputs = []
        self._input_bufs = []
        self.offset = 0
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
            self.offset += input

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
        self._input_bufs = [(<BufferNode>x).get_next() for x in self._input_bufs]

        # Add in the input signals.
        for input_buf in self._input_bufs:
            max_length = imax(max_length, input_buf.length)

            inputL = input_buf.get_left()
            inputR = input_buf.get_right()

            if first:
                first = False
                buf.copyfrom(input_buf)
            else:
                if buf.channels == 2:
                    for i in range(input_buf.length):
                        L[i] = L[i] + inputL[i]
                        R[i] = R[i] + inputR[i]
                else:
                    for i in range(input_buf.length):
                        L[i] = L[i] + inputL[i]

            if not input_buf.has_more:
                done_bufs.append(input_buf)

        # Add in the constant offset.
        if self.offset != 0:
            if buf.channels == 2:
                for i in range(max_length):
                    L[i] += self.offset
                    R[i] += self.offset
            else:
                for i in range(max_length):
                    L[i] += self.offset

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
        inputL = self.A.get_left()
        inputR = self.A.get_right()

        # Do multiply.
        if buf.channels == 2:
            for i in range(self.A.length):
                L[i] = self.C * inputL[i]
                R[i] = self.C * inputR[i]
        else:
            for i in range(self.A.length):
                L[i] = self.C * inputL[i]

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
        left = buf.get_left()
        right = buf.get_right()
        A_left = self.A.get_left()
        A_right = self.A.get_right()
        B_left = self.B.get_left()
        B_right = self.B.get_right()

        length = imin(self.A.length, self.B.length)

        # Do multiply.
        if buf.channels == 2:
            for i in range(length):
                left[i] = A_left[i] * B_left[i]
                right[i] = A_right[i] * B_right[i]
        else:
            for i in range(length):
                left[i] = A_left[i] * B_left[i]

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
