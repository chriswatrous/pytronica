from __future__ import division
from libc.string cimport memset

from generator cimport Generator
from buffernode cimport BufferNode
from bufferiter cimport BufferIter
from c_util cimport imin

include "constants.pxi"

cdef class Silence(Generator):
    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        buf.clear()

        buf.length = BUFFER_SIZE
        buf.has_more = True


cdef class NoOp(Generator):
    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        # Make sure the memory gets allocated.
        buf.get_left()

        buf.length = BUFFER_SIZE
        buf.has_more = True


cdef class Take(Generator):
    cdef BufferIter _input_iter
    cdef long _samples_left

    def __cinit__(self, Generator input, length):
        self._input_iter = input.get_iter()
        self._samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return self._input_iter.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        I_buf = self._input_iter.get_next()
        buf.share_from(I_buf)

        buf.has_more = self._samples_left > BUFFER_SIZE
        buf.length = imin(self._samples_left, BUFFER_SIZE)

        self._samples_left -= BUFFER_SIZE
