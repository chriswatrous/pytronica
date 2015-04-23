from sig cimport BufferSignal 
from sig import BufferSignal

include "constants.pxi"

cdef class Saw(BufferSignal):
    cdef double step
    cdef double value
    cdef long samples_left
    cdef bint finite

    def __init__(self, freq, length=None, phase=0):
        super(Saw, self).__init__(self)

        self.step = 2 * freq / self.sample_rate

        self.value = phase * 2
        if self.value > 1:
            self.value -= 2
        if length != None:
            self.finite = True
            self.samples_left = length * self.sample_rate
        else:
            self.finite = False

    cdef int generate(self) except -1:
        cdef int i, length

        if self.finite and self.samples_left <= 0:
            return 0

        if self.finite and self.samples_left <= BUFFER_SIZE:
            length = self.samples_left
        else:
            length = BUFFER_SIZE

        for i in range(length):
            self.samples[i] = self.value
            self.value += self.step
            if self.value > 1:
                self.value -= 2

        self.samples_left -= length

        return length
