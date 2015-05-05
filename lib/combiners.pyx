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

        #if issubclass(type(input), Layer):
            #layer = input
            #map(self.add, layer.inputs)
            #self.offset += layer.offset
        #elif issubclass(type(input), Generator):
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


#cdef class Multiply(BufferSignal):
    #cdef Signal inp1, inp2
    #cdef double constant_factor
#
    #def __init__(self, inp1, inp2):
        #cdef Signal sig
#
        #inputs = []
#
        #self.constant_factor = 1
        #for input in [inp1, inp2]:
            #if issubclass(type(input), Signal):
                #inputs.append(input)
            #else:
                #self.constant_factor = input
#
        #if len(inputs) == 0:
            #raise TypeError('At least one input must be a Signal.')
#
        #if len(inputs) == 2:
            #self.inp1, self.inp2 = inputs
        #else:
            #self.inp1 = inputs[0]
            #self.inp2 = None
#
        #for sig in inputs:
            #if sig.is_stereo():
                #self.make_stereo()
                #break
#
    #cdef int generate(self) except -1:
        #cdef int i, length
#
        #if self.inp2:
            #length = imin(self.inp1.generate(), self.inp2.generate())
            #for i in range(length):
                #self.left[i] = self.inp1.left[i] * self.inp2.left[i]
            #if self.is_stereo():
                #for i in range(length):
                    #self.right[i] = self.inp1.right[i] * self.inp2.right[i]
        #else:
            #length = self.inp1.generate()
            #for i in range(length):
                #self.left[i] = self.inp1.left[i] * self.constant_factor
            #if self.is_stereo():
                #for i in range(length):
                    #self.right[i] = self.inp1.right[i] * self.constant_factor
#
        #return length
#
#
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
