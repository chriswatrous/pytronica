cdef class Signal:
    cdef double *left
    cdef double *right

    cdef double sample_rate
    cdef bint is_stereo(self)
    cdef int generate(self) except -1

cdef class BufferSignal(Signal):
    cdef make_stereo(self)
