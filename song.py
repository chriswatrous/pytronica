#! /usr/bin/python

import os
import scipy.io.wavfile as wv
import numpy as np
from pdb import set_trace
from subprocess import call
import audio as au
import arrange as ar
from arrange import pitches as p

#pitches = p('E3 C4 D4 F#4')
#pitches = p('F#3 C4 D4 G4')
#pitches = p('A2 E3 C4 D4 G4')
#pitches = p('A1 E3 C4 D4 G4')
#pitches = p('E1 B2 D4 F#4 A4')
#pitches = p('Eb2 Bb3 C4 D4 G4')
#pitches = p('A2 B3 C4 E4 G4')
#pitches = p('D2 B3 C4 E4 G4')
#pitches = p('A1 G3 B3 C4 D4')
#pitches = p('D2 F3 G3 C4 E4')
#pitches = p('D2 A2 E3 B3')
#pitches = p('D2 A2 G3 B3 D4')
#pitches = p('D2 A2 F3 G3 C4')
#pitches = p('F2 G3 A3 C4 E4')
#pitches = p('D2 A2 G3 C4 E4 F#4 B4 E5 A5 C6 E6 A6')
#pitches = p('D2 A2')
#pitches = [48, 50.4, 52.8, 55.2, 57.6]
n = 12
pitches = [48 + 12.0/n*x for x in range(n)]

#pitches = p('D2 F3 G3 C4 E4|Eb2 Bb3 C4 D4 G4|E3 C4 D4 F#4|A2 E3 C4 D4 G4|E1 B2 D4 F#4 A4')

freqs = (ar.ptof(x) for x in pitches)

notes = (au.simple_saw_osc(x, 60) for x in freqs)
clip = au.normalize(au.compose(notes))
for pitch in pitches:
    

wv.write('out.wav', au.srate, clip) 

#devnull = open(os.devnull, 'w')
#call(['/home/Chris/bin/vlc', 'out.wav'], stdout=devnull, stderr=devnull)
#call(['audacity', 'out.wav'])

