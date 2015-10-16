from __future__ import division

from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf
from libc.string cimport memset, memcpy
from libc.math cimport cos, sqrt
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from subprocess import call, Popen
from random import randrange
from time import time

from c_util cimport dmax, imax
from generator cimport Generator

include "constants.pxi"

cdef class SampleBuffer:
    def __cinit__(self):
        self.data = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
        buf_count_inc()

    def __dealloc__(self):
        PyMem_Free(self.data)
        buf_count_dec()


cdef class BufferNode:
    """A linked list node that hold sample data."""

    def __cinit__(self, Generator generator, bint stereo):
        self.next = None
        self.has_more = True
        self.length = 0
        self.uses = 0
        self._left = None
        self._right = None
        self._shared = False

        self.generator = generator
        self.stereo = stereo

    cdef clear(self):
        if self._left == None:
            self._allocate()

        memset(self._left.data, 0, BUFFER_SIZE * sizeof(double))

        if self._right != self._left:
            memset(self._right.data, 0, BUFFER_SIZE * sizeof(double))

    cdef copy_from(self, BufferNode buf):
        """Copy the data from another BufferNode. Use this if the data will be modified."""
        if not self.stereo and buf.stereo:
            raise TypeError('Cannot copy stereo data to a mono buffer')

        if self._left == None:
            self._allocate()

        memcpy(self._left.data, buf._left.data, BUFFER_SIZE * sizeof(double))

        if self._right != self._left:
            memcpy(self._right.data, buf._right.data, BUFFER_SIZE * sizeof(double))

    cdef share_from(self, BufferNode buf):
        """Share the buffers from another BufferNode. Only use this if the data will not be modified."""
        if not self.stereo and buf.stereo:
            raise TypeError('A mono buffer cannot share stereo data.')

        self._left = buf._left
        self._right = buf._right

    cdef double *get_left(self):
        """Get a pointer to the left buffer."""
        if self._left == None:
            self._allocate()

        return self._left.data

    cdef double *get_right(self):
        """Get a pointer to the right buffer."""
        if self._right == None:
            self._allocate()

        return self._right.data

    cdef _allocate(self):
        self._left = SampleBuffer()
        self._right = SampleBuffer() if self.stereo else self._left


# Memory tracking stuff --------------------------------------------

cdef int _num_buffers
cdef int _max_buffers
cdef int _allocated_buffers
cdef int _freed_buffers

cdef buf_count_inc():
    global _num_buffers, _max_buffers, _allocated_buffers
    _num_buffers += 1
    _max_buffers = imax(_max_buffers, _num_buffers)
    _allocated_buffers += 1

cdef buf_count_dec():
    global _num_buffers, _freed_buffers
    _num_buffers -= 1
    _freed_buffers += 1

def mem_report():
    n = BUFFER_SIZE * sizeof(double)
    print 'BufferNode (aproximate) memory usage:'
    print '  Current:   {:,} buffers ({:,} bytes)'.format(_num_buffers, _num_buffers * n)
    print '  Max:       {:,} buffers ({:,} bytes)'.format(_max_buffers, _max_buffers * n)
    print '  Allocated: {:,} buffers ({:,} bytes)'.format(_allocated_buffers, _allocated_buffers * n)
    print '  Freed:     {:,} buffers ({:,} bytes)'.format(_freed_buffers, _freed_buffers * n)

def mem_report_clear():
    global _num_buffers, _max_buffers, _allocated_buffers, _freed_buffers
    _num_buffers = 0
    _max_buffers = 0
    _allocated_buffers = 0
    _freed_buffers = 0
