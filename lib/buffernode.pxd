from generator cimport Generator
#cdef class Generator(object):
    #pass

cdef class BufferNode(object):
    cdef Generator generator
    cdef BufferNode next
    cdef int channels
    cdef int length
    cdef bint has_more

    cdef double *_left
    cdef double *_right
    cdef int _uses

    cdef reset(self)
    cdef clear(self)
    cdef copyfrom(self, BufferNode buf)
    cdef double *get_left(self) except NULL
    cdef double *get_right(self) except NULL
    cdef BufferNode get_next(self)
