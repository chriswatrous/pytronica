from generator cimport Generator
#cdef class Generator(object):
    #pass

cdef class BufferNode(object):
    cdef double *_left
    cdef double *_right
    cdef int channels

    cdef int length
    cdef BufferNode next
    cdef Generator generator
    cdef bint has_more
    cdef int _uses

    cdef reset(self)
    cdef double *get_left(self) except NULL
    cdef double *get_right(self) except NULL
    cdef BufferNode get_next(self)
