#! /usr/bin/python
from __future__ import division

from pytronica import *


c = Controller(5000)
c.lineto(5, 20000)
a = Saw(5000+100*Sine(1))
a *= .2
a.play()
