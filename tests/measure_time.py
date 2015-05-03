#! /usr/bin/python

from __future__ import division
from time import time

from audio import *

times = []

def average(lst):
    return sum(lst) / len(lst)


class TimeReporter(object):
    def __init__(self, indent=0):
        self.time_list = []
        self.indent = indent

    def report(self, t):
        self.time_list.append(t)
        print ' ' * self.indent + 'time: {}  average: {}'.format(t, sum(self.time_list) / len(self.time_list))


def measure(s):
    print s
    r = TimeReporter(indent=2)
    for _ in range(5):
        a = eval(s)
        r.report(a.measure_time())
    print

measure('NoOp(3600)')
measure('Silence(3600)')
measure('Saw(220, 3600)')
measure('Pan(NoOp(3600), -.5)')
measure('Pan(Saw(220, 3600), -.5)')


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
#test2()
