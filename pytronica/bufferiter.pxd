from buffernode cimport BufferNode
from generator cimport Generator

cdef class BufferIter:
    cdef BufferNode current
    cdef Generator generator
    cdef bint started

    cdef get_next(self)
