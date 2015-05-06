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

        if self.current and not self.current.has_more:
            raise IndexError('There are no more nodes to be generated.')

        # First node?
        if not self.current:
            # Get or generate first node.
            if self.generator.head:
                self.current = self.generator.head
            else:
                self.current = BufferNode(self.generator, self.generator.is_stereo())
                self.generator.head = self.current
                self.generator.generate(self.current)
            return self.current

        # Only one BufferIter for this Generator?
        elif len(self.generator.iters) == 1:
            # Reuse the current node.
            assert self.current.next == None
            self.generator.generate(self.current)
            return self.current

        self.current.uses += 1

        # Next already exists?
        if self.current.next:
            # Should the current node be recycled?
            next = self.current.next
            if self.current.uses == len(self.generator.iters):
                self.current.reset()
                self.generator.spare = self.current
                self.generator.head = None
            self.current = next
            return self.current

        # Generate next node.
        # Recycle the spare node?
        if self.generator.spare:
            # Recycle.
            self.current.next = self.generator.spare
            self.generator.spare = None
        else:
            # Create new node.
            self.current.next = BufferNode(self.generator, self.current.stereo)
        self.current = self.current.next
        self.generator.generate(self.current)
        return self.current
