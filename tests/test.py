#! /usr/bin/python
import unittest

from audio import *

class AudioTests(unittest.TestCase):
    def test_sample_rate_changes(self):
        def play_sound():
            Mul(Saw(p2f(60), 0.5), 0.25).play()

        try:
            s = get_sample_rate()
            self.assertEqual(s, 48000)

            play_sound()

            set_sample_rate(2000)
            self.assertEqual(get_sample_rate(), 2000)

            play_sound()
        finally:
            set_sample_rate(s)

    def test_audio_stuff(self):
        adj = 0.03
        def osc():
            ss = [Saw(p2f(p+a)) for p in notes('F3 A3 C4 D4') for a in [0, adj, -adj]]
            return Layer(ss)

        def synth():
            return Mul(AmpMod(osc(), ExpDecay(0.2)), 0.09)

        c = Compose()
        c.add(synth(), 0)
        c.add(synth(), 0.5)
        c.add(synth(), 0.75)
        c.add(synth(), 1)
        c.play()


unittest.main()
