#! /usr/bin/python
import pyximport
pyximport.install()

from audio import Saw, MulConst

s = Saw(220, 1)
m = MulConst(s, 0.05)
m.play()
