from libc.string cimport memset

from sig cimport Signal, BufferSignal 

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

            if length > max_length:
                max_length = length

            if stereo:
                for i in range(length):
                    self.left[i] += inp.left[i]
                    self.right[i] += inp.right[i]
            else:
                for i in range(length):
                    self.left[i] += inp.left[i]

        if self.offset != 0:
            if stereo:
                for i in range(max_length):
                    self.left[i] += self.offset
                    self.right[i] += self.offset
            else:
                for i in range(max_length):
                    self.left[i] += self.offset
            

        for sig in done_signals:
            self.inputs.remove(sig)

        return max_length


cdef class AmpMod(BufferSignal):
    cdef Signal inp1, inp2

    def __init__(self, inp1, inp2):
        self.inp1 = inp1
        self.inp2 = inp2
        if self.inp1.is_stereo() or self.inp2.is_stereo():
            self.make_stereo()

    cdef int generate(self) except -1:
        cdef int length1, length2, length, i

        length1 = self.inp1.generate()
        length2 = self.inp2.generate()

        if length1 == 0 or length2 == 0:
            return 0

        length = length1 if length1 > length2 else length2

        if self.is_stereo():
            for i in range(length):
                self.left[i] = self.inp1.left[i] * self.inp2.left[i]
                self.right[i] = self.inp1.right[i] * self.inp2.right[i]
        else:
            for i in range(length):
                self.left[i] = self.inp1.left[i] * self.inp2.left[i]

        return length
