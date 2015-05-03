#! /usr/bin/python

from __future__ import division
from time import time

from audio import *

times = []

def average(lst):
    return sum(lst) / len(lst)

class TimeReporter(object):
    def __init__(self):
        self.time_list = []

    def report(self, t):
        self.time_list.append(t)
        print 'time: {}  average: {}'.format(t, sum(self.time_list) / len(self.time_list))



def test1():
    print 'test1'
    r = TimeReporter()
    for _ in range(5):
        #s = Saw(220, 3600) # .735
        s = Pan(NoOp(3600), -.5) # 0.38
        #s = Pan(Saw(220, 3600), -.5) # 1.05
        #s = NoOp(3600) # .00236
        #s = Silence(3600) # .0803

        r.report(s.measure_time())
    print
#test1()


def test2():
    print 'test2'
    r1 = TimeReporter()
    r2 = TimeReporter()
    for _ in range(5):
        #mem_report_clear()
        s = Saw(220, 3600)
        p1 = Pan(s, -.5)
        p2 = Pan(s, .5)
        r1.report(p1.measure_time())
        mem_report()
        r2.report(p2.measure_time())
        mem_report()
        print
    print
test2()
