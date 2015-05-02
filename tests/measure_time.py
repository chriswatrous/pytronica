#! /usr/bin/python

from __future__ import division
from time import time

from audio import *

times = []


def average(lst):
    return sum(lst) / len(lst)


#while True:
for _ in range(5):
    #s = Saw2(220, 3600) # .735
    #s = Pan2(NoOp(3600), -.5) # 1.05
    #s = Pan2(Saw2(220, 3600), -.5) # 1.05
    s = NoOp(3600) # .00236
    #s = Silence(3600) # .0803
    t = s.measure_time()
    times.append(t)
    print 'time: {}  average: {}'.format(t, average(times))
