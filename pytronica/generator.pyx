from __future__ import division
from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf

from subprocess import call, Popen
from random import randrange
from time import time

from buffernode cimport BufferNode
from bufferiter cimport BufferIter
from combiners import Layer, mul
from modifiers import Pan
from misc import Take, Drop

include "constants.pxi"

# Sample rate stuff:
cdef double _sample_rate = 48000

def set_sample_rate(r):
    """Set the global sample rate for all new objects.
    Already existing objects will still use the old sample rate."""
    global _sample_rate
    _sample_rate = r

def get_sample_rate():
    """Get the global sample rate."""
    return _sample_rate

# Clip reporting stuff:
cdef bint _report_clipping_instant = True
cdef bint _report_clipping_end = False

def set_clip_reporting(setting):
    global _report_clipping_instant, _report_clipping_end
    if setting == 'instant':
        _report_clipping_instant = True
        _report_clipping_end = False
    elif setting == 'end':
        _report_clipping_instant = False
        _report_clipping_end = True
    elif setting == 'off':
        _report_clipping_instant = False
        _report_clipping_end = False
    else:
        raise ValueError("setting must be one of 'instant', 'end', or 'off'")


cdef class Generator:
    """Abstract base class for objects that generate or modify sample data."""

    def __cinit__(self):
        self.sample_rate = _sample_rate
        self.head = None
        self.spare = None
        self._iters = []
        self._head_uses = 0
        self.mlength = 0

    # Operators -----------------------------------------------------------------------------------
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

    def __div__(a, b):
        if isinstance(b, Generator):
            return NotImplemented
        try:
            return a * (1/b)
        except TypeError:
            return NotImplemented

    def __truediv__(a, b):
        return Generator.__div__(a, b)

    # Convenience methods -------------------------------------------------------------------------
    def pan(self, p):
        return Pan(self, p)

    def take(self, length):
        return Take(self, length)

    def drop(self, length):
        return Drop(self, length)

    def slice(self, start, end):
        if end < start:
            raise ValueError('end must be greater than or equal to start')
        return self.drop(start).take(end - start)

    # ---------------------------------------------------------------------------------------------
    cdef BufferNode get_head(self):
        if self._head_uses >= len(self._iters):
            raise IndexError('get_head called too many times')

        if not self.head:
            self._stereo = self.is_stereo()
            self.head = BufferNode(self, self._stereo)
            self.generate(self.head)

        buf = self.head

        # Detach head so the list can be garbage collected.
        self._head_uses += 1
        if self._head_uses == len(self._iters):
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
        if any((<BufferIter?>x).started for x in self._iters):
            raise IndexError('Cannot use a Generator as an input after generation has already started.')

        it = BufferIter(self)
        self._iters.append(it)
        return it

    # Output stuff --------------------------------------------------------------------------------
    def play(self):
        """Play the sound."""
        cdef double sample
        cdef short output_sample
        cdef FILE *fifo
        cdef bint stereo

        with open('/dev/null', 'w') as f:
            call('rm /tmp/fifo-*', shell=True, stdout=f, stderr=f)

        self._clip_max = 0
        stereo = self.is_stereo()

        player_proc = None
        try:
            # Make the FIFO.
            fifo_name = ('/tmp/fifo-' + str(randrange(1e9))).encode()
            call(['mkfifo', fifo_name])

            # Start aplay.
            channels = '2' if stereo else '1'

            player_proc = Popen([
                'aplay',
                '-f', 'S16_LE',
                '-c', channels,
                '-r', str(int(self.sample_rate)),
                fifo_name,
            ])

            # The FIFO must be opened after aplay is started.
            fifo = fopen(fifo_name, 'w')
            self._write_output(fifo)
            fclose(fifo)

            # aplay should receive an EOF and quit when the FIFO is closed.
            player_proc.wait()

        finally:
            # Run even if the user kills with ^C.
            # FIXME This part is not working now for some reason. The code never gets called. I thought
            # it was working earlier.
            if player_proc and player_proc.poll() == None:
                player_proc.terminate()
            call(['rm', fifo_name])

    def playx(self):
        """Play and exit."""
        self.play()
        exit(0)

    def raw_write(self, filename):
        """Write a raw audio file."""
        cdef FILE *f
        f = fopen(filename, 'w')
        stereo = self._write_output(f)
        fclose(f)
        return stereo

    def wav_write(self, filename):
        """Write a wav file."""
        temp_file = '/tmp/{}.raw'.format(randrange(1e9))
        stereo = self.raw_write(temp_file)
        channels = 2 if stereo else 1
        call(['sox',
              '-r', str(self.sample_rate),
              '-e', 'signed',
              '-b', '16',
              '-c', str(channels),
              '-t', 'raw',
              temp_file,
              filename])
        call(['rm', temp_file])

    def audacity(self):
        """Save to temp wav file and open in audacity."""
        temp_file = '/tmp/{}.wav'.format(randrange(1e9))
        self.wav_write(temp_file)
        with open('/dev/null') as f:
            call(['audacity', temp_file], stderr=f)
        call(['rm', temp_file])
        exit(0)

    # Output implementation stuff -----------------------------------------------------------------
    cdef _write_output(self, FILE *f):
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
                    self._put_sample(L[i], f)
                    self._put_sample(R[i], f)
            else:
                for i in range(buf.length):
                    self._put_sample(L[i], f)

            if not buf.has_more:
                break

        if _report_clipping_end and self._clip_max > 1:
            print '\nClipping! (max value = {})\n'.format(self._clip_max)

        return stereo

    cdef _put_sample(self, double sample, FILE *f):
        cdef short output_sample
        cdef int r1, r2

        if sample > 1:
            self._report_clipping(sample)
            sample = 1

        if sample < -1:
            self._report_clipping(sample)
            sample = -1

        output_sample = <short>(sample * 0x7FFF)

        r1 = putc(output_sample & 0xFF, f)
        r2 = putc((output_sample >> 8) & 0xFF, f)

        # putc may return EOF if the user kills aplay before the sound is done playing.
        if r1 == EOF or r2 == EOF:
            raise EOFError

    cdef _report_clipping(self, double sample):
        if sample < 0:
            sample *= -1

        if sample > self._clip_max:
            self._clip_max = sample
            if _report_clipping_instant:
                print 'Clipping! (max value = {})'.format(self._clip_max)

    # Stuff for measuring the execution time of Generators ----------------------------------------
    def measure_time(self):
        """Measures and returns the total execution time of a generator."""
        return self._measure(False)

    def measure_rate(self):
        """Measures and returns the execution time as a fraction of real time."""
        return self._measure(True)

    cdef _measure(self, bint rate):
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

        t = time() - t

        if rate:
            return t / (samples / self.sample_rate)
        else:
            return t
