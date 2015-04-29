#! /usr/bin/python
from time import time
import re
from itertools import islice

from audio import *

from song1_synth import *

pitch_spread = 0.1

step = .18

def part1():
    return 3 * arp1s(['G3 C4 E4 B4', 'A3 D4 F#4 C5']*8)


def part1a():
    return 3 * arp1s(['E3 A3 C4 G4', 'F#3 B3 D4 A4']*8)


def part2():
    def osc(p):
        #return pSaw(p) + Pan(pSaw(p + pitch_spread), -.5) + Pan(pSaw(p - pitch_spread), .5)
        return Pan(pSaw(p + pitch_spread), -.5) + Pan(pSaw(p - pitch_spread), .5)

    def synth(p, d):
        return (osc(p) + osc(p+7)) * ExpDecay(d)

    step = 0.18
    c = Compose()
    delay = 0
    for p in notes('C2 D2 A1 D2'):
        c.add(synth(p, .75), delay)
        delay += step * 14

    for p in notes('C2 D2 A1 D2'):
        c.add(synth(p, .5), delay)
        c.add(synth(p, .5), delay + step*3)
        c.add(synth(p, .5), delay + step*7)
        c.add(synth(p, .5), delay + step*10)
        delay += step * 14

    #c.add(synth(note('C2')), delay)

    #c.add(synth(note('D2')), delay)
    #delay += step*3
    #c.add(synth(note('D2')), delay)
    #delay += step*4
    #c.add(synth(note('D2')), delay)
    #delay += step*4
    #c.add(synth(note('C2')), delay)
    #delay += step*1
    #c.add(synth(note('D2')), delay)
    #delay += step*2
    #c.add(synth(note('C2')), delay)

    return c

def part3():
    pitch_spread = 0.1
    def synth(p):
        return pSaw(p) *  ExpDecay(0.05)
        #return pSaw(p) *  LinearDecay(.8*step)

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

    #co = Controller(1)
    #co.lineto(step*29, 1)
    #co.lineto(step*33.5, 0)

    return c # * ExpDecay(3) * 2

c1 = Compose()
c1.add(.5 * part1(), 0)
c1.add(part2(), 0)

c2 = Compose()
c2.add(.5 * (part1() + part1a()), 0)
c2.add(part2(), 0)
c2.add(part3(), step*4*14)

c = Compose()
c.add(c1, 0)
c.add(c2, step*4*14*2)

a = c
#a = part3()

a *= .2

t = time()
a.play()
#a.rawwrite('1.raw')
print time() - t
