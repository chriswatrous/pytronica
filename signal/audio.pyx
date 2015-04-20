from libc.stdlib cimport malloc, free
from libc.stdio cimport putchar, fflush, stdout

cdef int buffer_size = 1024
cdef double sample_rate = 48000

cdef class Signal:
    cdef double *samples

    cdef int generate(self) except -1:
        raise NotImplementedError

    def play(self):
        cdef int i, length
        cdef double sample
        cdef short output_sample

        while True:
            length = self.generate()
            if length == 0:
                fflush(stdout)
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
        self.samples = <double *>malloc(buffer_size * sizeof(double))

    def __dealloc__(self):
        free(self.samples)


cdef class Saw(BufferSignal):
    cdef double step
    cdef double value
    cdef long samples_left
    cdef bint finite

    def __init__(self, freq, length=None, phase=0):
        super(Saw, self).__init__(self)

        self.step = 2 * freq / sample_rate

        self.value = phase * 2
        if self.value > 1:
            self.value -= 2
        if length != None:
            self.finite = True
            self.samples_left = length * sample_rate
        else:
            self.finite = False


    cdef int generate(self) except -1:
        cdef int i, length

        if self.samples_left <= 0:
            return 0

        if not self.finite and self.samples_left <= buffer_size:
            length = self.samples_left
        else:
            length = buffer_size

        for i in range(length):
            self.samples[i] = self.value
            self.value += self.step
            if self.value > 1:
                self.value -= 2

        self.samples_left -= length

        return length


cdef class MulConst(BufferSignal):
    cdef Signal child
    cdef double amount

    def __init__(self, child, amount):
        self.child = child
        self.amount = amount

    cdef int generate(self) except -1:
        cdef int i

        cdef length = self.child.generate()

        for i in range(length):
            self.samples[i] = self.child.samples[i] * self.amount

        return length
