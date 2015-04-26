from libc.string cimport memset

from sig cimport Signal, BufferSignal
from c_util cimport imax, imin

include "constants.pxi"

cdef class Layer(BufferSignal):
    cdef object inputs
    cdef double offset

    def __init__(self, *args):
        cdef Signal sig

        self.inputs = []
        self.offset = 0

        for arg in args:
            self.add(arg)

    def add(self, inp):
        cdef Signal sig
        cdef Layer layer

        if hasattr(inp, '__iter__'):
            for x in inp:
                self.add(x)
        elif issubclass(type(inp), Layer):
            layer = inp
            self.add(layer.inputs)
            self.offset += layer.offset
        elif issubclass(type(inp), Signal):
            sig = inp
            self.inputs.append(sig)
            if not self.is_stereo() and sig.is_stereo():
                self.make_stereo()
        else:
            self.offset += inp

    cdef int generate(self) except -1:
        cdef Signal inp
        cdef int i, length, max_length

        cdef bint stereo = self.is_stereo()

        # Clear the buffer(s).
        memset(self.left, 0, BUFFER_SIZE * sizeof(double))
        if stereo:
            memset(self.right, 0, BUFFER_SIZE * sizeof(double))

        done_signals = []
        max_length = 0

        for inp in self.inputs:
            length = inp.generate()

            if length == 0:
                done_signals.append(inp)

            max_length = imax(max_length, length)

            for i in range(length):
                self.left[i] += inp.left[i]
            if stereo:
                for i in range(length):
                    self.right[i] += inp.right[i]

        if self.offset != 0:
            for i in range(max_length):
                self.left[i] += self.offset
            if stereo:
                for i in range(max_length):
                    self.right[i] += self.offset

        for sig in done_signals:
            self.inputs.remove(sig)

        return max_length


cdef class Multiply(BufferSignal):
    cdef Signal inp1, inp2
    cdef double constant_factor

    def __init__(self, inp1, inp2):
        cdef Signal sig

        inputs = []
        self.constant_factor = 1
        for inp in [inp1, inp2]:
            if issubclass(type(inp), Signal):
                inputs.append(inp)
            else:
                self.constant_factor = inp

        if len(inputs) == 0:
            raise TypeError('At least one input must be a Signal.')

        if len(inputs) == 2:
            self.inp1, self.inp2 = inputs
        else:
            self.inp1 = inputs[0]
            self.inp2 = None

        for sig in inputs:
            if sig.is_stereo():
                self.make_stereo()
                break

    cdef int generate(self) except -1:
        cdef int i, length

        if self.inp2:
            length = imin(self.inp1.generate(), self.inp2.generate())
            for i in range(length):
                self.left[i] = self.inp1.left[i] * self.inp2.left[i]
            if self.is_stereo():
                for i in range(length):
                    self.right[i] = self.inp1.right[i] * self.inp2.right[i]
        else:
            length = self.inp1.generate()
            for i in range(length):
                self.left[i] = self.inp1.left[i] * self.constant_factor
            if self.is_stereo():
                for i in range(length):
                    self.right[i] = self.inp1.right[i] * self.constant_factor

        return length
