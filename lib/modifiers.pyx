from sig cimport Signal, BufferSignal 

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
            self.samples[i] = self.inp.samples[i] * self.amount

        return length

