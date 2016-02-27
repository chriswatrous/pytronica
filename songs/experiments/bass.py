#! /usr/bin/python
from __future__ import division

from pytronica import *


def saw(p):
    return Saw(p2f(p))

def sine(p):
    return Sine(p2f(p))

def square(p):
    f = p2f(p)
    return Saw(f) - Saw(f, .5)


t = .15
c = Chain()
for x in notes('Db1 Ab1 Eb2 Ab1 F2 Eb2 Ab1'):
    c.add((sine(x) + saw(x)).take(t), t)
c = Chain([c]*4)
c *= .3
c.play()
#c.audacity()
