#! /usr/bin/python
import pyximport
pyximport.install()

import re

from audio import Saw, Mul, Layer, AmpMod, DEnv


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


ss = [Saw(p2f(x)) for x in [43, 57, 58, 62, 65]]
def play_notes(s):
    ss = [Saw(p2f(x)) for x in notes(s)]
    Mul(AmpMod(Layer(ss), DEnv(0.5)), 0.25).play()

play_notes('Ab2 Bb3 C4 Eb4 G4')
play_notes('Gb2 Ab3 Bb3 Db4 F4')
play_notes('A2 B3 C#4 E4 G#4')
play_notes('B2 Db4 Eb4 Gb4 Bb4')

#a = AmpMod(Saw(note_freq('Ab4')), DEnv(1))
#a.play()
