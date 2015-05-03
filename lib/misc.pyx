from __future__ import division
from libc.string cimport memset

from generator cimport Generator
from buffernode cimport BufferNode

include "constants.pxi"

# Measured at 24us/s.
cdef class Silence(Generator):
    cdef long samples_left

    def __cinit__(self, length):
        self.samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        buf.clear()

        if self.samples_left <= BUFFER_SIZE:
            buf.has_more = False
            buf.length = self.samples_left
        else:
            buf.has_more = True
            buf.length = BUFFER_SIZE

        self.samples_left -= BUFFER_SIZE


# Measured at 920ns/s real time.
cdef class NoOp(Generator):
    cdef long samples_left

    def __cinit__(self, length):
        self.samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        if self.samples_left <= BUFFER_SIZE:
            buf.has_more = False
            buf.length = self.samples_left
        else:
            buf.has_more = True
            buf.length = BUFFER_SIZE

        self.samples_left -= BUFFER_SIZE
