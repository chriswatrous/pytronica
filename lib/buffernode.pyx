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

cdef class BufferNode:
    """A linked list node that hold sample data and provides a mechanism for getting or generating the
    next node and recycling nodes that are no longer used."""

    def __cinit__(self, Generator generator, bint stereo):
        self.reset()

        self.generator = generator
        self.stereo = stereo

        if stereo:
            self._left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
            self._right = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
        else:
            self._left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
            self._right = self._left

        buf_count_inc(2 if self.stereo else 1)

    def __dealloc__(self):
        if self._left != NULL:
            PyMem_Free(self._left)
        if self._right != NULL and self._right != self._left:
            PyMem_Free(self._right)

        buf_count_dec(2 if self.stereo else 1)

    cdef reset(self):
        self.next = None
        self.has_more = True
        self.length = 0
        self.uses = 0

    cdef clear(self):
        memset(self._left, 0, BUFFER_SIZE * sizeof(double))
        if self._right != self._left:
            memset(self._right, 0, BUFFER_SIZE * sizeof(double))

    cdef copyfrom(self, BufferNode buf):
        if self.stereo != buf.stereo:
            fmt = "Number of channels doesn't match. self.stereo = {}, buf.stereo = {}"
            raise TypeError(fmt.format(self.stereo, buf.stereo))
        memcpy(self._left, buf._left, BUFFER_SIZE * sizeof(double))
        if self._right != self._left:
            memcpy(self._right, buf._right, BUFFER_SIZE * sizeof(double))

    # Keep these as functions rather than fields. This encourages saving the pointer as a local variable.
    # In a tight loop, using the pointer in a local variable is a little faster than getting the pointer
    # from an object field every iteration of the loop. (confirmed by testing)
    cdef double *get_left(self):
        """Get a pointer to the left buffer."""
        return self._left

    cdef double *get_right(self):
        """Get a pointer to the right buffer."""
        return self._right


# Memory tracking stuff --------------------------------------------

cdef int _num_buffers
cdef int _max_buffers
cdef int _allocated_buffers
cdef int _freed_buffers

cdef buf_count_inc(channels):
    global _num_buffers, _max_buffers, _allocated_buffers
    _num_buffers += channels
    _max_buffers = imax(_max_buffers, _num_buffers)
    _allocated_buffers += channels

cdef buf_count_dec(channels):
    global _num_buffers, _freed_buffers
    _num_buffers -= channels
    _freed_buffers += channels

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
