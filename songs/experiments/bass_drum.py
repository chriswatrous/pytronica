#! /usr/bin/python
from __future__ import division

from pytronica import *


f = Controller(1000)
f.lineto(.01, 250)
f.lineto(.08, 40)
f.lineto(1, 40)

e = Controller(1)
e.lineto(.13, 1)
e.lineto(.18, 0)
a = e * Saw(f)

step = 60/120
c = Chain()
for _ in range(4):
    c.add(a, step)
c = Chain([c]*16)
c.play()
#c.audacity()
