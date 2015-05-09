#! /usr/bin/python
from __future__ import division
import unittest
import time

import sys
sys.path.append('../lib')
from audio import *
set_clip_reporting('off')

class Tests(unittest.TestCase):
    def test_sample_rate_changes(self):
        def play_sound():
            a = .25 * Saw(p2f(60)).take(.5)
            a.play()
        try:
            s = get_sample_rate()
            self.assertEqual(s, 48000)
            play_sound()
            set_sample_rate(2000)
            self.assertEqual(get_sample_rate(), 2000)
            play_sound()
        finally:
            set_sample_rate(s)

    def test_take_short(self):
        a = Saw(220).take(.01)
        a.play()

    def test_saw_pan(self):
        s = Saw(220).take(.2)
        p1 = s.pan(.5)
        p2 = s.pan(-.5)
        p1.play()
        p2.play()

    def test_layer(self):
        a = Saw(note_freq('C4')).take(.2) + Saw(note_freq('E4')).take(.2)
        b = a + 1.9
        a.play()
        b.play()

    def test_const_mul(self):
        a = Saw(note_freq('C4')).take(.2) * .25
        a.play()

    def test_mul(self):
        f1, f2 = note_freqs('C5 E5')
        a = Saw(f1) * Saw(f2).take(.2)
        a.play()

    def test_decays(self):
        a = Saw(220) * ExpDecay(.1)
        a.play()
        a = Saw(220) * LinearDecay(.5)
        a.play()

    def test_use_simul(self):
        a = Saw(220).take(.2)
        b = a * a
        b.play()

    def test_compose(self):
        c = Compose()
        c.add(Saw(220).take(.2), 0)
        c.add(Saw(330).take(.2), .2)
        c.play()

    def test_chain(self):
        f1, f2 = note_freqs('C4 F#3')
        a = Saw(f1).take(.2)
        a.mlength = .2
        b = Saw(f2).take(.2)
        b.mlength = .2
        ch = Chain([a, b])
        ch.play()

    def test_controller(self):
        co = Controller(0)
        co.lineto(0.5, 1)
        co.lineto(1.0, 0)
        co.lineto(1.5, 1)
        co.lineto(2.0, 0)
        a = .5 * Saw(220) * co
        a.play()

    def test_chain_bug(self):
        s = Saw(220).take(.1)
        s.mlength = .5
        c1 = Chain()
        c1.add(s, .25)
        c2 = Chain([s, c1])
        c2.play()

    def test_sub(self):
        c = Chain()
        c.add(Saw(220).take(.2) - Saw(220, 0.5).take(.2), .5)
        c.add(2 - Saw(220).take(.2), .5)
        c.add(Saw(220).take(.2) - 2, .5)
        (.5 * c).play()

    def test_div(self):
        a = Saw(220).take(.2) / 4
        a.play()

    def test_clip_reporting(self):
        set_clip_reporting('end')
        (Saw(220).take(.1) * 1.2).play()
        set_clip_reporting('instant')
        (Saw(220).take(.1) * 1.2).play()
        set_clip_reporting('off')
        (Saw(220).take(.1) * 1.2).play()

    def test_sine(self):
        Sine(440).take(.2).play()

    def test_stereo_mul(self):
        c = Compose()
        m = .25 * c
        # (Compose becomes stereo after it is used as an input.)
        c.add(Saw(220).take(.2).pan(-.5), 0)
        c.add(Saw(440).take(.2).pan(.5), .5)
        m.play()

    def test_mul_const_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a *= .5
        c = Chain()
        for _ in range(4):
            c.add(a)
        c.play()

    def test_mul_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a = a * a
        c = Chain()
        for _ in range(4):
            c.add(a)
        c.play()

    def test_layer_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a = a + 1
        c = Chain()
        for _ in range(4):
            c.add(a)
        c.play()

    def test_pan_mlength(self):
        a = Sine(440).take(.1)
        a.mlength = .2
        a = a.pan(-.5)
        c = Chain()
        for _ in range(4):
            c.add(a)
        c.play()

    #def test_adsr(self):
        #a = Saw(220) * ADSREnvelope(attack=.5, decay=.5, sustain=.25, release=.05, length=2)
        #a.play()


class ErrorTests(unittest.TestCase):
    def test_operator_errors(self):
        self.assertRaises(TypeError, lambda: Saw(220) + 'a')
        self.assertRaises(TypeError, lambda: Saw(220) - 'a')
        self.assertRaises(TypeError, lambda: Saw(220) * 'a')
        self.assertRaises(TypeError, lambda: 'a' + Saw(220))
        self.assertRaises(TypeError, lambda: 'a' - Saw(220))
        self.assertRaises(TypeError, lambda: 'a' * Saw(220))

    def test_controller_errors(self):
        with self.assertRaises(ValueError):
            co = Controller(0)
            co.lineto(1, 1)
            co.lineto(.5, 0)
        with self.assertRaises(IndexError):
            co = Controller(0)
            co.play()


if __name__ == '__main__':
    unittest.main()
