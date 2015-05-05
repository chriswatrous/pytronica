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
        cdef int i, length

        L = buf.get_left()

        # Determine length of this frame.
        if self.finite and self.remaining_samples <= BUFFER_SIZE:
            length = self.remaining_samples
        else:
            length = BUFFER_SIZE

        # Set the first value.
        L[0] = self.value
        if L[0] > 1:
            L[0] -= 2

        # Fill in the rest of the values.
        for i in range(1, length):
            L[i] = L[i-1] + self.step
            if L[i] > 1:
                L[i] -= 2

        self.value = L[length-1] + self.step
        self.remaining_samples -= length

        buf.length = length
        buf.has_more = not self.finite or self.remaining_samples > 0
