import re
from math import log, log10

cdef inline int imax(int a, int b):
    return a if a > b else b

cdef inline int imin(int a, int b):
    return a if a < b else b

def p2f(p):
    return 440 * 2**((p - 69)/12.0)

def f2p(f):
    return 69 + 12*log(f/440, 2)

def to_dB(x):
    return 20*log10(x)

def from_dB(x):
    return 10**(x/20)

note_names = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
note_modifiers = {None: 0, 'b': -1, '#': 1}
note_re = re.compile('([A-G])(b|#)?(-?\d+)')
def note(s):
    match = note_re.match(s)
    if not match:
        raise ValueError("Bad note spec '{}'".format(s))
    letter, modifier, octave = match.groups()
    return note_names[letter] + note_modifiers[modifier] + 12 + 12*int(octave)

def notes(s):
    return [note(x) for x in s.split()]

def note_freq(s):
    return p2f(note(s))

def note_freqs(s):
    return map(p2f, notes(s))
