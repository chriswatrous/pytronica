#! /usr/bin/python
import re

from audio import *

pitch_spread = 0.1

step = 0.18

def saw(p):
    return Saw(p2f(p))

def part1():
    pitch_spread = 0.1

    def synth(p, pan):
        osc = saw(p)
        osc += saw(p + pitch_spread)
        osc += saw(p - pitch_spread)
        return Pan(osc * ExpDecay(0.3), pan)

    def arp(s):
        ns = notes(s)
        pans = list(span(-.5, .5, len(ns)))
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

    for p in notes('C2 D2 A1'):
        c.add(synth(p), delay)
        c.add(synth(p), delay + step*3)
        c.add(synth(p), delay + step*7)
        c.add(synth(p), delay + step*10)
        delay += step * 14


    c.add(synth(note('D2')), delay)
    delay += step*3
    c.add(synth(note('D2')), delay)
    delay += step*4
    c.add(synth(note('D2')), delay)
    delay += step*4
    c.add(synth(note('C2')), delay)
    delay += step*1
    c.add(synth(note('D2')), delay)
    delay += step*2
    c.add(synth(note('C2')), delay)

    return c

def part3():
    pitch_spread = 0.1
    def synth(p):
        return saw(p) *  ExpDecay(0.05)
        #return saw(p) *  LinearDecay(.8*step)
    c = Compose()
    ps = notes('F#3 G3 A3 C4 D4 F#4 G4 A4 C5 D5 F#5')
    ps = [ps[x] for x in [0, 1, 2, 3, 4, 3, 2, 3, 4, 5, 6, 5, 4, 5, 6, 7, 8, 7, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]]
    delay = 0
    for p in ps:
        c.add(synth(p), delay)
        delay += step / 2
    return c

c = Compose()
c.add(.5 * part1(), 0)
c.add(part2(), 0)
c.add(1.5 * part3(), step*(14*4))

(.25 * c).play()
#(.25 * part3()).play()
