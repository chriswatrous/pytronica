from generator cimport Generator

cdef class SampleBuffer:
    cdef double *data


cdef class BufferNode:
    cdef Generator generator
    cdef BufferNode next
    cdef int length
    cdef bint stereo
    cdef bint has_more
    cdef int uses

    cdef SampleBuffer _left
    cdef SampleBuffer _right
    cdef bint _shared

    cdef clear(self)
    cdef copy_from(self, BufferNode buf)
    cdef share_from(self, BufferNode buf)
    cdef double *get_left(self)
    cdef double *get_right(self)

    cdef _allocate(self)
