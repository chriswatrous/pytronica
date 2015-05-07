from __future__ import division

from generator cimport Generator
from buffernode cimport BufferNode

include "constants.pxi"

cdef class BufferIter:
    def __cinit__(self, generator):
        self.generator = generator
        self.current = None
        self.started = False

    cdef get_next(self):
        """Get the next node in the list. Generate it if it doesn't already exist."""
        self.started = True

        if self.current:
            if not self.current.has_more:
                raise IndexError('There are no more nodes to be generated.')

            if self.current.next:
                self.current = self.current.next
            else:
                self.current.next = self.generator.get_next()
                self.current = self.current.next
        else:
            self.current = self.generator.get_head()

        return self.current
