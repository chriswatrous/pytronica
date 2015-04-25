#! /usr/bin/python

from __future__ import division

from audio import *

def e1():
    a = Saw(220)
    b = Saw(440)
    c = .5 * (a * (b)) * LinearDecay(5)
    c.play()
#e1()


def square_wave():
    def pulse(f, ph):
        return Saw(f) + -1 * Saw(f, phase=ph)
    def synth(p, ph):
        return pulse(p2f(p), ph) * ExpDecay(.5) * LinearDecay(2)
    a = synth(60, .3)
    a *= .5
    a.play()
#square_wave()


def stereo_chord():
    def synth(p, pan):
        s = Saw(p2f(p)) * ExpDecay(1)
        return Pan(s, pan)
    ns = notes('F3 Ab3 Db4 Eb4 G4 Bb4')
    pans = list(span(-1, 1, len(ns)))
    a = sum(synth(ns[x], pans[x]) for x in range(len(ns)))
    a *= 1 / 3.33
    a.play()
stereo_chord()
