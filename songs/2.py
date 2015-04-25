#! /usr/bin/python

from audio import *

#adj = 0.1
#def osc(p):
    #def osc1(p):
        #return Saw(p2f(p))
    #os = [osc1(p+x) for x in [0, 12.03, 7-.03]]
    #return Layer(os)

def saw(p):
    return Saw(p2f(p))

a = .5

def osc(p):
    return Pan(saw(p), -a) + Pan(saw(p+.1), a)

def synth(p):
    return osc(p) * ExpDecay(1)

s = .25 * synth(note('C4'))
s.play()
