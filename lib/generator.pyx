from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf
from libc.string cimport memset
from libc.math cimport cos, sqrt
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from subprocess import call, Popen
from random import randrange
from time import time

from c_util cimport dmax, imax

include "constants.pxi"

# Sample rate stuff:
cdef double _sample_rate = 48000

def set_sample_rate(r):
    global _sample_rate
    _sample_rate = r

def get_sample_rate():
    return _sample_rate


# Memory tracking stuff:
cdef int _num_buffers
cdef int _max_buffers
cdef int _allocated_buffers
cdef int _freed_buffers

cdef buf_count_inc(channels):
    global _num_buffers, _max_buffers, _allocated_buffers
    _num_buffers += channels
    _max_buffers = imax(_max_buffers, _num_buffers)
    _allocated_buffers += channels

cdef buf_count_dec(channels):
    global _num_buffers, _freed_buffers
    _num_buffers -= channels
    _freed_buffers += channels

def mem_report():
    n = BUFFER_SIZE * sizeof(double)
    print 'Current:   {:,} buffers ({:,} bytes)'.format(_num_buffers, _num_buffers * n)
    print 'Max:       {:,} buffers ({:,} bytes)'.format(_max_buffers, _max_buffers * n)
    print 'Allocated: {:,} buffers ({:,} bytes)'.format(_allocated_buffers, _allocated_buffers * n)
    print 'Freed:     {:,} buffers ({:,} bytes)'.format(_freed_buffers, _freed_buffers * n)


cdef class BufferNode(object):
    cdef double *_left
    cdef double *_right
    cdef int channels

    cdef int length
    cdef BufferNode next
    cdef Generator generator
    cdef bint has_more
    cdef int _uses

    def __cinit__(self, Generator generator, int channels):
        self.reset()

        self.generator = generator
        self.channels = channels

        if channels == 0:
            self._left = NULL
            self._right = NULL
        elif channels == 1:
            self._left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
            self._right = self._left
        elif channels == 2:
            self._left = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
            self._right = <double *>PyMem_Malloc(BUFFER_SIZE * sizeof(double))
        else:
            raise ValueError('channels must be 0, 1, or 2 (got {})'.format(channels))

        buf_count_inc(self.channels)

    def __dealloc__(self):
        self.dispose()

    cdef reset(self):
        self.next = None
        self.has_more = True
        self.length = 0
        self._uses = 0

    cdef dispose(self):
        self.next = None
        self.generator = None

        if self._left != NULL:
            PyMem_Free(self._left)
        if self._right != NULL and self._right != self._left:
            PyMem_Free(self._right)

        buf_count_dec(self.channels)

    cdef double *get_left(self) except NULL:
        if self._left == NULL:
            raise IndexError('This BufferNode was created with 0 channels.')
        return self._left

    cdef double *get_right(self) except NULL:
        if self._right == NULL:
            raise IndexError('This BufferNode was created with 0 channels.')
        return self._right

    cdef BufferNode get_next(self):
        cdef int channels
        self.generator.started = True

        # Generate the next node if it doesn't already exist.
        if not self.next:
            channels = self.channels if self.channels != 0 else (2 if self.generator.is_stereo() else 1)

            # Recycle this node now?
            if self.generator.starters == 1 and self.channels > 0:
                self.generator.generate(self)
                return self

            # Recycle the spare node?
            if self.generator.spare:
                # Recycle.
                self.next = self.generator.spare
                self.generator.spare = None
            else:
                # Create new node.
                self.next = BufferNode(self.generator, channels)

            self.generator.generate(self.next)

        self._uses += 1

        next = self.next

        # If this node will not be used again.
        if self._uses == self.generator.starters:
            if self.channels == 0:
                self.generator.starter = None
                self.dispose()
            else:
                if self.generator.spare:
                    self.dispose()
                else:
                    self.generator.spare = self
                    self.reset()

        return next


cdef class Generator(object):
    cdef double sample_rate
    cdef double _clip_max
    cdef BufferNode starter
    cdef BufferNode spare
    cdef int starters
    cdef bint started

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
        cdef int i, length
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


# Measured at 0.018% of real time.
cdef class Saw2(Generator):
    cdef double step
    cdef double value
    cdef long remaining_samples
    cdef bint finite

    def __init__(self, freq, length=None, phase=0):
        super(Saw2, self).__init__(self)

        self.step = 2 * freq / self.sample_rate

        self.value = phase * 2
        if self.value > 1:
            self.value -= 2
        if length != None:
            self.finite = True
            self.remaining_samples = length * self.sample_rate
        else:
            self.finite = False

    cdef bint is_stereo(self) except -1:
        return False

    cdef generate(self, BufferNode buf):
        cdef int i, length
        cdef double *left

        if self.finite and self.remaining_samples <= 0:
            return 0

        if self.finite and self.remaining_samples <= BUFFER_SIZE:
            length = self.remaining_samples
        else:
            length = BUFFER_SIZE

        left = buf.get_left()

        left[0] = self.value
        for i in range(1, length):
            left[i] = left[i-1] + self.step
            if left[i] > 1:
                left[i] -= 2
        self.value = left[length-1] + self.step

        self.remaining_samples -= length

        buf.length = length
        buf.has_more = not self.finite or self.remaining_samples > 0


# Measured at 0.0091% real time with NoOp as input.
cdef class Pan2(Generator):
    cdef BufferNode inp_buf
    cdef double left_gain, right_gain

    def __cinit__(self, Generator inp, double pan):
        if pan < -1 or pan > 1:
            raise ValueError('Pan must be between -1 and 1.')

        self.inp_buf = inp.get_starter()

        # "Circualar" panning law. -3dB in the middle.
        # This one sounds better than triangle.
        self.left_gain = cos((1 + pan)*PI/4) * sqrt(2)
        self.right_gain = cos((1 - pan)*PI/4) * sqrt(2)

        # "Triangle" panning law. -6dB in the middle
        #self.left_gain = 1 - pan
        #self.right_gain = 1 + pan

        # 0 dB in the middle.
        # This one sounds the best and is cheap.
        # Changed my mind. Cirular sounds better.
        #if pan >= 0:
            #self.left_gain = 1 - pan
            #self.right_gain = 1
        #else:
            #self.left_gain = 1
            #self.right_gain = 1 + pan

    cdef bint is_stereo(self) except -1:
        return True

    cdef generate(self, BufferNode buf):
        cdef int i
        cdef double *left
        cdef double *right
        cdef BufferNode inp_buf

        self.inp_buf = self.inp_buf.get_next()

        left = buf.get_left()
        right = buf.get_right()
        inp_left = self.inp_buf.get_left()
        inp_right = self.inp_buf.get_right()

        for i in range(self.inp_buf.length):
            left[i] = inp_left[i] * self.left_gain
            right[i] = inp_right[i] * self.right_gain

        buf.length = self.inp_buf.length
        buf.has_more = self.inp_buf.has_more


# Measured at 0.0024% real time.
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


# Measured at 0.000092% real time.
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
