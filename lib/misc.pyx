from __future__ import division
from libc.string cimport memset

from generator cimport Generator
from buffernode cimport BufferNode
from c_util cimport imin

include "constants.pxi"

cdef class Silence(Generator):
    cdef long samples_left

    def __cinit__(self, length):
        self.samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        buf.clear()

        buf.has_more = self.samples_left > BUFFER_SIZE
        buf.length = imin(self.samples_left, BUFFER_SIZE)

        self.samples_left -= BUFFER_SIZE


cdef class NoOp(Generator):
    cdef long samples_left

    def __cinit__(self, length):
        self.samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        buf.has_more = self.samples_left > BUFFER_SIZE
        buf.length = imin(self.samples_left, BUFFER_SIZE)

        self.samples_left -= BUFFER_SIZE
