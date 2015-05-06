from __future__ import division

from generator cimport Generator
from bufferiter cimport BufferIter
from buffernode cimport BufferNode

include "constants.pxi"

cdef class ExpDecay(Generator):
    cdef double value, step

    def __cinit__(self, double half_life):
        if half_life <= 0:
            raise ValueError('half_life must be a positive number')
        self.value = 1
        self.step = 2**(-1 / self.sample_rate / half_life)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        cdef int i
        cdef double m, b

        L = buf.get_left()

        for i in range(BUFFER_SIZE):
            L[i] = self.value
            self.value *= self.step

        buf.length = BUFFER_SIZE
        buf.has_more = self.value > 0.0003


cdef class LinearDecay(Generator):
    cdef double value, step

    def __cinit__(self, double decay_time):
        if decay_time <= 0:
            raise ValueError('decay_time must be a positive number')
        self.value = 1
        self.step = -1 / decay_time / self.sample_rate

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        cdef int i, length

        L = buf.get_left()

        for i in range(BUFFER_SIZE):
            L[i] = self.value
            self.value += self.step
            if self.value < 0:
                break

        buf.length = i + 1
        buf.has_more = self.value >= 0
