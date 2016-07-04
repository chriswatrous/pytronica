from __future__ import division
import re
from math import log, log10


def p2f(p):
    """
    Get the frequency from a pitch (MIDI note number).
    """
    return 440 * 2**((p - 69)/12.0)


def f2p(f):
    """
    Get the pitch (MIDI note number) for a frequency.
    """
    return 69 + 12*log(f/440, 2)


def to_dB(x):
    """
    Get the dB value for an amplitude.

    >>> to_dB(1)
    0.0
    >>> to_dB(10)
    20.0
    >>> to dB(0.1)
    -20.0
    """

    return 20*log10(x)


def from_dB(x):
    return 10**(x/20)


note_names = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
note_modifiers = {None: 0, 'b': -1, '#': 1}
note_re = re.compile('([A-G])(b|#)?(-?\d+)')


def note(s):
    """
    Get the pitch (MIDI note number) for a pitch name.

    >>> note('C4')
    60
    >>> note('Eb4')
    63
    >>> note('F#4')
    66
    >>> note('C-1')
    0
    >>> note('G9')
    127
    """
    match = note_re.match(s)
    if not match:
        raise ValueError("Bad pitch name '{}'".format(s))
    letter, modifier, octave = match.groups()
    return note_names[letter] + note_modifiers[modifier] + 12 + 12*int(octave)


def notes(s):
    return [note(x) for x in s.split()]


#note_spec_re = re.compile(r'(-*|\+*)$')
#def notes2(s):
    #note_specs = s.split()
    #octave = int(note_specs[0])


def note_freq(s):
    return p2f(note(s))


def note_freqs(s):
    return map(p2f, notes(s))


def f_range(start, end, count):
    """f_range(start, end, count)

    A generator yielding count floats evenly spaced from start to end.
    Start and end are yielded exactly, with no loss of precision.
    """
    step = (end - start) / (count - 1)
    for n in range(count - 1):
        yield start + n*step
    yield end
