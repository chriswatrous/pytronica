from __future__ import division

from generator cimport Generator
from buffernode cimport BufferNode

include "constants.pxi"

# Measured at 180us/s.
cdef class Saw(Generator):
    cdef double step
    cdef double value
    cdef long remaining_samples
    cdef bint finite

    def __cinit__(self, freq, length=None, phase=0):
        self.step = 2 * freq / self.sample_rate
        self.value = (2 * phase + 1) % 2 - 1

        if length != None:
            self.finite = True
            self.remaining_samples = length * self.sample_rate
        else:
            self.finite = False

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        # For some reason it needs these declarations or it will make them objects.
        cdef int i, j, length
        cdef double x

        L = buf.get_left()

        # Determine length of this frame.
        if self.finite and self.remaining_samples <= BUFFER_SIZE:
            length = self.remaining_samples
        else:
            length = BUFFER_SIZE

        # Fill in most of the values with this partially unrolled loop. (This runs about twice as fast
        # as the non unrolled version.)
        x = self.value
        i = 0
        while i <= length - 20:
            x = saw_next(x, self.step); L[i] = x
            x = saw_next(x, self.step); L[i+1] = x
            x = saw_next(x, self.step); L[i+2] = x
            x = saw_next(x, self.step); L[i+3] = x
            x = saw_next(x, self.step); L[i+4] = x
            x = saw_next(x, self.step); L[i+5] = x
            x = saw_next(x, self.step); L[i+6] = x
            x = saw_next(x, self.step); L[i+7] = x
            x = saw_next(x, self.step); L[i+8] = x
            x = saw_next(x, self.step); L[i+9] = x
            x = saw_next(x, self.step); L[i+10] = x
            x = saw_next(x, self.step); L[i+11] = x
            x = saw_next(x, self.step); L[i+12] = x
            x = saw_next(x, self.step); L[i+13] = x
            x = saw_next(x, self.step); L[i+14] = x
            x = saw_next(x, self.step); L[i+15] = x
            x = saw_next(x, self.step); L[i+16] = x
            x = saw_next(x, self.step); L[i+17] = x
            x = saw_next(x, self.step); L[i+18] = x
            x = saw_next(x, self.step); L[i+19] = x
            i += 20

        # Fill in any remaining values.
        while i < length:
            x = saw_next(x, self.step); L[i] = x
            i += 1

        self.value = x
        self.remaining_samples -= length

        buf.length = length
        buf.has_more = not self.finite or self.remaining_samples > 0


cdef inline double saw_next(double value, double step):
    value += step
    if value > 1:
        value -= 2
    return value
