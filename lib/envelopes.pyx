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

        L[0] = self.value
        L[1] = L[0] * self.step
        L[2] = L[1] * self.step
        L[3] = L[2] * self.step
        L[4] = L[3] * self.step
        L[5] = L[4] * self.step
        L[6] = L[5] * self.step
        L[7] = L[6] * self.step
        L[8] = L[7] * self.step
        L[9] = L[8] * self.step
        L[10] = L[9] * self.step
        L[11] = L[10] * self.step
        L[12] = L[11] * self.step
        L[13] = L[12] * self.step
        L[14] = L[13] * self.step
        L[15] = L[14] * self.step
        L[16] = L[15] * self.step
        L[17] = L[16] * self.step
        L[18] = L[17] * self.step
        L[19] = L[18] * self.step

        for i in range(20, BUFFER_SIZE, 20):
            L[i] = L[i-1] * self.step
            L[i+1] = L[i] * self.step
            L[i+2] = L[i+1] * self.step
            L[i+3] = L[i+2] * self.step
            L[i+4] = L[i+3] * self.step
            L[i+5] = L[i+4] * self.step
            L[i+6] = L[i+5] * self.step
            L[i+7] = L[i+6] * self.step
            L[i+8] = L[i+7] * self.step
            L[i+9] = L[i+8] * self.step
            L[i+10] = L[i+9] * self.step
            L[i+11] = L[i+10] * self.step
            L[i+12] = L[i+11] * self.step
            L[i+13] = L[i+12] * self.step
            L[i+14] = L[i+13] * self.step
            L[i+15] = L[i+14] * self.step
            L[i+16] = L[i+15] * self.step
            L[i+17] = L[i+16] * self.step
            L[i+18] = L[i+17] * self.step
            L[i+19] = L[i+18] * self.step

        self.value = L[i+19] * self.step

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
