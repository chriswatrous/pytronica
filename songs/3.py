#! /usr/bin/python3
from __future__ import division

from pytronica import (
    multi_saw,
    pitch_spread,
    note,
    notes,
    Layer,
    Chain,
    Compose,
    Controller,
)

BPM = 240
BEAT = 60 / BPM


def osc1(p, r):
    o = multi_saw([1.0, .00], [0.5, .125], [1.0, .25], [1.0, .50])
    return pitch_spread(p, o, voices=5, spread=.15, stereo_spread=1,
                        random_phase=r).drop(.1) * 0.1


def synth1(p, l):
    return osc1(p, 1).take(l)


def block1(p):
    return (
        synth1(p + 7, BEAT * 1.5) +
        Chain([
            synth1(p + 4, BEAT * 0.5),
            synth1(p + 2, BEAT * 0.5),
            synth1(p, BEAT * 0.5),
        ])
    )


def block2(p):
    a = block1(p)
    b = Compose([
        [a, 0],
        [a, BEAT * 2.5],
        [a, BEAT * 5],
    ])
    b.mlength = BEAT * 7
    return b


def block3(p):
    a = block1(p)
    b = Compose([
        [a, 0],
        [a, BEAT * 1.5],
        [a, BEAT * 3.5],
        [a, BEAT * 5],
    ])
    b.mlength = BEAT * 7
    return b


def block4():
    a = Chain([
        block2(note('C4')) * .9,
        block2(note('Bb3')) * .9,
    ])
    return Chain([a, a])


def block5():
    a = Chain([
        block3(note('C4')) * .9,
        block3(note('Bb3')) * .9,
    ])
    return Chain([a, a])


def chord_fade(chord1, chord2, synth, length):
    env = Controller(0)
    env.lineto(length / 2, 1)
    env.lineto(length, 0)
    a = Layer([synth(x, length / 2) for x in notes(chord1)])
    b = Layer([synth(x, length / 2) for x in notes(chord2)])
    return Chain([a, b]) * env


def block6():
    l = BEAT * 14
    return Chain([
        chord_fade('D4 E4 G4 C5', 'C4 D4 F4 Bb4', synth1, l),
        chord_fade('A3 Bb3 D4 G4', 'G3 A3 C4 F4', synth1, l),
        chord_fade('Ab3 D4 E4 G4 C5', 'G3 C4 D4 F4 Bb4', synth1, l),
        chord_fade('E3 A3 Bb3 D4 G4', 'D3 G3 A3 C4 F4', synth1, l),
    ])


a = block5()
b = block6()
b.play()
a = Chain([a] * 128)
a = a * 0.9
a.play()

# a = synth1(note('C4'), 1)
# a.play()
