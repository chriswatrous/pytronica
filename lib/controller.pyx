from __future__ import division

from collections import deque

from generator cimport Generator
from buffernode cimport BufferNode
from c_util cimport imin, imax

from generator import get_sample_rate

include "constants.pxi"

cdef class Controller(Generator):
    cdef double start_value
    cdef ControlMoveQueue moves
    cdef BufferFiller current_move
    cdef long current_sample, next_change
    cdef bint starting, ending

    def __init__(self, start_value):
        self.moves = ControlMoveQueue()
        self.start_value = start_value
        self.current_move = None
        self.starting = True
        self.ending = False

    def lineto(self, time, value):
        self.moves.lineto(time, value)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        cdef int i

        L = buf.get_left()

        if self.starting:
            self.starting = False
            if self.moves.not_empty():
                self.current_move = self.moves.get_next(self.start_value)
                self.next_change = self.current_move.length
            else:
                raise IndexError('There are no control moves in the queue.')

        i = 0
        while self.next_change - self.current_sample <= BUFFER_SIZE - i:
            # Current move ending this frame.

            # Fill buffer.
            length = self.next_change - self.current_sample
            self.current_move.fill_buffer(&L[i], length)

            # Increment counters.
            i += length
            self.current_sample += length

            # Get next move. End if no more.
            if self.moves.not_empty():
                self.current_move = self.moves.get_next(self.current_move.value)
                self.next_change = self.current_sample + self.current_move.length
            else:
                buf.length = i
                buf.has_more = False
                return

        # Current move ending sometime after this frame.
        # Fill buffer and increment counter.
        length = BUFFER_SIZE - i
        self.current_move.fill_buffer(&L[i], length)
        self.current_sample += length

        buf.length = BUFFER_SIZE
        buf.has_more = True


cdef class ControlMoveQueue:
    cdef object moves
    cdef double current_time, sample_rate
    cdef long current_sample

    def __init__(self):
        self.sample_rate = get_sample_rate()
        self.moves = deque()
        self.current_time = 0
        self.current_sample = 0

    cdef lineto(self, double time, double value):
        cdef long sample, length

        sample = <long>(time * self.sample_rate)
        length = sample - self.current_sample

        if length < 0:
            raise ValueError('time must not be earlier then the previous time')

        self.moves.append(LinearFiller(length, value))

        self.current_time = time
        self.current_sample = sample

    cdef get_next(self, double start_value):
        cdef BufferFiller move
        try:
            move = self.moves.popleft()
            move.start(start_value)
            return move
        except:
            return None

    cdef bint not_empty(self):
        return len(self.moves) != 0


cdef class BufferFiller:
    cdef long length
    cdef double value

    cdef start(self, double value):
        raise NotImplementedError

    cdef fill_buffer(self, double *buffer, int count):
        raise NotImplementedError


cdef class LinearFiller(BufferFiller):
    cdef double step, end_value

    def __cinit__(self, long length, double end_value):
        self.length = length
        self.end_value = end_value

    cdef start(self, double start_value):
        self.value = start_value
        self.step = (self.end_value - start_value) / self.length

    cdef fill_buffer(self, double *buffer, int count):
        cdef int i
        for i in range(count):
            buffer[i] = self.value
            self.value += self.step


#cdef class Hold(BufferFiller):
    #cdef double step
#
    #def __cinit__(self, double start_time, double step):
        #self.step = step
#
    #cdef start(self, double value):
        #self.value = value
#
    #cdef fill_buffer(self, double *buffer, int count):
        #cdef int i
        #for i in range(count):
            #buffer[i] = value
            #value += step
