#! /usr/bin/python

from audio import *

#adj = 0.1
#def osc(p):
    #def osc1(p):
        #return Saw(p2f(p))
    #os = [osc1(p+x) for x in [0, 12.03, 7-.03]]
    #return Layer(os)

a = .5
def osc(p):
    return Layer([
        Pan(Mul(Saw(p2f(p)), .25), -a),
        Pan(Mul(Saw(p2f(p+.05)), .25), a)
        ])

def synth(p):
    #return AmpMod(osc(p), ExpDecay(5))
    return osc(p)

synth(note('C4')).play()
