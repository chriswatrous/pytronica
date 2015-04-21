from libc.stdlib cimport malloc, free
from libc.stdio cimport putchar, fflush, stdout
from libc.string cimport memset

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

        if self.finite and self.samples_left <= 0:
            return 0

        if self.finite and self.samples_left <= buffer_size:
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


cdef class Mul(BufferSignal):
    cdef Signal inp
    cdef double amount

    def __init__(self, inp, amount):
        self.inp = inp
        self.amount = amount

    cdef int generate(self) except -1:
        cdef int i

        cdef length = self.inp.generate()

        for i in range(length):
            self.samples[i] = self.inp.samples[i] * self.amount

        return length


cdef class Layer(BufferSignal):
    cdef object inputs

    def __init__(self, inputs):
        self.inputs = inputs

    cdef int generate(self) except -1:
        cdef Signal inp
        cdef int length, i
        memset(self.samples, 0, buffer_size * sizeof(double))

        done_signals = []
        cdef int max_length = 0

        for inp in self.inputs:
            length = inp.generate()

            if length == 0:
                done_signals.append(inp)

            if length > max_length:
                max_length = length

            for i in range(length):
                self.samples[i] += inp.samples[i]

        for sig in done_signals:
            self.inputs.remove(sig)

        return max_length


cdef class AmpMod(BufferSignal):
    cdef Signal inp1, inp2

    def __init__(self, inp1, inp2):
        self.inp1 = inp1
        self.inp2 = inp2

    cdef int generate(self) except -1:
        cdef int length1, length2, length, i

        length1 = self.inp1.generate()
        length2 = self.inp2.generate()

        if length1 == 0 or length2 == 0:
            return 0

        length = length1 if length1 > length2 else length2

        for i in range(length):
            self.samples[i] = self.inp1.samples[i] * self.inp2.samples[i]

        return length


cdef class DEnv(BufferSignal):
    cdef double value, step

    def __init__(self, half_life):
        if half_life <= 0:
            raise ValueError('half_life must be a positive number')
        self.value = 1
        self.step = 2**(-1 / sample_rate / half_life)

    cdef int generate(self) except -1:
        cdef int i

        if self.value < 0.0003:
            return 0

        for i in range(buffer_size):
            self.samples[i] = self.value
            self.value *= self.step

        return buffer_size
