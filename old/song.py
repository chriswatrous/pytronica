#! /usr/bin/python

from __future__ import division

import os
from subprocess import call

from numpy import ndarray

from audio import simple_saw_osc
from arrange import pitches as p, ptof
from clip import Clip


tempo = 240.0
beat = 60.0 / tempo


def main():
    generate_clip().normalized().wavwrite('out.wav')

    #devnull = open(os.devnull, 'w')
    #call(['/home/Chris/bin/vlc', 'out.wav'], stdout=devnull, stderr=devnull)
    #call(['audacity', 'out.wav'])


def generate_clip():
    #pitches = p('A2 B3 C4 E4 G4')
    #pitches = p('F2 Ab3 C4 Eb4 G4')

    #chords = p('D2 F3 G3 C4 E4|Eb2 Bb3 C4 D4 G4|E3 C4 D4 F#4|A2 E3 C4 D4 G4|E1 B2 D4 F#4 A4')
    #length = 2

    #chords = [
        #'D2 F3 G3 C4 E4',
        #'Eb2 Bb3 C4 D4 G4',
        #'A2 B3 C4 D4 G4',
        #'E2 C#4 D4 F#4 A4',
        #'F2 Ab3 Eb4 G4 Bb4',
        #'C2 A3 Bb3 D4 F4 G4 C5',
        #'C2 Bb3 Db4 E4 F#4 A4 C5',
    #]*4
    chords = [
        'D2 F3 G3 C4 E4',
        'Eb2 Bb3 C4 D4 G4',
        'A2 B3 C4 D4 G4',
        'E2 C#4 D4 F#4 A4',
        'F2 Ab3 Eb4 G4 Bb4',
        'C2 Bb3 D4 F4 G4',
        'C2 Bb3 Db4 E4 F#4',
    ] * 20
    #chords = [
        #'D2 A2 F#3',
        #'D2 Bb2 E3',
        #'D2 B2 F#3',
        #'D2 BB2 F3',
        #'D2 A2 F#3',
        #'D2 Bb2 E3',
        #'D2 B2 F#3',
        #'D2 BB2 F3',
        #'D2 A2 F#3',
        #'D2 Bb2 E3',
        #'D2 B2 F#3',
        #'D2 BB2 F3',
    #]


    clip = Clip()
    clip.compose(Clip(), 5*60)
    offset = 0
    for notes in chords:
        rhythm = [x/2 for x in [1, 2, 1, 3, 3, 1, 3]]
        s = 0.4
        l = 1.25
        durations = [s, s, s, s, l, s, s]
        clip.compose(pattern(notes, rhythm, durations, simple_saw_osc), offset)
        offset += sum(rhythm) * beat
    return clip


def pattern(pitches, rhythm, durations, synth):
    clip = Clip()
    offset = 0
    for step, dur in zip(rhythm, durations):
        clip.compose(chord(pitches, dur * beat, synth), offset)
        offset += beat * step
    return clip


def chord(pitches, length, synth):
    if type(pitches) == str:
        pitches = p(pitches)
    clip = Clip()
    for pitch in pitches:
        freq = ptof(pitch)
        clip.compose(synth(freq, length))
    return clip


if __name__ == '__main__':
    main()
