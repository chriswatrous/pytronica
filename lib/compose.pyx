from __future__ import division

from libc.string cimport memset
from collections import deque

from sig cimport Signal, BufferSignal 
from c_util cimport imin, imax

include "constants.pxi"

cdef class ComposeInfo:
    cdef Signal signal
    cdef int start_frame
    cdef int offset
    cdef int length

    def __cinit__(self, Signal signal, int start_frame, int offset):
        self.signal = signal
        self.start_frame = start_frame
        self.offset = offset
        self.length = -1


cdef class Compose(BufferSignal):
    cdef object inputs, waiting, running
    cdef int frame_count
    cdef bint started

    def __init__(self, inputs=None):
        if inputs:
            self.inputs = inputs
        else:
            self.inputs = []

        self.started = False
        self.frame_count = 0


    def add(self, Signal signal, delay):
        self.inputs.append((signal, delay))
        if signal.is_stereo() and not self.is_stereo():
            self.make_stereo()


    cdef _prepare(self):
        cdef int start_frame, offset
        cdef Signal signal
        cdef double delay

        self.started = True

        self.inputs.sort(key=lambda x: x[1])

        self.waiting = deque()
        self.running = []

        for signal, delay in self.inputs:
            start_frame = <int>((delay * self.sample_rate) / BUFFER_SIZE)
            offset = <int>((delay * self.sample_rate) - (start_frame * BUFFER_SIZE))
            self.waiting.append(ComposeInfo(signal, start_frame, offset))


    cdef int generate(self) except -1:
        cdef ComposeInfo info
        cdef int i # used for loop iterators
        cdef int length # used for the loop terminator
        cdef int frame_length # the total number of samples in the buffer that were touch by any loop

        cdef bint stereo = self.is_stereo()

        if not self.started:
            self._prepare()

        # End this signal if there are no more child signals to be played.
        if len(self.running) == 0 and len(self.waiting) == 0:
            return 0

        # Zero out the buffer(s).
        memset(self.left, 0, BUFFER_SIZE * sizeof(double))
        if stereo:
            memset(self.right, 0, BUFFER_SIZE * sizeof(double))

        # Get the signals that will be starting this frame.
        while True:
            if len(self.waiting) == 0:
                break
            info = self.waiting[0]
            if info.start_frame > self.frame_count:
                break
            self.running.append(self.waiting.popleft())

        frame_length = 0
        done = []
        for info in self.running:
            # Add the end of the previously generated signal to the start of the buffer.
            if info.length >= 0:
                length = info.length + info.offset - BUFFER_SIZE
                if stereo:
                    for i in range(length):
                        self.left[i] += info.signal.left[i + BUFFER_SIZE - info.offset]
                        self.right[i] += info.signal.right[i + BUFFER_SIZE - info.offset]
                else:
                    for i in range(length):
                        self.left[i] += info.signal.left[i + BUFFER_SIZE - info.offset]
                frame_length = imax(length, frame_length)

            # Generate the signal.
            info.length = info.signal.generate()
            if info.length == 0:
                done.append(info)
                continue

            # Add the start of the generated signal to the end of the buffer.
            length = imin(info.length + info.offset, BUFFER_SIZE)
            if stereo:
                for i in range(info.offset, length):
                    self.left[i] += info.signal.left[i - info.offset]
                    self.right[i] += info.signal.right[i - info.offset]
            else:
                for i in range(info.offset, length):
                    self.left[i] += info.signal.left[i - info.offset]
            frame_length = imax(length, frame_length)

        for x in done:
            self.running.remove(x)

        self.frame_count += 1

        if len(self.running) == 0 and len(self.waiting) == 0:
            return frame_length
        else:
            return BUFFER_SIZE
