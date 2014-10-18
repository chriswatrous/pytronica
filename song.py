import os
import scipy.io.wavfile as wv
import numpy as np
from pdb import set_trace
from subprocess import call
import synth as sy

devnull = open(os.devnull, 'w')
#pitches = sy.ps('E3 C4 D4 F#4')
#pitches = sy.ps('F#3 C4 D4 G4')
#pitches = sy.ps('A2 E3 C4 D4 G4')
#pitches = sy.ps('A1 E3 C4 D4 G4')
#pitches = sy.ps('Eb2 Bb3 C4 D4 G4')
#pitches = sy.ps('A1 G3 B3 C4 D4')
freqs = [sy.ptof(x) for x in pitches]

notes = [sy.simple_saw_osc(x, 5) for x in freqs]
clip = sy.normalize(sy.compose(notes))
wv.write('out.wav', sy.srate, clip) 
call(['/home/Chris/bin/vlc', 'out.wav'], stdout=devnull, stderr=devnull)
#call(['audacity', 'out.wav'])

