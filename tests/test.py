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


    def test_pan(self):
        def play(pan):
            s = Mul(Saw(note_freq('C4'), .2), 0.25)
            p = Pan(s, pan)
            p.play()
        for x in span(-1, 1, 9):
            play(x)


    def test_stereo_layer(self):
        def synth(p, pan):
            s = Mul(Saw(p2f(p)), 0.25)
            a = AmpMod(s, ExpDecay(0.5))
            #return a
            return Pan(a, pan)
        #ns = notes('Eb3 G3 Bb3 F4')
        ns = notes('F3 Ab3 Db4 Eb4 G4 Bb4')
        #ns = notes('Ab3 Eb4 Bb4 G4 Db4 F3')
        pans = list(span(-.5, .5, len(ns)))
        ss = [synth(ns[x], pans[x]) for x in range(len(ns))]
        Layer(ss).play()


unittest.main()
