import scipy.io.wavfile as wv
from pdb import set_trace
from subprocess import call

from synth import srate, simple_saw_osc, sin_osc

a = sin_osc(1000, 5)
wv.write('out.wav', srate, a) 
#call(['smplayer', 'out.wav'])
call(['audacity', 'out.wav'])

