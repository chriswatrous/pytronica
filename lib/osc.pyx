from sig cimport BufferSignal
from sig import BufferSignal

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
        cdef int i, length
        cdef double *left

        left = buf.get_left()

        # Determine length of this frame.
        if self.finite and self.remaining_samples <= BUFFER_SIZE:
            length = self.remaining_samples
        else:
            length = BUFFER_SIZE

        # Fill the buffer.
        left[0] = self.value
        if left[0] > 1:
            left[0] -= 2
        for i in range(1, length):
            left[i] = left[i-1] + self.step
            if left[i] > 1:
                left[i] -= 2

        self.value = left[length-1] + self.step
        self.remaining_samples -= length
        buf.length = length
        buf.has_more = not self.finite or self.remaining_samples > 0
