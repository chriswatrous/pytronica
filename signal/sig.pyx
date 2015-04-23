from libc.stdio cimport putc, FILE, fopen, EOF
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from subprocess import call, Popen
from random import randrange

include "constants.pxi"

cdef double _sample_rate = 48000

def set_sample_rate(r):
    _sample_rate = r

def get_sample_rate():
    return _sample_rate


cdef class Signal:
    def __cinit__(self):
        self.sample_rate = _sample_rate

    cdef int generate(self) except -1:
        raise NotImplementedError

    def play(self):
        cdef int i, length, r1, r2
        cdef double sample
        cdef short output_sample
        cdef FILE *fifo
        cdef bint exit_loop

        fifo_name = '/tmp/fifo-' + str(randrange(1e9))
        call(['mkfifo', fifo_name])
        cmd = 'aplay -f S16_LE -c 1 -r {} < {}'.format(int(_sample_rate), fifo_name)
        player_proc = Popen(cmd, shell=True)
        fifo = fopen(fifo_name, 'w')

        while True:
            length = self.generate()

            if length == 0:
                return

            for i in range(length):
                sample = self.samples[i]

                if sample > 1:
                    sample = 1

                if sample < -1:
                    sample = -1

                output_sample = <short>(sample * 0x7FFF)

                # These checks are needed in case the user kills the audio player before the
                # song is done.
                r1 = putc(output_sample & 0xFF, fifo)
                r2 = putc((output_sample >> 8) & 0xFF, fifo)
                exit_loop = r1 == EOF or r2 == EOF
                if exit_loop:
                    break
            if exit_loop:
                break

        player_proc.terminate()
        call(['rm', fifo_name])


cdef class BufferSignal(Signal):
    def __cinit__(self):
        self.samples = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))

    def __dealloc__(self):
        PyMem_Free(self.samples)
