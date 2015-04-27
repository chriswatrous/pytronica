from libc.stdio cimport FILE

cdef class Signal:
    cdef double *left
    cdef double *right
    cdef double clip_max

    cdef double sample_rate
    cdef bint is_stereo(self)
    cdef int generate(self) except -1
    cdef write_output(self, FILE *f)
    cdef object put_sample(self, double sample, FILE *f)
    cdef report_clipping(self, double samples)

cdef class BufferSignal(Signal):
    cdef make_stereo(self)
