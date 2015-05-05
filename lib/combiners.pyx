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
        cdef int i, max_length
        cdef double *left
        cdef double *right
        cdef double *input_left
        cdef double *input_right
        cdef bint first

        first = True
        max_length = 0
        done_bufs = []

        left = buf.get_left()
        right = buf.get_right()

        # Get next set of input bufers.
        self._input_bufs = [(<BufferNode>x).get_next() for x in self._input_bufs]

        # Add in the input signals.
        for input_buf in self._input_bufs:
            max_length = imax(max_length, input_buf.length)

            input_left = input_buf.get_left()
            input_right = input_buf.get_right()

            if first:
                first = False
                buf.copyfrom(input_buf)
            else:
                if buf.channels == 2:
                    for i in range(input_buf.length):
                        left[i] = left[i] + input_left[i]
                        right[i] = right[i] + input_right[i]
                else:
                    for i in range(input_buf.length):
                        #left[i] += input_left[i]
                        left[i] = left[i] + input_left[i]

            if not input_buf.has_more:
                done_bufs.append(input_buf)

        # Add in the constant offset.
        if self.offset != 0:
            if buf.channels == 2:
                for i in range(max_length):
                    left[i] += self.offset
                    right[i] += self.offset
            else:
                for i in range(max_length):
                    left[i] += self.offset

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
    cdef Generator input
    cdef BufferNode input_buf
    cdef double const_factor

    def __init__(self, input, const_factor):
        self.input = input
        self.input_buf = input.get_starter()
        self.const_factor = const_factor

    cdef bint is_stereo(self) except -1:
        return self.input.is_stereo()

    cdef generate(self, BufferNode buf):
        cdef int i, length
        cdef double *left
        cdef double *right
        cdef double *input_left
        cdef double *input_right

        self.input_buf = self.input_buf.get_next()

        # Get pointers.
        left = buf.get_left()
        right = buf.get_right()
        input_left = self.input_buf.get_left()
        input_right = self.input_buf.get_right()

        # Do multiply.
        if buf.channels == 2:
            for i in range(self.input_buf.length):
                left[i] = self.const_factor * input_left[i]
                right[i] = self.const_factor * input_right[i]
        else:
            for i in range(self.input_buf.length):
                left[i] = self.const_factor * input_left[i]

        buf.length = self.input_buf.length
        buf.has_more = self.input_buf.has_more


cdef class Multiply(Generator):
    cdef BufferNode A
    cdef BufferNode B

    def __init__(self, a, b):
        self.A = a.get_starter()
        self.B = b.get_starter()

    cdef bint is_stereo(self) except -1:
        return self.A.generator.is_stereo() or self.B.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        cdef int i, length
        cdef double *left
        cdef double *right
        cdef double *A_left
        cdef double *A_right
        cdef double *B_left
        cdef double *B_right

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
