#! /usr/bin/python
from __future__ import division
import unittest

from audio import *

class AudioTests(unittest.TestCase):
    def test_sample_rate_changes(self):
        def play_sound():
            (.25 * Saw(p2f(60), 0.5)).play()
        try:
            s = get_sample_rate()
            self.assertEqual(s, 48000)
            play_sound()
            set_sample_rate(2000)
            self.assertEqual(get_sample_rate(), 2000)
            play_sound()
        finally:
            set_sample_rate(s)

    def test_stereo_layer(self):
        def synth(p, pan):
            s = .2 * Saw(p2f(p)) * LinearDecay(3)
            return Pan(s, pan)
        ns = notes('F3 Ab3 Db4 Eb4 G4 Bb4')
        pans = list(span(-1, 1, len(ns)))
        sum(synth(ns[x], pans[x]) for x in range(len(ns))).play()

    def test_stereo_compose(self):
        def env():
            return ExpDecay(0.3) * LinearDecay(2)
        def synth(ps, pan):
            a = 0.3 * sum(Saw(p2f(x)) for x in ps) * env()
            return Pan(a, pan)
        a = lambda: synth(notes('C3 G3 Eb4'), -.5)
        b = lambda: synth(notes('Eb3 Bb3 F4'), .5)
        step = 0.18
        c = Compose()
        c.add(a(), 0)
        c.add(a(), 3*step)
        c.add(b(), 7*step)
        c.add(b(), 10*step)
        c.play()

    # Users might expect the Mul to be stereo even if the compose becomes stereo after
    # it is hooked up to the Mul.
    #def test_stereo_mul(self):
        #c = Compose()
        #m = .25 * c
        #c.add(Pan(Saw(220, .2), -.5), 0)
        #c.add(Pan(Saw(440, .2), .5), .5)
        #m.play()

    def test_operator_multiply(self):
        c = Compose()
        c.add(.25 * Saw(note_freq('A3')) * ExpDecay(.2), 0)
        c.add(Saw(note_freq('C4')) * ExpDecay(.2) * .25, .5)
        c.play()

    def test_operator_add(self):
        f1, f2 = note_freqs('C4 E4')
        c = Compose()
        c.add(.25 * (Saw(f1, .2) + Saw(f2, .2)), 0)
        c.add(1 + .25 * (Saw(f1, .2) + Saw(f2, .2)), .5)
        c.add(.25 * (Saw(f1, .2) + Saw(f2, .2)) + 1, 1)
        c.play()


if __name__ == '__main__':
    unittest.main()
