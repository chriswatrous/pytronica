from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf
from libc.string cimport memset
from libc.math cimport cos, sqrt
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from subprocess import call, Popen
from random import randrange
from time import time

from c_util cimport dmax, imax
from buffernode cimport BufferNode
from buffernode import BufferNode

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


cdef class Generator(object):
    """Abstract base class for objects that generate (or modify) sample data."""

    def __cinit__(self):
        self.sample_rate = _sample_rate
        self.starter = None

    cdef bint is_stereo(self) except -1:
        raise NotImplementedError

    cdef generate(self, BufferNode buf):
        raise NotImplementedError

    def get_starter(self):
        if self.started:
            raise IndexError('Cannot get starter after the first real buffer has been generated.')
        self.starters += 1
        if self.starter == None:
            self.starter = BufferNode(self, channels=0)
        return self.starter

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
        cdef int i
        cdef double *left
        cdef double *right
        cdef bint stereo
        cdef BufferNode buf

        stereo = self.is_stereo()

        buf = self.get_starter()

        while buf.has_more:
            buf = buf.get_next()

            left = buf.get_left()
            right = buf.get_right()

            if stereo:
                for i in range(buf.length):
                    self.put_sample(left[i], f)
                    self.put_sample(right[i], f)
            else:
                for i in range(buf.length):
                    self.put_sample(left[i], f)

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
        cdef BufferNode buf
        t = time()
        buf = self.get_starter()

        while buf.has_more:
            buf = buf.get_next()

        return time() - t


# Measured at 24us/s.
cdef class Silence(Generator):
    cdef long samples_left

    def __cinit__(self, length):
        self.samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        memset(buf.get_left(), 0, BUFFER_SIZE * sizeof(double))

        if self.samples_left <= BUFFER_SIZE:
            buf.has_more = False
            buf.length = self.samples_left
        else:
            buf.has_more = True
            buf.length = BUFFER_SIZE

        self.samples_left -= BUFFER_SIZE


# Measured at 920ns/s real time.
cdef class NoOp(Generator):
    cdef long samples_left

    def __cinit__(self, length):
        self.samples_left = <long>(length * self.sample_rate)

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        if self.samples_left <= BUFFER_SIZE:
            buf.has_more = False
            buf.length = self.samples_left
        else:
            buf.has_more = True
            buf.length = BUFFER_SIZE

        self.samples_left -= BUFFER_SIZE
