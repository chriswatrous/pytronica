#! /usr/bin/python
from __future__ import division
from random import random

if __name__ == '__main__':
    import sys
    sys.path.append('../../lib')

from audio import *

pitch_spread = 0.1
def synth1(p, pan, random_phase=False):
    if random_phase:
        osc = pSaw(p, phase=random())
        osc += pSaw(p + pitch_spread, phase=random())
        osc += pSaw(p - pitch_spread, phase=random())
    else:
        osc = pSaw(p)
        osc += pSaw(p + pitch_spread)
        osc += pSaw(p - pitch_spread)
    return 1/3 * Pan(osc * ExpDecay(0.3), pan)


step = 0.18
def arp1(s, pan_spread=1):
    ns = notes(s)
    assert len(ns) == 4
    pans = list(f_range(-pan_spread, pan_spread, len(ns)))
    c = Compose()
    delay = 0
    for x in [0,1,2,1,3,2,1]:
        c.add(synth1(ns[x], pans[x]), delay)
        delay += step
    c.mlength = step * 7
    return c

def arp1s(ss, *args, **kwargs):
    return Chain(arp1(x, *args, **kwargs) for x in ss)

if __name__ == '__main__':
    #synth1(note('C4'), 0).play()
    a = arp1s(['E3 B3 D4 G4', 'D3 A3 C4 F4', 'G2 D3 F3 Bb3', 'A2 E3 G3 C4'])
    #a.play()
    repeat(a, 1000).play()
