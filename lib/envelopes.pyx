from __future__ import division

from sig cimport Signal, BufferSignal

include "constants.pxi"

cdef class ExpDecay(BufferSignal):
    cdef double value, step, start_value, end_value
    cdef bint finite

    def __cinit__(self, double half_life, double start_value=1, double end_value=0, bint finite=True):
        if half_life <= 0:
            raise ValueError('half_life must be a positive number')
        self.value = 1
        self.step = 2**(-1 / self.sample_rate / half_life)
        self.start_value = start_value
        self.end_value = end_value
        self.finite = finite

    cdef int generate(self) except -1:
        cdef int i
        cdef double m, b

        if self.finite and self.value < 0.0003:
            return 0

        m = self.start_value - self.end_value
        b = self.end_value

        for i in range(BUFFER_SIZE):
            self.left[i] = m * self.value + b
            self.value *= self.step

        return BUFFER_SIZE


cdef class LinearDecay(BufferSignal):
    cdef long sample_count, total_samples,
    cdef double m, b, end_value
    cdef bint finite

    def __cinit__(self, double decay_time, double start_value=1, double end_value=0, bint finite=True):
        if decay_time <= 0:
            raise ValueError('decay_time must be a positive number')
        self.finite = finite
        self.sample_count = 0
        self.total_samples = <long>(decay_time * self.sample_rate)
        self.m = (end_value - start_value) / self.sample_rate / decay_time
        self.b = start_value
        self.end_value = end_value

    cdef int generate(self) except -1:
        cdef int i, length

        if self.finite and self.sample_count >= self.total_samples:
                return 0

        if self.sample_count <= self.total_samples + BUFFER_SIZE:
            i = 0
            while i < BUFFER_SIZE:
                if self.sample_count < self.total_samples:
                    self.left[i] = self.m * self.sample_count + self.b
                else:
                    if self.finite:
                        return i
                    else:
                        self.left[i] = self.end_value
                i += 1
                self.sample_count += 1

        return BUFFER_SIZE
