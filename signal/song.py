#! /usr/bin/python
import pyximport
pyximport.install()

from audio import Saw, Signal

s = Saw(110, 1)
s.play()

