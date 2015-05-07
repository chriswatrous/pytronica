from __future__ import division
from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf

from subprocess import call, Popen
from random import randrange
from time import time

from buffernode cimport BufferNode
from bufferiter cimport BufferIter
from combiners import Layer, mul

include "constants.pxi"

# Sample rate stuff:
cdef double _sample_rate = 48000

def set_sample_rate(r):
    """Set the global sample rate for all new objects.
    Already existing object will still use the old sample rate."""
    global _sample_rate
    _sample_rate = r

def get_sample_rate():
    """Get the global sample rate."""
    return _sample_rate


cdef class Generator:
    """Abstract base class for objects that generate (or modify) sample data."""

    def __cinit__(self):
        self.sample_rate = _sample_rate
        self.head = None
        self.spare = None
        self.iters = []
        self._head_uses = 0
        self.mlength = 0

    def __add__(a, b):
        try:
            l = Layer()
            l.add(a)
            l.add(b)
            return l
        except TypeError:
            return NotImplemented

    def __mul__(a, b):
        try:
            return mul(a, b)
        except TypeError:
            return NotImplemented

    def __sub__(a, b):
        try:
            return a + (-1 * b)
        except TypeError:
            return NotImplemented

    cdef BufferNode get_head(self):
        if self._head_uses >= len(self.iters):
            raise IndexError('get_head called too many times')

        if not self.head:
            self._stereo = self.is_stereo()
            self.head = BufferNode(self, self._stereo)
            self.generate(self.head)

        buf = self.head

        # Detach head so the list can be garbage collected.
        self._head_uses += 1
        if self._head_uses == len(self.iters):
            self.head = None

        return buf

    cdef BufferNode get_next(self):
        buf = BufferNode(self, self._stereo)
        self.generate(buf)
        return buf

    cdef bint is_stereo(self) except -1:
        raise NotImplementedError

    cdef generate(self, BufferNode buf):
        raise NotImplementedError

    cdef get_iter(self):
        if any((<BufferIter?>x).started for x in self.iters):
            raise IndexError('Cannot use a Generator as an input after generation has already started.')

        it = BufferIter(self)
        self.iters.append(it)
        return it

    def play(self):
        cdef double sample
        cdef short output_sample
        cdef FILE *fifo
        cdef bint stereo

        self._clip_max = 0
        stereo = self.is_stereo()

        try:
            # Make the FIFO.
            fifo_name = '/tmp/fifo-' + str(randrange(1e9))
            call(['mkfifo', fifo_name])

            # Start aplay.
            channels = '2' if stereo else '1'
            cmd = ['aplay', '-f', 'S16_LE', '-c', channels, '-r', str(int(_sample_rate)), fifo_name]
            player_proc = Popen(cmd)

            # The FIFO must be opened after aplay is started.
            fifo = fopen(fifo_name, 'w')
            self.write_output(fifo)
            fclose(fifo)

            # aplay should receive an EOF and quit when the FIFO is closed.
            player_proc.wait()

        finally:
            # Run even if the user kills with ^C.
            # FIXME This part is not working now for some reason. The code never gets called. I thought
            # it was working earlier.
            if player_proc.poll == None:
                player_proc.terminate()
            call(['rm', fifo_name])

    def rawwrite(self, filename):
        cdef FILE *f

        f = fopen(filename, 'w')
        self.write_output(f)
        fclose(f)

    cdef write_output(self, FILE *f):
        cdef BufferNode buf
        cdef BufferIter it

        stereo = self.is_stereo()
        it = self.get_iter()

        while True:
            buf = it.get_next()

            L = buf.get_left()
            R = buf.get_right()

            if stereo:
                for i in range(buf.length):
                    self.put_sample(L[i], f)
                    self.put_sample(R[i], f)
            else:
                for i in range(buf.length):
                    self.put_sample(L[i], f)

            if not buf.has_more:
                break

    cdef put_sample(self, double sample, FILE *f):
        cdef short output_sample
        cdef int r1, r2

        if sample > 1:
            self.report_clipping(sample)
            sample = 1

        if sample < -1:
            self.report_clipping(sample)
            sample = -1

        output_sample = <short>(sample * 0x7FFF)

        r1 = putc(output_sample & 0xFF, f)
        r2 = putc((output_sample >> 8) & 0xFF, f)

        # putc may return EOF if the user kills aplay before the sound is done playing.
        if r1 == EOF or r2 == EOF:
            raise EOFError

    cdef report_clipping(self, double sample):
        if sample < 0:
            sample *= -1

        if sample > self._clip_max:
            self._clip_max = sample
            print 'Clipping! (max value = {})'.format(self._clip_max)

    def measure_time(self):
        cdef BufferIter it
        cdef BufferNode buf
        t = time()

        it = self.get_iter()
        while True:
            buf = it.get_next()
            if not buf.has_more:
                break

        return time() - t

    def measure_rate(self):
        cdef BufferIter it
        cdef BufferNode buf
        cdef long samples
        samples = 0

        t = time()

        it = self.get_iter()
        while True:
            buf = it.get_next()
            samples += buf.length
            if not buf.has_more:
                break

        return (time() - t) / (samples / self.sample_rate)
