#! /usr/bin/python3
from __future__ import division

import sys
from math import log2, ceil

from pytronica import (
    multi_saw,
    pitch_spread,
    note,
    note_freq,
    note_freqs,
    notes,
    p2f,
    Layer,
    Chain,
    Compose,
    Controller,
    Noise,
    ExpDecay,
    Sine,
)

###############################################################################
#
# Config
#

# notes = ('E3 A3 C4 D4 G4 '
#          'F3 B3 D4 E4 A4 '
#          'G3 C4 E4 F4 B4 '
#          'A3 D4 F4 G4 C5')
# notes = 'A2 Bb2 D3 F3 A3 C4 G3'
# notes = ('B2 Eb3 Gb3 Ab3 '
#          'Bb2 D3 F3 Ab3 '
#          'A2 Db3 E3 Ab3 '
#          'Bb2 D3 F3 Ab3 '
#          'B2 Eb3 Gb3 Ab3')
# notes = ('B2 D3 F#3 A3 C#4 E4 '
#          'A2 C3 E3 G3 B3 D4 '
#          'C3 Eb3 G3 Bb3 D4 F4 '
#          'D3 F3 A3 C4 E4 G4 '
#          'B2 D3 F#3 A3 C#4 E4')
# notes = (
#     'Bb4 A4 G4 E4 Eb4 '
#     'G4 F#4 E4 C#4 C4 '
#     'E4 D#4 C#4 Bb3 A3 '
#     'Db4 C4 Bb3 G3 F#3'
# )
# notes = (
#     'E3 F#3 A3 C#4 A3 '
#     'F#3 G3 Bb3 Eb4 Bb3 '
#     'G3 A3 C4 E4 C4 '
#     'A3 Bb3 C#4 F#4 C#4'
# )
# notes = 'F#1 C#2 B1 F#2 E2 B2 A2 D2 G1'
# notes = (
#     'F#1 A#1 B1 C#2 E2 '
#     'F#2 A#2 B2 C#3 E3 '
#     'F#3 A#3 B3 C#4 E4 '
#     'F#4'
# )

# freqs = note_freqs(notes)
# freqs = freqs + list(reversed(freqs[:-1]))


scale = 'C4 D4 E4 F4 G4 A4 B4'
pattern = [0, 1, 3, 4, 5]
note_range = 'C3 A4'
steps = [4, 5, 6, 7]

tempo = 140
note_lengths = [1/4, 1/3, 1/2, 2/3, 1]

###############################################################################


def main():
    scale_pitches = notes(scale)
    pitch_range = notes(note_range)

    i_start = lowest_index(scale_pitches, pitch_range[0])

    pitches = []
    for x in steps:
        for y in pattern:
            pitches.append(scale_pitch(scale_pitches, x + y + i_start))

    n_lengths = note_lengths + list(reversed(note_lengths[1:-1]))

    a = Chain([practice_block(pitches, x) for x in n_lengths])
    a = Chain([a] * 1000)
    a.play()


def scale_pitch(pitches, n):
    return pitches[n % len(pitches)] + (n // len(pitches)) * 12


def lowest_index(pitches, lower_limit):
    if scale_pitch(pitches, 0) == lower_limit:
        return 0
    elif scale_pitch(pitches, 0) > lower_limit:
        i = 0
        while scale_pitch(pitches, i) >= lower_limit:
            i -= 1
        return i + 1
    else:
        i = 0
        while scale_pitch(pitches, i) < lower_limit:
            i += 1
        return i


def practice_block(pitches, note_length):
    beat = 60 / tempo
    osc1 = multi_saw([1.0, .00])
    freqs = [p2f(x) for x in pitches]

    tick_decay = 0.001

    tick1 = Sine(3000) * ExpDecay(tick_decay)
    tick1.mlength = beat

    tick = Sine(1500) * ExpDecay(tick_decay)
    tick.mlength = beat
    ticks = Chain([tick1] + [tick] * ceil(len(freqs)*note_length + 3))

    ch = Chain(start_offset=beat*4)
    for freq in freqs:
        ch.add(osc1(freq).take(beat * note_length))

    return ch * 0.2 + ticks


if __name__ == '__main__':
    main()
