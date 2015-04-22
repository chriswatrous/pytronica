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
    ss = [Saw(p2f(p+adj*x)) for x in range(-1, 2)]
    return Layer(ss)

def synth(p):
    return AmpMod(osc(p), DEnv(0.3))

c = Compose()
delay = 0
step = 0.18

#for p in (notes('Ab3 C4 Eb4 G4') * 4 + notes('Eb3 G3 Bb3 D4') * 4)*4:
for p in notes('G3 C4 E4 C4 B4 E4 C4  A3 D4 F#4 D4 C5 F#4 D4') * 8:
    c.add(synth(p), delay)
    delay += step

def synth2(p):
    return AmpMod(Layer([osc(p), osc(p+7)]), DEnv(.5))

c2 = Compose()
delay = 0
for p in notes('C2 D2 A1 D2'):
    c2.add(synth2(p), delay)
    delay += step * 14

for p in notes('C2 D2 A1'):
    c2.add(synth2(p), delay)
    c2.add(synth2(p), delay + step*3)
    c2.add(synth2(p), delay + step*7)
    c2.add(synth2(p), delay + step*10)
    delay += step * 14


c2.add(synth2(note('D2')), delay)
delay += step*3
c2.add(synth2(note('D2')), delay)
delay += step*4
c2.add(synth2(note('D2')), delay)
delay += step*4
c2.add(synth2(note('C2')), delay)
delay += step*1
c2.add(synth2(note('D2')), delay)
delay += step*2
c2.add(synth2(note('C2')), delay)

def part3():
    def synth(p):
        return AmpMod(osc(p), DEnv(0.1))
    c = Compose()
    ps = notes('F#3 G3 A3 C4 D4 F#4 G4 A4 C5 D5 F#5')
    ps = [ps[x] for x in [0, 1, 2, 3, 4, 3, 2, 3, 4, 5, 6, 5, 4, 5, 6, 7, 8, 7, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]]
    delay = step*(14*4 + 4)
    for p in ps:
        c.add(synth(p), delay)
        delay += step / 2
    return c

m = Mul(Layer([c, c2, part3()]), 0.15)
#m = Mul(part3(), 0.15)
m.play()
