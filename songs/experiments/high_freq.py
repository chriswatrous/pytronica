#! /usr/bin/python
from __future__ import division

from pytronica import *


c = Chain()
c.add(Sine(5000).take(1), 1)
c.add(Sine(6000).take(1), 1)
c.add(Sine(7000).take(1), 1)
c.add(Sine(8000).take(1), 1)
c.add(Sine(9000).take(1), 1)
c.add(Sine(10000).take(1), 1)
c.add(Sine(11000).take(1), 1)
c.add(Sine(12000).take(1), 1)
c.add(Sine(13000).take(1), 1)
c.add(Sine(14000).take(1), 1)
c.add(Sine(15000).take(1), 1)
c.add(Sine(16000).take(1), 1)
c.add(Sine(17000).take(1), 1)
c.add(Sine(18000).take(1), 1)
c.add(Sine(19000).take(1), 1)
c.add(Sine(22000).take(1), 1)
c *= .5
c.play()
#c.audacity()
