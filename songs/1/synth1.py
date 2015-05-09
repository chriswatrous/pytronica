#! /usr/bin/python
from __future__ import division
from random import random

if __name__ == '__main__':
    import sys
    sys.path.append('../../lib')

from audio import *

def saw_pitch_spread_synth(pitch, num_osc=3, pitch_spread=0.1, phase_spread=0, random_phase=0):
    osc = Layer()
    ph_step = 1 / num_osc
    ph = 0
    for x in f_range(-pitch_spread, pitch_spread, num_osc):
        osc.add(psaw(pitch + x, phase=ph + random_phase*random()))
        ph += ph_step * phase_spread
    return osc * ExpDecay(0.3)

synth1 = lambda p: saw_pitch_spread_synth(p) / 2.961 # crisp
#synth1 = lambda p: saw_pitch_spread_synth(p, phase_spread=.2) / 2.551 # softer attack
#synth1 = lambda p: saw_pitch_spread_synth(p, phase_spread=1) / 1.544 # fuzzy

#synth1 = lambda p: saw_pitch_spread_synth(p, phase_spread=1, num_osc=10) / 2.331 # swirly
#synth1 = lambda p: saw_pitch_spread_synth(p, phase_spread=.5, num_osc=10) / 5.5 # pop swirl
#synth1 = lambda p: saw_pitch_spread_synth(p, pitch_spread=.15, phase_spread=.3, num_osc=5) / 3.754 # pop small swirl

#synth1 = lambda p: saw_pitch_spread_synth(p, phase_spread=1, random_phase=1, num_osc=10) / 2.331 # attack fuzz
#synth1 = lambda p: saw_pitch_spread_synth(p, pitch_spread=.15, phase_spread=0, num_osc=5) / 4.909 # sharp attack
#synth1 = lambda p: saw_pitch_spread_synth(p, pitch_spread=.15, random_phase=1, num_osc=5) / 3.28 # fuzzy
#synth1 = lambda p: saw_pitch_spread_synth(p, pitch_spread=.2, random_phase=1, num_osc=50) / 10 # wide fuzz

#synth1(note('C4')).playx()

step = 0.18
def arp1(s, pan_spread=1):
    ns = notes(s)
    assert len(ns) == 4
    pans = list(f_range(-pan_spread, pan_spread, len(ns)))
    c = Compose()
    delay = 0
    for x in [0,1,2,1,3,2,1]:
        c.add(synth1(ns[x]).pan(pans[x]), delay)
        delay += step
    c.mlength = step * 7
    return c

def arp1s(ss, *args, **kwargs):
    return Chain(arp1(x, *args, **kwargs) for x in ss)

if __name__ == '__main__':
    #synth1(note('C4'), 0).play()
    a = arp1s(['E3 B3 D4 G4', 'D3 A3 C4 F4', 'G2 D3 F3 Bb3', 'A2 E3 G3 C4'])
    #repeat(a, 8).audacity()
    #b = arp1s(['B2 G3 B3 E4', 'A2 F3 A3 D4', 'D2 Bb2 D3 G3', 'E2 C3 E3 A2'])
    #c = a + b
    #c.mlength = a.mlength
    c = arp1s(['Eb3 G3 Bb3 F4', 'F3 A3 C4 G4'])
    #a.play()
    (repeat(c, 1000)/2).play()
    #(repeat(a, 4)/2).audacity()
