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
        cdef int i, j

        L = buf.get_left()

        # This is ugly but it runs about twice is fast as the non unrolled version.

        # Fill in most of the values with this unrolled loop. (This runs about twice as fast
        # as the non unrolled version.)
        x = self.value
        i = 0
        while i <= BUFFER_SIZE - 20:
            x *= self.step; L[i] = x
            x *= self.step; L[i+1] = x
            x *= self.step; L[i+2] = x
            x *= self.step; L[i+3] = x
            x *= self.step; L[i+4] = x
            x *= self.step; L[i+5] = x
            x *= self.step; L[i+6] = x
            x *= self.step; L[i+7] = x
            x *= self.step; L[i+8] = x
            x *= self.step; L[i+9] = x
            x *= self.step; L[i+10] = x
            x *= self.step; L[i+11] = x
            x *= self.step; L[i+12] = x
            x *= self.step; L[i+13] = x
            x *= self.step; L[i+14] = x
            x *= self.step; L[i+15] = x
            x *= self.step; L[i+16] = x
            x *= self.step; L[i+17] = x
            x *= self.step; L[i+18] = x
            x *= self.step; L[i+19] = x
            i += 20

        # Fill in any remaining values.
        while i < BUFFER_SIZE:
            x *= self.step; L[i] = x
            i += 1

        self.value = x

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
