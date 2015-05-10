#! /usr/bin/python
from __future__ import division
import unittest
import time
from subprocess import call

import sys
from os import chdir
from os.path import realpath, dirname, exists, isdir

sys.path.append('../lib')
from audio import *

chdir(dirname(realpath(__file__)))
set_clip_reporting('off')

class Tests(unittest.TestCase):
    def test_sample_rate(self):
        try:
            set_sample_rate(2000)
            a = Saw(220).take(.2)
            compare_outputs(a, 'outputs/sample_rate.wav')
        finally:
            set_sample_rate(48000)

    def test_take_short(self):
        a = Saw(220).take(.01)
        compare_outputs(a, 'outputs/take_short.wav')

    def test_saw_pan(self):
        s = Saw(220).take(.2)
        p1 = s.pan(.5)
        p2 = s.pan(-.5)
        compare_outputs(p1, 'outputs/saw_pan1.wav')
        compare_outputs(p2, 'outputs/saw_pan2.wav')

    def test_layer(self):
        a = Saw(note_freq('C4')).take(.2) + Saw(note_freq('E4')).take(.2)
        b = a + 1.9
        compare_outputs(a, 'outputs/layer1.wav')
        compare_outputs(b, 'outputs/layer2.wav')

    def test_const_mul(self):
        a = Saw(note_freq('C4')).take(.2) * .25
        compare_outputs(a, 'outputs/const_mul.wav')

    def test_mul(self):
        f1, f2 = note_freqs('C5 E5')
        a = Saw(f1) * Saw(f2).take(.2)
        compare_outputs(a, 'outputs/mul.wav')

    def test_decays(self):
        c = Chain()
        c.add(Saw(220) * ExpDecay(.1), 1)
        c.add(Saw(220) * LinearDecay(.5), 1)
        compare_outputs(c, 'outputs/decays.wav')

    def test_use_simul(self):
        a = Saw(220).take(.2)
        b = a * a
        compare_outputs(b, 'outputs/use_simul.wav')

    def test_compose(self):
        c = Compose()
        c.add(Saw(220).take(.2), 0)
        c.add(Saw(330).take(.2), .2)
        compare_outputs(c, 'outputs/compose.wav')

    def test_chain(self):
        f1, f2 = note_freqs('C4 F#3')
        a = Saw(f1).take(.2)
        a.mlength = .2
        b = Saw(f2).take(.2)
        b.mlength = .2
        c = Chain([a, b])
        compare_outputs(c, 'outputs/chain.wav')

    def test_controller(self):
        co = Controller(0)
        co.lineto(0.5, 1)
        co.lineto(1.0, 0)
        a = .5 * Saw(220) * co
        compare_outputs(a, 'outputs/controller.wav')

    def test_chain_bug(self):
        s = Saw(220).take(.1)
        s.mlength = .5
        c = Chain()
        c.add(s, .25)
        c = Chain([s, c])
        compare_outputs(c, 'outputs/chain_bug.wav')

    def test_sub(self):
        s1 = Saw(220).take(.2)
        s2 = Saw(220, 0.5).take(.2)
        c = Chain()
        c.add(s1 - s2, .2)
        c.add(2 - s1, .2)
        c.add(s1 - 2, .2)
        c = .5 * c
        compare_outputs(c, 'outputs/sub.wav')

    def test_div(self):
        a = Saw(220).take(.2) / 4
        compare_outputs(a, 'outputs/div.wav')

    #def test_clip_reporting(self):
        #set_clip_reporting('end')
        #(Saw(220).take(.1) * 1.2).play()
        #set_clip_reporting('instant')
        #(Saw(220).take(.1) * 1.2).play()
        #set_clip_reporting('off')
        #(Saw(220).take(.1) * 1.2).play()

    def test_sine(self):
        a = Sine(440).take(.2)
        compare_outputs(a, 'outputs/sine.wav')

    def test_stereo_mul(self):
        c = Compose()
        m = .25 * c
        # (Compose becomes stereo after it is used as an input.)
        c.add(Saw(220).take(.2).pan(-.5), 0)
        c.add(Saw(440).take(.2).pan(.5), .5)
        compare_outputs(m, 'outputs/stereo_mul.wav')

    def test_mul_const_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a *= .5
        c = Chain()
        for _ in range(4):
            c.add(a)
        compare_outputs(c, 'outputs/mul_const_mlength.wav')

    def test_mul_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a = a * a
        c = Chain()
        for _ in range(4):
            c.add(a)
        compare_outputs(c, 'outputs/mul_mlength.wav')

    def test_layer_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a = a + 1
        c = Chain()
        for _ in range(4):
            c.add(a)
        compare_outputs(c, 'outputs/layer_mlength.wav')

    def test_pan_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a = a.pan(-.5)
        c = Chain()
        for _ in range(4):
            c.add(a)
        compare_outputs(c, 'outputs/pan_mlength.wav')

    def test_drop(self):
        f1, f2 = note_freqs('C4 E4')
        c = Chain()
        c.add(Sine(f1).take(.2), .2)
        c.add(Sine(f2).take(.2), .2)
        c = c.drop(.15)
        compare_outputs(c, 'outputs/drop.wav')

    def test_slice(self):
        f1, f2 = note_freqs('C4 E4')
        c = Chain()
        c.add(Sine(f1).take(.2), .2)
        c.add(Sine(f2).take(.2), .2)
        c = c.slice(.15,.25)
        compare_outputs(c, 'outputs/slice.wav')

    def test_variable_saw(self):
        c = Chain()
        c.add(Saw(220 + 50*Saw(4, .5)).take(1), 1)
        c.add(Saw(220, 2*Sine(4)).take(1), 1)
        compare_outputs(c, 'outputs/variable_saw.wav')


class ErrorTests(unittest.TestCase):
    def test_operator_errors(self):
        self.assertRaises(TypeError, lambda: Saw(220) + 'a')
        self.assertRaises(TypeError, lambda: Saw(220) - 'a')
        self.assertRaises(TypeError, lambda: Saw(220) * 'a')
        self.assertRaises(TypeError, lambda: 'a' + Saw(220))
        self.assertRaises(TypeError, lambda: 'a' - Saw(220))
        self.assertRaises(TypeError, lambda: 'a' * Saw(220))

    def test_controller_errors(self):
        with self.assertRaisesRegexp(ValueError, 'time must not be earlier then the previous time'):
            co = Controller(0)
            co.lineto(1, 1)
            co.lineto(.5, 0)
        with self.assertRaisesRegexp(IndexError, 'There are no control moves in the queue.'):
            c = Controller(0)
            c.measure_time()


def compare_outputs(gen, filename):
    if isdir(filename):
        raise IOError('{} is a directory.'.format(filename))

    if not exists(filename):
        raise IOError('{} does not exist.'.format(filename))

    gen.wav_write('outputs/temp.wav')

    with open('/dev/null', 'w') as f:
        exit_code = call(['diff', 'outputs/temp.wav', filename], stdout=f, stderr=f)

    if exit_code != 0:
        raise AssertionError('Files outputs/temp.wav and {} do not match.'.format(filename))


if __name__ == '__main__':
    unittest.main()
