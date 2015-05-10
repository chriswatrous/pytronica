#!python
#cython cdivision=True
from __future__ import division

from math import sin, cos, pi

from libc.math cimport fmod

from generator cimport Generator
from buffernode cimport BufferNode
from bufferiter cimport BufferIter
from c_util cimport imin

from misc import Const

include "constants.pxi"

cdef Generator get_generator(x):
    if isinstance(x, Generator):
        return x
    else:
        return Const(x)


cdef class Saw(Generator):
    cdef BufferIter _freq_iter
    cdef BufferIter _phase_iter
    cdef double _step
    cdef double _value
    cdef object (*_generate) (Saw, BufferNode)

    def __cinit__(self, freq, phase=0):
        if isinstance(freq, Generator) or isinstance(phase, Generator):
            self._generate = self._generate_variable
            self._freq_iter = get_generator(freq).get_iter()
            self._phase_iter = get_generator(phase).get_iter()
            self._value = 0
        else:
            self._generate = self._generate_fixed
            self._freq_iter = None
            self._phase_iter = None
            self._step = 2 * freq / self.sample_rate
            self._value = (2 * phase + 1) % 2 - 1

    cdef bint is_stereo(self) except -1:
        if self._freq_iter and self._freq_iter.generator.is_stereo():
            raise ValueError('frequency must be a constant or mono Generator')

        if self._phase_iter and self._phase_iter.generator.is_stereo():
            raise ValueError('phase must be a constant or mono Generator')

        return False

    cdef generate(self, BufferNode buf):
        self._generate(self, buf)

    cdef _generate_fixed(self, BufferNode buf):
        cdef int i
        cdef double x

        L = buf.get_left()

        # Fill in the values with this partially unrolled loop. This runs significantly faster than
        # the non unrolled version. This will work as long as BUFFER_SIZE is a multiple of 20.
        x = self._value
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

        self._value = x

        buf.length = BUFFER_SIZE
        buf.has_more = True

    cdef _generate_variable(self, BufferNode buf):
        cdef BufferNode F_buf, P_buf
        cdef int i, length
        cdef double x, y, step

        out = buf.get_left()

        F_buf = self._freq_iter.get_next()
        P_buf = self._phase_iter.get_next()

        F = F_buf.get_left()
        P = P_buf.get_left()

        length = imin(F_buf.length, P_buf.length)

        x = self._value
        a = 2 / self.sample_rate

        # I tried loop unrolling here. It doesn't make much difference.
        for i in range(length):
            x += a * F[i]
            out[i] = saw_adjust(x + P[i])

        self._value = saw_adjust(x)

        buf.length = F_buf.length
        buf.has_more = F_buf.has_more


cdef inline double saw_next(double value, double step):
    value += step
    if value > 1: value -= 2
    return value

cdef inline double saw_adjust(double x):
    x = fmod(x, 2)
    if x <= -1: x += 2 # This check is necessary because fmod returns a negative number if the input is negative
    elif x > 1: x -= 2
    return x


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
