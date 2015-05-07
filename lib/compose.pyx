from __future__ import division

from collections import deque

from generator cimport Generator
from buffernode cimport BufferNode
from bufferiter cimport BufferIter
from c_util cimport imin, imax

include "constants.pxi"

cdef class ComposeInfo:
    cdef BufferIter iter
    cdef int start_frame
    cdef int offset
    cdef int length

    def __cinit__(self, BufferIter iter, int start_frame, int offset):
        self.iter = iter
        self.start_frame = start_frame
        self.offset = offset


cdef class Compose(Generator):
    cdef object _inputs, _waiting, _running
    cdef int _frame_count
    cdef bint _starting

    def __cinit__(self, inputs=None):
        self._inputs = inputs or []
        self._starting = True
        self._frame_count = 0

    def add(self, Generator generator, delay):
        self._inputs.append((generator, delay))

    cdef bint is_stereo(self) except -1:
        cdef Generator input

        if not self._inputs:
            raise IndexError('Compose object has no inputs')

        for input, delay in self._inputs:
            if input.is_stereo():
                return True

        return False

    cdef _prepare(self):
        cdef int start_frame, offset
        cdef double delay

        self._inputs.sort(key=lambda x: x[1])

        self._waiting = deque()
        self._running = []

        for input, delay in self._inputs:
            start_frame = <int>((delay * self.sample_rate) / BUFFER_SIZE)
            offset = <int>((delay * self.sample_rate) - (start_frame * BUFFER_SIZE))
            self._waiting.append(ComposeInfo((<Generator?>input).get_iter(), start_frame, offset))

    cdef generate(self, BufferNode buf):
        cdef ComposeInfo info
        cdef BufferNode I_buf
        cdef int i, length, frame_length

        if self._starting:
            self._starting = False
            self._prepare()

        buf.clear()

        L = buf.get_left()
        R = buf.get_right()

        # Get the signals that will be starting this frame.
        while True:
            if len(self._waiting) == 0:
                break
            info = self._waiting[0]
            if info.start_frame > self._frame_count:
                break
            self._running.append(self._waiting.popleft())

        frame_length = 0
        done = []
        for info in self._running:
            # Add the end of the previously generated signal to the start of the buffer.
            if info.iter.current:
                I_buf = info.iter.current

                length = I_buf.length + info.offset - BUFFER_SIZE

                IL = I_buf.get_left()
                IR = I_buf.get_right()

                if buf.stereo:
                    for i in range(length):
                        L[i] += IL[i + BUFFER_SIZE - info.offset]
                        R[i] += IR[i + BUFFER_SIZE - info.offset]
                else:
                    for i in range(length):
                        L[i] += IL[i + BUFFER_SIZE - info.offset]

                frame_length = imax(length, frame_length)

                if not I_buf.has_more:
                    done.append(info)
                    continue

            I_buf = info.iter.get_next()

            IL = I_buf.get_left()
            IR = I_buf.get_right()

            # Add the start of the generated signal to the end of the buffer.
            length = imin(I_buf.length + info.offset, BUFFER_SIZE)

            if buf.stereo:
                for i in range(info.offset, length):
                    L[i] += IL[i - info.offset]
                    R[i] += IR[i - info.offset]
            else:
                for i in range(info.offset, length):
                    L[i] += IL[i - info.offset]

            frame_length = imax(length, frame_length)

        for x in done:
            self._running.remove(x)

        self._frame_count += 1

        buf.has_more = self._running or self._waiting
        buf.length = BUFFER_SIZE if buf.has_more else frame_length
