from libc.stdlib cimport malloc, free
from libc.stdio cimport putchar, fflush, stdout
from libc.string cimport memset
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from collections import deque

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
        self.samples = <double *>PyMem_Malloc(buffer_size * sizeof(double))

    def __dealloc__(self):
        PyMem_Free(self.samples)


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


cdef class ComposeInfo:
    cdef Signal signal
    cdef int start
    cdef int offset
    cdef int length

    def __cinit__(self, Signal signal, int start, int offset):
        self.signal = signal
        self.start = start
        self.offset = offset
        self.length = 0


cdef class Compose(BufferSignal):
    cdef object inputs, waiting, running
    cdef int generate_count
    cdef bint started

    def __init__(self, inputs=None):
        if inputs:
            self.inputs = inputs
        else:
            self.inputs = []

        self.started = False
        self.generate_count = 0

    def add(self, signal, delay):
        self.inputs.append((signal, delay))

    cdef _prepare(self):
        cdef int start, offset
        cdef Signal signal
        cdef double delay

        self.started = True

        self.inputs.sort(key=lambda x: x[1])

        self.waiting = deque()
        self.running = []

        for signal, delay in self.inputs:
            start = <int>((delay * sample_rate) / buffer_size)
            offset = <int>((delay * sample_rate) - (start * buffer_size))
            self.waiting.append(ComposeInfo(signal, start, offset))


    cdef int generate(self) except -1:
        cdef ComposeInfo info
        cdef int i # used for loop iterators
        cdef int length # used for the loop terminator
        cdef int total_length # the total number of samples in the buffer that were touch by any loop

        total_length = 0

        if not self.started:
            self._prepare()

        # End this signal if there are no more child signals to be played.
        if len(self.running) == 0 and len(self.waiting) == 0:
            return 0

        # Zero out the buffer.
        memset(self.samples, 0, buffer_size * sizeof(double))

        # Get the signals that will be starting this round.
        starting = set()
        while True:
            if len(self.waiting) == 0:
                break
            info = self.waiting[0]
            if info.start > self.generate_count:
                break
            x = self.waiting.popleft()
            starting.add(x)
            self.running.append(x)

        done = []
        for info in self.running:
            # Add the end of the previously generated signal to the start of the buffer.
            if info not in starting:
                length = info.length + info.offset - buffer_size
                for i in range(length):
                    self.samples[i] += info.signal.samples[i + buffer_size - info.offset]
                total_length = imax(length, total_length)

            # Generate the signal.
            info.length = info.signal.generate()
            if info.length == 0:
                done.append(info)
                continue

            # Add the start of the generated signal to the end of the buffer.
            length = imin(info.length + info.offset, buffer_size)
            for i in range(info.offset, length):
                self.samples[i] += info.signal.samples[i - info.offset]
            total_length = imax(length, total_length)

        for x in done:
            self.running.remove(x)

        self.generate_count += 1

        if len(self.running) == 0 and len(self.waiting) == 0:
            return total_length
        else:
            return buffer_size


cdef inline int imax(int a, int b):
    return a if a > b else b

cdef inline int imin(int a, int b):
    return a if a < b else b
