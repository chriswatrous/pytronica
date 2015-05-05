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


# Memory tracking stuff:
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


cdef class BufferNode(object):
    """A linked list node that hold sample data and provides a mechanism for getting or generating the
    next node and recycling nodes that are no longer used."""

    def __cinit__(self, Generator generator, int channels):
        self.reset()

        self.generator = generator
        self.channels = channels

        if channels == 0:
            self._left = NULL
            self._right = NULL
        elif channels == 1:
            self._left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
            self._right = self._left
        elif channels == 2:
            self._left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
            self._right = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
        else:
            raise ValueError('channels must be 0, 1, or 2 (got {})'.format(channels))

        buf_count_inc(self.channels)

    def __dealloc__(self):
        self.next = None
        self.generator = None

        if self._left != NULL:
            PyMem_Free(self._left)
        if self._right != NULL and self._right != self._left:
            PyMem_Free(self._right)

        buf_count_dec(self.channels)

    cdef reset(self):
        self.next = None
        self.has_more = True
        self.length = 0
        self._uses = 0

    cdef clear(self):
        if self._left == NULL or self._right == NULL:
            raise IndexError('This BufferNode was created with 0 channels.')
        memset(self._left, 0, BUFFER_SIZE * sizeof(double))
        if self._right != self._left:
            memset(self._right, 0, BUFFER_SIZE * sizeof(double))

    cdef copyfrom(self, BufferNode buf):
        if buf.channels != self.channels:
            fmt = "Number of channels doesn't match. (self: {}  buf: {})"
            raise TypeError(fmt.format(self.channels, buf.channels))
        memcpy(self._left, buf._left, BUFFER_SIZE * sizeof(double))
        if self._right != self._left:
            memcpy(self._right, buf._right, BUFFER_SIZE * sizeof(double))

    # Keep these as functions rather than fields. This encourages saving the pointer as a local variable.
    # In a tight loop, using the pointer in a local variable is a little faster than getting the pointer
    # from an object field every iteration of the loop. (confirmed by testing)
    cdef double *get_left(self) except NULL:
        """Get a pointer to the left buffer."""
        if self._left == NULL:
            raise IndexError('This BufferNode was created with 0 channels.')
        return self._left

    cdef double *get_right(self) except NULL:
        """Get a pointer to the right buffer."""
        if self._right == NULL:
            raise IndexError('This BufferNode was created with 0 channels.')
        return self._right

    cdef BufferNode get_next(self):
        """Get the next node in the list. Generate it if it doesn't already exist. Recycle an old node if
        possible, otherwise allocate a new node."""
        cdef int channels

        if not self.has_more:
            raise IndexError('There are no more nodes to be generated.')

        self.generator.started = True

        # Generate the next node if it doesn't already exist.
        if not self.next:
            channels = self.channels if self.channels != 0 else (2 if self.generator.is_stereo() else 1)

            # Recycle this node now?
            if self.generator.starters == 1 and self.channels > 0:
                self.generator.generate(self)
                return self

            # Recycle the spare node?
            if self.generator.spare:
                # Recycle.
                self.next = self.generator.spare
                self.generator.spare = None
            else:
                # Create new node.
                self.next = BufferNode(self.generator, channels)

            self.generator.generate(self.next)

        self._uses += 1

        next = self.next

        # If this node will not be used again.
        if self._uses == self.generator.starters:
            if self.channels == 0:
                self.generator.starter = None
            else:
                self.generator.spare = self
                self.reset()

        return next
