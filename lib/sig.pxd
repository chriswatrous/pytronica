cdef class Signal:
    cdef double *samples
    cdef double sample_rate
    cdef int generate(self) except -1

cdef class BufferSignal(Signal):
    pass
