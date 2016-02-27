#! /usr/bin/python
from __future__ import division

from pytronica import *


m = Sine(1.5)
#osc = Saw
#osc = multi_saw([1, 0], [-1, .50])
#osc = multi_saw([1, 0], [-1, .25])
#osc = multi_saw([1, 0], [-1, .25], [1, .55])
#osc = multi_saw([1, 0], [-1, .25], [1, .50])
#osc = multi_saw([1, 0], [-1, .25], [1, .55])
#osc = multi_saw([1, 0], [-1, .25], [1, .50], [1, .7]) # good
#osc = multi_saw([1, 0], [-1, .25], [1, .50], [1, .65]) # good
#osc = multi_saw([1, 0], [-1, .25], [1, .50], [1, .6])
#osc = multi_saw([1, 0], [-.5, .25], [1, .50], [1, .6])
#osc = multi_saw([1.0, .00], [1.0, .30], [1.0, .70])
#osc = multi_saw([1.0, .00], [1.0, .20], [1.0, .40])
osc = multi_saw([1.0, .00], [0.5, .125], [1.0, .25], [1.0, .50]) # good, full, bright
#osc = multi_saw([1.0, .00], [-0.5, .125], [1.0, .25], [1.0, .50])
#osc = multi_saw([1.0, .00], [1.0, .25], [1.0, .50]) # good, a little thin
#osc = multi_saw([1.0, .00], [-1.0, .18], [1.0, .50]) # good
#osc = multi_saw([1, 0], [-1, .375+.125*m])
#osc = multi_saw([.7, 0], [.7, .5+.50*Sine(1.5)], [.5, .5+.50*Sine(2.3)])

def osc1(p):
    #return pitch_spread(p, osc, voices = 5, stereo_spread=1, random_phase=.5)
    #return pitch_spread(p, osc, voices = 4, spread=.1, stereo_spread=1, random_phase=1)
    return pitch_spread(p, osc, voices = 5, spread=.15, stereo_spread=1, random_phase=1)
    #return pitch_spread(p, osc, voices = 5, spread=.20, stereo_spread=1, random_phase=1)
    #return pitch_spread(p, osc, voices = 5, spread=.15, stereo_spread=1, random_phase=0.10).drop(.10)
    #return pitch_spread(p, osc, voices = 5, spread=.15, stereo_spread=1, random_phase=0.05).drop(.1)
    #return pitch_spread(p, osc, voices = 5, spread=.15, stereo_spread=-1, random_phase=0.00).drop(.1)

step = 2

def chord(s):
    a = Layer()
    for p in notes(s):
        a.add(osc1(p))
    return a.take(step)


a = Chain()
a.add(chord('Gb3 Bb3 Db4 F4 Ab4'), step)
a.add(chord('Eb3 G3 Bb3 D4 F4'), step)
a.add(chord('Db3 F3 Ab3 C4 Eb4'), step)
a.add(chord('E3 Ab3 B3 Eb4 Gb4'), step)

a = Chain([a]*1000)

a *= .04
a.play()
#mem_report()
#a.take(10).audacity()
#print a.measure_rate()
