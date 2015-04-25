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
square_wave()
