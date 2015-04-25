#! /usr/bin/python
from __future__ import division
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


    def test_pan(self):
        def play(pan):
            s = Mul(Saw(note_freq('C4'), .2), 0.25)
            p = Pan(s, pan)
            p.play()
        for x in span(-1, 1, 9):
            play(x)


    def test_stereo_layer(self):
        def synth(p, pan):
            s = Mul(Saw(p2f(p)), 0.20)
            a = AmpMod(s, ExpDecay(2))
            return Pan(a, pan)
        ns = notes('F3 Ab3 Db4 Eb4 G4 Bb4')
        pans = list(span(-1, 1, len(ns)))
        ss = [synth(ns[x], pans[x]) for x in range(len(ns))]
        Layer(ss).play()


    def test_stereo_compose(self):
        def synth(ps, pan):
            ss = [Saw(p2f(x)) for x in ps]
            a = AmpMod(Layer(ss), ExpDecay(0.3))
            a = Mul(a, 0.3)
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


    def test_stereo_mul(self):
        c = Compose()
        c.add(Pan(Saw(220, .2), -.5), 0)
        c.add(Pan(Saw(440, .2), .5), .5)
        m = Mul(c, 0.25)
        m.play()

        # Users would expect the Mul to be stereo even if the compose becomes stereo after
         #it is hooked up to the Mul
        #c = Compose()
        #m = Mul(c, 0.25)
        #c.add(Pan(Saw(220, .2), -.5), 0)
        #c.add(Pan(Saw(440, .2), .5), .5)
        #m.play()



if __name__ == '__main__':
    unittest.main()
