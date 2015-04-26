#! /usr/bin/python
import re
from itertools import islice

from audio import *

pitch_spread = 0.1

step = 0.18

def saw(p):
    return Saw(p2f(p))

def part1():
    pitch_spread = 0.1
    pan_spread = 1

    def synth(p, pan):
        osc = saw(p)
        osc += saw(p + pitch_spread)
        osc += saw(p - pitch_spread)
        return Pan(osc * ExpDecay(0.3), pan)

    def arp(s):
        ns = notes(s)
        pans = list(f_range(-pan_spread, pan_spread, len(ns)))
        c = Compose()
        delay = 0
        for x in [0,1,2,1,3,2,1]:
            c.add(synth(ns[x], pans[x]), delay)
            delay += step
        return c

    def arp1():
        c = Compose()
        c.add(arp('G3 C4 E4 B4'), 0)
        c.add(arp('A3 D4 F#4 C5'), step*7)
        return c

    c = Compose()
    for x in range(8):
        c.add(arp1(), step*14*x)

    return c


def part1a():
    pitch_spread = 0.1
    pan_spread = 1

    def synth(p, pan):
        osc = saw(p)
        osc += saw(p + pitch_spread)
        osc += saw(p - pitch_spread)
        return Pan(osc * ExpDecay(0.3), pan)

    def arp(s):
        ns = notes(s)
        pans = list(f_range(-pan_spread, pan_spread, len(ns)))
        c = Compose()
        delay = 0
        for x in [0,1,2,1,3,2,1]:
            c.add(synth(ns[x], pans[x]), delay)
            delay += step
        return c

    def arp1():
        c = Compose()
        c.add(arp('E3 A3 C4 G4'), 0)
        c.add(arp('F#3 B3 D4 A4'), step*7)
        return c

    c = Compose()
    for x in range(8):
        c.add(arp1(), step*14*x)

    return c


def part2():
    def osc(p):
        #return saw(p) + Pan(saw(p + pitch_spread), -.5) + Pan(saw(p - pitch_spread), .5)
        return Pan(saw(p + pitch_spread), -.5) + Pan(saw(p - pitch_spread), .5)

    def synth(p):
        return (osc(p) + osc(p+7)) * ExpDecay(.5)

    step = 0.18
    c = Compose()
    delay = 0
    for p in notes('C2 D2 A1 D2'):
        c.add(synth(p), delay)
        delay += step * 14

    for p in notes('C2 D2 A1 D2'):
        c.add(synth(p), delay)
        c.add(synth(p), delay + step*3)
        c.add(synth(p), delay + step*7)
        c.add(synth(p), delay + step*10)
        delay += step * 14

    c.add(synth(note('C2')), delay)
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
        return saw(p) *  ExpDecay(0.05)
        #return saw(p) *  LinearDecay(.8*step)

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
    for p in islice((arp_pitch(x) for x in arp_idxs()), 60):
        c.add(synth(p), delay)
        delay += step / 2
    return c


c = Compose()
c.add(.5 * part1(), 0)
c.add(.5 * part1a(), 0)
c.add(part2(), 0)
c.add(1 * part3(), step*(14*4))

a = c
#a = part2()

a *= .2
a.play()
