from libc.stdio cimport FILE
from buffernode cimport BufferNode

cdef class Generator:
    cdef public double mlength

    cdef double sample_rate
    cdef BufferNode head
    cdef BufferNode spare
    cdef object iters

    cdef double _clip_max
    cdef int _head_uses
    cdef bint _stereo

    cdef bint is_stereo(self) except -1
    cdef generate(self, BufferNode buf)
    cdef get_iter(self)
    cdef write_output(self, FILE *f)
    cdef put_sample(self, double sample, FILE *f)
    cdef report_clipping(self, double sample)
    cdef BufferNode get_head(self)
    cdef BufferNode get_next(self)

    cdef _measure(self, bint rate)
