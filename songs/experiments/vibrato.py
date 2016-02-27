#! /usr/bin/python
from __future__ import division

from random import random

from pytronica import *


step = 2.5
c = Controller(0)
c.lineto(.7, 0)
c.lineto(1.5, 1)
c.lineto(100, 1)
c *= 8*Sine(5)
def synth(p):
    f = p2f(p) + c
    return Saw(f, random()) * ExpDecay(.7)
def synth2(s):
    a = Layer()
    for p in notes(s):
        a.add(synth(p))
    return a #* (1 + .2*c)
a = Chain()
a.add(synth2('Ab3 Db4 Eb4 G4'), step)
a.add(synth2('F3 Bb3 C4 Eb4'), step)
a.add(synth2('Gb3 Bb3 Db4 F4'), step)
a.add(synth2('Gb3 Bb3 Db4 Eb4'), step)
a.add(synth2('E3 Bb3 B3 Eb4'), step)
a.add(synth2('Db3 F3 Ab3 Eb4'), step)
a.add(synth2('Bb2 F3 Bb3 D4'), step)
a.add(synth2('Ab2 Eb3 Gb3 D4'), step)
a = Chain([a]*100)
a *= .2
a.play()
#a.audacity()
