from generator cimport Generator

cdef class BufferNode:
    cdef Generator generator
    cdef BufferNode next
    cdef int length
    cdef bint stereo
    cdef bint has_more

    cdef double *_left
    cdef double *_right
    cdef int uses

    cdef reset(self)
    cdef clear(self)
    cdef copyfrom(self, BufferNode buf)
    cdef double *get_left(self)
    cdef double *get_right(self)
