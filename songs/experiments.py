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
    step = 2.5
    c = Controller(0)
    c.lineto(.7, 0)
    c.lineto(1.5, 1)
    c.lineto(100, 1)
    c *= 8*Sine(5)
    def synth(p):
        f = p2f(p) + c
        return Saw(f, random()) * ExpDecay(.7)
    def synth2(s):
        a = Layer()
        for p in notes(s):
            a.add(synth(p))
        return a #* (1 + .2*c)
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
#vibrato()

def aliasing():
    c = Controller(5000)
    c.lineto(5, 20000)
    a = Saw(5000+100*Sine(1))
    a *= .2
    a.play()
#aliasing()

def high_freq():
    c = Chain()
    c.add(Sine(5000).take(1), 1)
    c.add(Sine(6000).take(1), 1)
    c.add(Sine(7000).take(1), 1)
    c.add(Sine(8000).take(1), 1)
    c.add(Sine(9000).take(1), 1)
    c.add(Sine(10000).take(1), 1)
    c.add(Sine(11000).take(1), 1)
    c.add(Sine(12000).take(1), 1)
    c.add(Sine(13000).take(1), 1)
    c.add(Sine(14000).take(1), 1)
    c.add(Sine(15000).take(1), 1)
    c.add(Sine(16000).take(1), 1)
    c.add(Sine(17000).take(1), 1)
    c.add(Sine(18000).take(1), 1)
    c.add(Sine(19000).take(1), 1)
    c.add(Sine(22000).take(1), 1)
    c *= .5
    c.play()
    #c.audacity()
#high_freq()

def bass_drum():
    f = Controller(1000)
    f.lineto(.01, 250)
    f.lineto(.08, 40)
    f.lineto(1, 40)

    e = Controller(1)
    e.lineto(.13, 1)
    e.lineto(.18, 0)
    a = e * Saw(f)

    step = 60/120
    c = Chain()
    for _ in range(4):
        c.add(a, step)
    c = Chain([c]*16)
    c.play()
    #c.audacity()
#bass_drum()

def multi_saw_experiment():
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
#multi_saw_experiment()


def ambient1():
    def osc1(p):
        o = multi_saw([1.0, .00], [0.5, .125], [1.0, .25], [1.0, .50])
        return pitch_spread(p, o, voices = 5, spread=.15, stereo_spread=1, random_phase=0).drop(.1)

    step = 20

    def chord(s):
        a = Layer()
        for p in notes(s):
            a.add(osc1(p))
        return a.take(step)

    #m = (0.5 - 0.5 * Saw(20))
    #m = (0.5 + 0.5 * Sine(20))
    #m = (0.5 - 0.5 * Saw(20)) * (1 - 0.5 * (0.5 + 0.5 * Sine(0.3)))
    #m = (0.6 - 0.4 * Saw(20 + 5*Sine(.3, .75))) * (0.8 + 0.2 * Sine(.5))

    co = Controller(0)
    co.lineto(120, 1)
    co.lineto(240, 0)
    co.lineto(10000, 0)

    f1 = 4
    f2 = 20
    s = Saw((f1 + f2)/2 + ((f1 - f2)/2)*Sine(.12, .75))

    b = .30
    m = (1 - b) - b * s * co

    c = Chain()
    c.add(chord('A3 Bb3 D4 F4'), step)
    c.add(chord('C4 D4 F4 A4'), step)
    c.add(chord('B3 C4 E4 G4'), step)
    c.add(chord('C4 E4 F4 A4'), step)

    c = Chain([c]*1000)

    def osc2(p):
        o = multi_saw([1, 0], [-1, .25], [1, .50], [1, .7])
        o = pitch_spread(p, o, voices = 5, spread=.15, stereo_spread=1, random_phase=1)
        o += 0.5 * Sine(p2f(p))
        return o

    c2 = Chain()
    c2.add(osc2(note('G1')).take(step), step)
    c2.add(osc2(note('Bb1')).take(step), step)
    c2.add(osc2(note('A1')).take(step), step)
    c2.add(osc2(note('D2')).take(step), step)
    c2 = Chain([c2]*1000)

    a = m * c

    a += c2

    a *= .05
    a.play()
ambient1()
