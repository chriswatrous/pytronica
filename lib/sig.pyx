from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from subprocess import call, Popen
from random import randrange

from c_util cimport dmax
from combiners import Layer, Multiply
from modifiers import Pan

include "constants.pxi"

cdef double _sample_rate = 48000

def set_sample_rate(r):
    global _sample_rate
    _sample_rate = r

def get_sample_rate():
    return _sample_rate


cdef class Signal(object):
    def __cinit__(self):
        self.sample_rate = _sample_rate

    cdef int generate(self) except -1:
        raise NotImplementedError

    cdef bint is_stereo(self):
        return self.left != self.right

    def __add__(a, b):
        try:
            return Layer(a, b)
        except TypeError:
            return NotImplemented

    def __mul__(a, b):
        try:
            return Multiply(a, b)
        except TypeError:
            return NotImplemented

    def __sub__(a, b):
        try:
            return a + (-1 * b)
        except TypeError:
            return NotImplemented

    def Pan(self, p):
        return Pan(self, p)

    def play(self):
        cdef double sample
        cdef short output_sample
        cdef FILE *fifo
        cdef bint stereo

        self.clip_max = 0
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
        cdef int i, length
        cdef bint stereo

        stereo = self.is_stereo()

        while True:
            length = self.generate()
            if length == 0:
                break
            if stereo:
                for i in range(length):
                    self.put_sample(self.left[i], f)
                    self.put_sample(self.right[i], f)
            else:
                for i in range(length):
                    self.put_sample(self.left[i], f)


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
        if sample > self.clip_max:
            self.clip_max = sample
            print 'Clipping! (max value = {})'.format(self.clip_max)


cdef class BufferSignal(Signal):
    def __cinit__(self):
        self.left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
        self.right = self.left

    cdef make_stereo(self):
        self.right = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))

    def __dealloc__(self):
        if self.right != self.left:
            PyMem_Free(self.right)
        PyMem_Free(self.left)
