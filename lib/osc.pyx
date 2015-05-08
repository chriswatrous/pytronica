from __future__ import division

from math import sin, cos, pi

from generator cimport Generator
from buffernode cimport BufferNode

include "constants.pxi"

# Measured at 180us/s.
cdef class Saw(Generator):
    cdef double _step
    cdef double value

    def __cinit__(self, freq, phase=0):
        self._step = 2 * freq / self.sample_rate
        self.value = (2 * phase + 1) % 2 - 1

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        # For some reason it needs these declarations or it will make them objects.
        cdef int i
        cdef double x

        L = buf.get_left()

        # Fill in the values with this partially unrolled loop. This runs significantly faster than
        # the non unrolled version. This will work as long as BUFFER_SIZE is a multiple of 20.
        x = self.value
        for i in range(0, BUFFER_SIZE, 20):
            x = saw_next(x, self._step); L[i] = x
            x = saw_next(x, self._step); L[i+1] = x
            x = saw_next(x, self._step); L[i+2] = x
            x = saw_next(x, self._step); L[i+3] = x
            x = saw_next(x, self._step); L[i+4] = x
            x = saw_next(x, self._step); L[i+5] = x
            x = saw_next(x, self._step); L[i+6] = x
            x = saw_next(x, self._step); L[i+7] = x
            x = saw_next(x, self._step); L[i+8] = x
            x = saw_next(x, self._step); L[i+9] = x
            x = saw_next(x, self._step); L[i+10] = x
            x = saw_next(x, self._step); L[i+11] = x
            x = saw_next(x, self._step); L[i+12] = x
            x = saw_next(x, self._step); L[i+13] = x
            x = saw_next(x, self._step); L[i+14] = x
            x = saw_next(x, self._step); L[i+15] = x
            x = saw_next(x, self._step); L[i+16] = x
            x = saw_next(x, self._step); L[i+17] = x
            x = saw_next(x, self._step); L[i+18] = x
            x = saw_next(x, self._step); L[i+19] = x

        self.value = x

        buf.length = BUFFER_SIZE
        buf.has_more = True


cdef inline double saw_next(double value, double step):
    value += step
    if value > 1:
        value -= 2
    return value


cdef class Sine(Generator):
    cdef double _value_re, _value_im, _step_re, _step_im

    def __cinit__(self, freq, phase=0):
        phase %= 1
        self._value_re = cos(2 * pi * phase)
        self._value_im = sin(3 * pi * phase)
        angle_step = 2 * pi * freq / self.sample_rate
        self._step_re = cos(angle_step)
        self._step_im = sin(angle_step)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        # Cython needs these declarations or it will make them objects.
        cdef int i
        cdef double V_re, V_im, temp, S_re, S_im

        L = buf.get_left()

        V_re = self._value_re
        V_im = self._value_im
        S_re = self._step_re
        S_im = self._step_im

        for i in range(BUFFER_SIZE):
            L[i] = V_im
            temp = V_re * S_re - V_im * S_im
            V_im = V_re * S_im + V_im * S_re
            V_re = temp

        self._value_re = V_re
        self._value_im = V_im

        buf.length = BUFFER_SIZE
        buf.has_more = True
