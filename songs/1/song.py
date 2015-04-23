#! /usr/bin/python

from os.path import realpath, dirname, join
import sys
sys.path.append(join(dirname(realpath(__file__)), '../../signal'))

from audio import p2f, note, Saw, AmpMod, ExpDecay, Mul, Layer

#adj = 0.1
def osc(p):
    def osc1(p):
        return Saw(p2f(p))
    os = [osc1(p+x) for x in [0, 12.03, 7-.03]]
    return Layer(os)

def synth(p):
    return AmpMod(osc(p), ExpDecay(5))
    #return osc(p)

a = synth(note('C4'))

m = Mul(a, 0.25)
m.play()
