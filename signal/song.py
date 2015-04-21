#! /usr/bin/python
import pyximport
pyximport.install()

import re

from audio import Saw, Mul, Layer, AmpMod, DEnv, Compose


def p2f(p):
    return 440 * 2**((p - 69)/12.0)

note_names = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
note_modifiers = {None: 0, 'b': -1, '#': 1}
note_re = re.compile('([A-G])(b|#)?(-?\d+)')

def note(s):
    match = note_re.match(s)
    if not match:
        raise ArgumentException("Bad note spec '{}'".format(s))
    letter, modifier, octave = match.groups()
    return note_names[letter] + note_modifiers[modifier] + 12 + 12*int(octave)

def notes(s):
    return [note(x) for x in s.split()]

def note_freq(s):
    return p2f(note(s))

def play_notes(s):
    ss = [Saw(p2f(x)) for x in notes(s)]
    return AmpMod(Layer(ss), DEnv(0.4))

#c = Compose()
#delay = 0
#step = 1.5
#for s in ['Ab2 Bb3 C4 Eb4 G4', 'Gb2 Ab3 Bb3 Db4 F4', 'A2 B3 C#4 E4 G#4', 'B2 Db4 Eb4 Gb4 Bb4']*4:
    #c.add(play_notes(s), delay)
    #delay += step

#a = AmpMod(Saw(note_freq('Ab4')), DEnv(1))
#a.play()

adj = 0.1
def osc(p):
    ss = [Saw(p2f(p+adj*x)) for x in range(-2, 3)]
    return Layer(ss)

def synth(p):
    return AmpMod(osc(p), DEnv(0.5))

c = Compose()
delay = 0
step = 0.2

for p in (notes('Ab3 C4 Eb4 G4') * 4 + notes('Eb3 G3 Bb3 D4') * 4)*4:
    c.add(synth(p), delay)
    delay += step


m = Mul(c, 0.15)
m.play()
