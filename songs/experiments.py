#! /usr/bin/python
from __future__ import division

import sys
sys.path.append('../lib')
from audio import *

def saw(p):
    return Saw(p2f(p))

def sine(p):
    return Sine(p2f(p))

def square(p):
    f = p2f(p)
    return Saw(f) - Saw(f, .5)


def e1():
    a = Saw(220)
    b = Saw(440)
    c = .5 * (a * (b)) * LinearDecay(5)
    c.play()
#e1()


def square_wave():
    def pulse(f, ph):
        return Saw(f) + -1 * Saw(f, ph)
    def synth(p, ph):
        return pulse(p2f(p), ph) * ExpDecay(.5) * LinearDecay(2)
    a = synth(60, .3)
    a *= .5
    a.play()
#square_wave()


def stereo_chord():
    def osc(p):
        #return (sine(p) + saw(p)) / 2
        return sine(p)
    def synth(ns):
        os = (osc(p) for p in notes(ns))
        return stereo_spread(os, .75) # * ExpDecay(1)
    a = synth('F3 Ab3 Db4 Eb4 G4 Bb4')
    a *= .19
    a = a.take(5)
    a.play()
    #a.audacity()
stereo_chord()

def bass():
    c = Chain()
    for x in notes('Db1 Ab1 Eb2 F2 Eb2 Ab1 Db1'):
        c.add(sine(x).take(.2) + square(x).take(.2), .2)
    c *= .3
    c.play()
    #c.audacity()
#bass()
