from libc.stdio cimport FILE
from buffernode cimport BufferNode

cdef class Generator:
    cdef double sample_rate
    cdef BufferNode head
    cdef BufferNode spare
    cdef object iters
    cdef double mlength

    cdef double _clip_max
    cdef int _head_uses

    cdef bint is_stereo(self) except -1
    cdef generate(self, BufferNode buf)
    cdef get_iter(self)
    cdef write_output(self, FILE *f)
    cdef put_sample(self, double sample, FILE *f)
    cdef report_clipping(self, double sample)
    cdef get_head(self)
