#! /usr/bin/python
from __future__ import division

import sys
sys.path.append('../lib')
from audio import *

# parameters
reps = 4
step = 20

# chord track ---------------------------------------------------------------------------------
def osc1(p, r):
    o = multi_saw([1.0, .00], [0.5, .125], [1.0, .25], [1.0, .50])
    return pitch_spread(p, o, voices = 5, spread=.15, stereo_spread=1, random_phase=r).drop(.1)

def chord(s, r):
    a = Layer()
    for p in notes(s):
        a.add(osc1(p, r))
    return a.take(step)

co = Controller(0)
co.lineto(6*step, 1)
co.lineto(12*step, 0)
co.lineto(1000*step, 0)

f1 = 4
f2 = 20
s = Saw((f1 + f2)/2 + ((f1 - f2)/2)*Sine(.12, .75))

b = .30
m = (1 - b) - b * s * co

c = Chain()
r = 1
for _ in range(reps):
    for s in ['A3 Bb3 D4 F4', 'C4 D4 F4 A4', 'B3 C4 E4 G4', 'C4 E4 F4 A4']:
        c.add(chord(s, r), step)
        r *= .75

chord_track = c * m


# bass track ----------------------------------------------------------------------------------
def osc2(p):
    o = multi_saw([1, 0], [-1, .25], [1, .50], [1, .7])
    o = pitch_spread(p, o, voices = 5, spread=.15, stereo_spread=1, random_phase=1)
    o += 0.5 * Sine(p2f(p))
    return o

c = Chain()
for p in notes('G1 Bb1 A1 D2'):
    c.add(osc2(p).take(step), step)

bass_track = Chain([c]*reps)


# whole song ----------------------------------------------------------------------------------
# volume envelope for whole song
c = Controller(0)
c.lineto(step, 1)
c.lineto(12*step, 1)
c.lineto(16*step, 0)

a = chord_track + bass_track
a *= c
a *= .05
a.play()
#a.audacity()
