#! /usr/bin/python
from __future__ import division

from pytronica import *

#adj = 0.1
#def osc(p):
    #def osc1(p):
        #return Saw(p2f(p))
    #os = [osc1(p+x) for x in [0, 12.03, 7-.03]]
    #return Layer(os)

a = .5
saw = lambda p: Saw(p2f(p))
osc = lambda p: Pan(saw(p), -a) + Pan(saw(p+.1), a)
def synth(p):
    return osc(p) * ExpDecay(1)

s = .25 * synth(note('C4'))
s.play()
