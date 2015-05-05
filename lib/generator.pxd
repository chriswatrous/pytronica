from libc.stdio cimport FILE
from buffernode cimport BufferNode

cdef class Generator:
    cdef double sample_rate
    cdef BufferNode starter
    cdef BufferNode spare
    cdef int starters
    cdef bint started

    cdef double _clip_max

    cdef bint is_stereo(self) except -1
    cdef generate(self, BufferNode buf)
    cdef write_output(self, FILE *f)
    cdef put_sample(self, double sample, FILE *f)
    cdef report_clipping(self, double sample)
