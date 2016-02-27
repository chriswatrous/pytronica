#! /usr/bin/python3
from __future__ import division

from pytronica import *


def saw(p):
    return Saw(p2f(p))

def sine(p):
    return Sine(p2f(p))

def square(p):
    f = p2f(p)
    return Saw(f) - Saw(f, .5)

def osc(p):
    return (sine(p) + saw(p)) / 2
    # return sine(p)
# def osc(p):
#     o = multi_saw([1.0, .00], [0.5, .125], [1.0, .25], [1.0, .50]) # good, full, bright
#     return o(p2f(p))

def synth(ns):
    os = (osc(p) for p in notes(ns))
    return stereo_spread(os, .75) # * ExpDecay(1)


t = 2

c = Chain()
c.add(synth('F3 Ab3 Db4 Eb4 G4 Bb4').take(t), t)
c.add(synth('G3 Bb3 Eb4 E4 G#4 B4').take(t), t)
c.add(synth('Ab3 B3 E4 Gb4 Bb4 Db5').take(t), t)
c.add(synth('G3 Bb3 Eb4 E4 G#4 B4').take(t), t)
c = Chain([c]*8)
c *= .19
c.play()
#c.audacity()
