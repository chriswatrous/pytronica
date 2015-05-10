#! /usr/bin/python
from __future__ import division

from random import random

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
#stereo_chord()

def bass():
    t = .15
    c = Chain()
    for x in notes('Db1 Ab1 Eb2 Ab1 F2 Eb2 Ab1'):
        c.add((sine(x) + square(x)).take(t), t)
    c = Chain([c]*4)
    c *= .3
    c.play()
    #c.audacity()
#bass()

def vibrato():
    step = 2
    c = Controller(0)
    c.lineto(.7, 0)
    c.lineto(1.5, 1)
    c.lineto(100, 1)
    c *= 8 * Sine(5)
    def synth(p):
        f = p2f(p) + c
        return Saw(f, random()) * ExpDecay(.7)
    def synth2(s):
        a = Layer()
        for p in notes(s):
            a.add(synth(p))
        return a
    a = Chain()
    a.add(synth2('Ab3 Db4 Eb4 G4'), step)
    a.add(synth2('F3 Bb3 C4 Eb4'), step)
    a.add(synth2('Gb3 Bb3 Db4 F4'), step)
    a.add(synth2('Gb3 Bb3 Db4 Eb4'), step)
    a.add(synth2('E3 Bb3 B3 Eb4'), step)
    a.add(synth2('Db3 F3 Ab3 Eb4'), step)
    a.add(synth2('Bb2 F3 Bb3 D4'), step)
    a.add(synth2('Ab2 Eb3 Gb3 D4'), step)
    a = Chain([a]*100)
    a *= .2
    a.play()
    #a.audacity()
vibrato()
