from libc.stdio cimport putc, FILE, fopen, EOF, fclose, printf
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from libc.math cimport cos, sqrt

from subprocess import call, Popen
from random import randrange

from c_util cimport dmax, imax

include "constants.pxi"

cdef double _sample_rate = 48000

def set_sample_rate(r):
    global _sample_rate
    _sample_rate = r

def get_sample_rate():
    return _sample_rate

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
    print 'Current number of buffers: {}'.format(_num_buffers)
    print 'Max buffers: {}'.format(_num_buffers)
    print 'Allocated buffers: {}'.format(_allocated_buffers)
    print 'Freed buffers: {}'.format(_freed_buffers)

cdef class SampleBuffer(object):
    cdef int length
    cdef SampleBuffer next
    cdef Generator generator
    cdef bint stereo
    cdef bint has_more

    def __cinit__(self, generator):
        self.generator = generator
        self.next = None

    cdef double *get_left(self):
        raise NotImplementedError

    cdef double *get_right(self):
        raise NotImplementedError

    cdef SampleBuffer get_next(self):
        if self.next == None:
            buf_type = StereoBuffer if self.stereo else MonoBuffer
            self.next = buf_type(self.generator)
            self.generator.generate(self.next)
        return self.next


cdef class MonoBuffer(SampleBuffer):
    cdef double buf[BUFFER_SIZE]

    def __cinit__(self):
        self.stereo = False
        buf_count_inc(1)

    def __dealloc__(self):
        buf_count_dec(1)

    cdef double *get_left(self):
        return self.buf

    cdef double *get_right(self):
        return self.buf


cdef class StereoBuffer(SampleBuffer):
    cdef double lbuf[BUFFER_SIZE]
    cdef double rbuf[BUFFER_SIZE]

    def __cinit__(self):
        self.stereo = True
        buf_count_inc(2)

    def __dealloc__(self):
        buf_count_dec(2)

    cdef double *get_left(self):
        return self.lbuf

    cdef double *get_right(self):
        return self.rbuf


cdef class Generator(object):
    cdef double sample_rate
    cdef double clip_max
    cdef SampleBuffer first_buf

    def __cinit__(self):
        self.sample_rate = _sample_rate
        self.first_buf = None

    cdef bint is_stereo(self) except -1:
        raise NotImplementedError

    cdef generate(self, SampleBuffer buf):
        raise NotImplementedError

    cdef get_starter(self):
        if self.first_buf == None:
            self.first_buf = SampleBuffer(self)
            self.first_buf.stereo = self.is_stereo()
        return self.first_buf

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
        cdef double *left
        cdef double *right
        cdef bint stereo
        cdef SampleBuffer buf

        stereo = self.is_stereo()

        buf = self.get_starter()

        while True:
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
        if sample > self.clip_max:
            self.clip_max = sample
            print 'Clipping! (max value = {})'.format(self.clip_max)


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

    cdef generate(self, SampleBuffer buf):
        cdef int i, length
        cdef double *left

        if self.finite and self.remaining_samples <= 0:
            return 0

        if self.finite and self.remaining_samples <= BUFFER_SIZE:
            length = self.remaining_samples
        else:
            length = BUFFER_SIZE

        left = buf.get_left()

        for i in range(length):
            left[i] = self.value
            self.value += self.step
            if self.value > 1:
                self.value -= 2

        self.remaining_samples -= length

        buf.length = length
        buf.has_more = not self.finite or self.remaining_samples > 0


cdef class Pan(Generator):
    cdef SampleBuffer inp_buf
    cdef double left_gain, right_gain

    def __cinit__(self, Generator inp, double pan):
        self.make_stereo()

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

    cdef generate(self, SampleBuffer buf):
        cdef int i
        cdef double *left
        cdef double *right
        cdef SampleBuffer inp_buf

        self.inp_buf = self.inp_buf.get_next()

        left = buf.get_left()
        right = buf.get_right()
        inp_left = self.inp_buf.get_left()
        inp_right = self.inp_buf.get_right()

        for i in range(self.inp_buf.length):
            left[i] = inp_left[i] * self.left_gain
            right[i] = inp_right[i] * self.right_gain

        buf.has_more = self.inp_buf.has_more
