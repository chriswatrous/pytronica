from __future__ import division

from sig cimport Signal, BufferSignal 

include "constants.pxi"

cdef class ExpDecay(BufferSignal):
    cdef double value, step

    def __init__(self, half_life, start_value=1):
        if half_life <= 0:
            raise ValueError('half_life must be a positive number')
        self.value = start_value
        self.step = 2**(-1 / self.sample_rate / half_life)

    cdef int generate(self) except -1:
        cdef int i

        if self.value < 0.0003:
            return 0

        for i in range(BUFFER_SIZE):
            self.left[i] = self.value
            self.value *= self.step

        return BUFFER_SIZE


cdef class LinearDecay(BufferSignal):
    cdef double value, step

    def __init__(self, decay_time, start_value=1):
        if decay_time <= 0:
            raise ValueError('decay_time must be a positive number')
        self.value = start_value
        self.step = start_value / decay_time / self.sample_rate

    cdef int generate(self) except -1:
        cdef int i, length

        if self.value < 0:
            return 0

        length = BUFFER_SIZE

        for i in range(BUFFER_SIZE):
            self.left[i] = self.value
            self.value -= self.step
            if self.value < 0:
                length = i
                break

        return length
