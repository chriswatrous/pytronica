#! /usr/bin/python
from __future__ import division

from time import time
import re
from itertools import islice

import sys
sys.path.append('../../lib')
from audio import *

from synth1 import *

pitch_spread = 0.1

step = .18

def f(ss):
    return 0.5 * repeat(arp1s(ss), 8)

part1 = f(['G3 C4 E4 B4', 'A3 D4 F#4 C5'])
part1a = part1 + f(['E3 A3 C4 G4', 'F#3 B3 D4 A4'])
#part1a.playx()

def osc(p):
    return psaw(p + pitch_spread).pan(-.5) + psaw(p - pitch_spread).pan(.5)

def synth(p, d):
    return (osc(p) + osc(p+7)) * ExpDecay(d)

def f(d):
    a = Chain()
    for p in notes('C2 D2 A1 D2'):
        a.add(synth(p, d), step * 14)
    return a

a = f(.75)
b = f(.5)

c = Chain()
for x in [3, 4, 3, 4]:
    c.add(b, step * x)
c.mlength = b.mlength

part2 = 0.25 * Chain([a, c])
#part2.playx()

e = part1 * part2
e = e * 3
#e.playx()
#e.audacity()


def part3():
    pitch_spread = 0.1
    def synth(p):
        return psaw(p) *  ExpDecay(0.05)
        #return psaw(p) *  LinearDecay(.8*step)

    arp_idx_steps = [-1, -1, 1, 1, 1, 1]
    def arp_idxs():
        a = 2
        while True:
            for step in arp_idx_steps:
                yield a
                a += step

    arp_pitch_lst = notes('F#3 G3 A3 C4 D4')
    def arp_pitch(i):
        octave = int(i / len(arp_pitch_lst))
        idx = i % len(arp_pitch_lst)
        return arp_pitch_lst[idx] + 12*octave

    c = Compose()
    delay = 0
    for p in islice((arp_pitch(x) for x in arp_idxs()), 67):
        c.add(synth(p), delay)
        delay += step / 2

    return c

c1 = Compose()
c1.add(3 * part1, 0)
c1.add(5 * part2, 0)

c2 = Compose()
c2.add(3 * (part1 + part1a), 0)
c2.add(5 * part2, 0)
c2.add(part3(), step*4*14)

c = Compose()
c.add(c1, 0)
c.add(c2, step*4*14*2)

a = c
#a = part3()

a *= .2

a.play()
#print a.measure_rate()

mem_report()
