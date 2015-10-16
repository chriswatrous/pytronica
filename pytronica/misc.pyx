from __future__ import division
from libc.string cimport memcpy

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


cdef class Const(Generator):
    cdef BufferNode _value_node

    def __cinit__(self, double value):
        cdef int i

        self._value_node = BufferNode(None, False)
        L = self._value_node.get_left()

        for i in range(BUFFER_SIZE):
            L[i] = value

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        buf.share_from(self._value_node)
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


cdef class Drop(Generator):
    cdef bint _starting
    cdef BufferIter _input_iter
    cdef int _frames_to_drop
    cdef int _offset

    def __cinit__(self, Generator input, length):
        if length < 0:
            raise ValueError('length must be positive')

        self._input_iter = input.get_iter()
        self._starting = True

        samples_to_drop = length * self.sample_rate
        self._frames_to_drop = samples_to_drop // BUFFER_SIZE
        self._offset = samples_to_drop % BUFFER_SIZE

    cdef bint is_stereo(self) except -1:
        return self._input_iter.generator.is_stereo()

    cdef generate(self, BufferNode buf):
        cdef BufferNode I_buf
        cdef int a, offset, length

        if self._starting:
            self._starting = False
            for _ in range(self._frames_to_drop + 1):
                self._input_iter.get_next()

        offset = self._offset
        L = buf.get_left()
        R = buf.get_right()

        # First half:
        I_buf = self._input_iter.current
        IL = I_buf.get_left()
        IR = I_buf.get_right()

        length = I_buf.length - offset
        memcpy(L, &IL[offset], length * sizeof(double))
        if buf.stereo:
            memcpy(R, &IR[offset], length * sizeof(double))

        # End here if no more.
        if not self._input_iter.current.has_more:
            buf.length = length
            buf.has_more = False
            return

        # Second half:
        I_buf = self._input_iter.get_next()
        IL = I_buf.get_left()
        IR = I_buf.get_right()
        length = imin(offset, I_buf.length)

        memcpy(&L[BUFFER_SIZE - offset], IL, length * sizeof(double))
        if buf.stereo:
            memcpy(&R[BUFFER_SIZE - offset], IR, length * sizeof(double))

        buf.has_more = I_buf.length > offset
        buf.length = BUFFER_SIZE - offset + length
