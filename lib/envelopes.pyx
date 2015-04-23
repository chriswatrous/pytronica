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
