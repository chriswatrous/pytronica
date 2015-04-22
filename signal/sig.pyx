from libc.stdio cimport putchar, fflush, stdout
from cpython.mem cimport PyMem_Malloc, PyMem_Free

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
        cdef int i, length
        cdef double sample
        cdef short output_sample

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

                putchar(output_sample & 0xFF)
                putchar((output_sample >> 8) & 0xFF)


cdef class BufferSignal(Signal):
    def __cinit__(self):
        self.samples = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))

    def __dealloc__(self):
        PyMem_Free(self.samples)
