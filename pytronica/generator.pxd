from libc.stdio cimport FILE
from buffernode cimport BufferNode

cdef class Generator:
    # Python visible fields
    cdef public double mlength

    # fields used by other Cython objects
    cdef double sample_rate
    cdef BufferNode head
    cdef BufferNode spare

    # fields used internally
    cdef object _iters
    cdef double _clip_max
    cdef int _head_uses
    cdef bint _stereo

    # methods used by other Cython objects
    cdef bint is_stereo(self) except -1
    cdef generate(self, BufferNode buf)
    cdef get_iter(self)
    cdef BufferNode get_head(self)
    cdef BufferNode get_next(self)

    # methods used internally
    cdef _put_sample(self, double sample, FILE *f)
    cdef _report_clipping(self, double sample)
    cdef _write_output(self, FILE *f)
    cdef _measure(self, bint rate)
