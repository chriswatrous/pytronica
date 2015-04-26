#! /usr/bin/python
from __future__ import division
import unittest

from audio import *

class Tests(unittest.TestCase):
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
        f1, f2 = note_freqs('C4 E4')
        a = Saw(f1, .5).Pan(-.5) + Saw(f2, .5).Pan(.5)
        a *= .25
        a.play()

    def test_stereo_compose(self):
        f1, f2 = note_freqs('C4 E4')
        c = Compose()
        c.add(Saw(f1, .5).Pan(-.5), 0)
        c.add(Saw(f2, .5).Pan(.5), .5)
        (.25 * c).play()

    # Users might expect the Mul to be stereo even if the compose becomes stereo after
    # it is hooked up to the Mul.
    #def test_stereo_mul(self):
        #c = Compose()
        #m = .25 * c
        #c.add(Saw(220, .2).Pan(-.5), 0)
        #c.add(Saw(440, .2).Pan(.5), .5)
        #m.play()

    def test_mul(self):
        f = note_freq('F#3')
        c = Compose()
        c.add(.25 * Saw(f) * ExpDecay(.2), 0)
        c.add(Saw(f) * ExpDecay(.2) * .25, .5)
        c.play()

    def test_add(self):
        f1, f2 = note_freqs('C4 E4')
        c = Compose()
        c.add(.25 * (Saw(f1, .2) + Saw(f2, .2)), 0)
        c.add(1 + .25 * (Saw(f1, .2) + Saw(f2, .2)), .5)
        c.add(.25 * (Saw(f1, .2) + Saw(f2, .2)) + 1, 1)
        c.play()

    def test_sub(self):
        c = Compose()
        c.add(Saw(220, .5) - Saw(220, .5, phase=0.5), 0)
        c.add(2 - Saw(220, .5), .5)
        c.add(Saw(220, .5) - 2, 1)
        (.5 * c).play()


class ErrorTests(unittest.TestCase):
    def test_operator_errors(self):
        self.assertRaises(TypeError, lambda: Saw(220) + 'a')
        self.assertRaises(TypeError, lambda: Saw(220) - 'a')
        self.assertRaises(TypeError, lambda: Saw(220) * 'a')
        self.assertRaises(TypeError, lambda: 'a' + Saw(220))
        self.assertRaises(TypeError, lambda: 'a' - Saw(220))
        self.assertRaises(TypeError, lambda: 'a' * Saw(220))


if __name__ == '__main__':
    unittest.main()
