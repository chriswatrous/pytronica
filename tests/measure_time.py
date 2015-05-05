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
        s1 = format_render_time(t)
        s2 = format_render_time(average(self.time_list))
        print ' ' * self.indent + 'time: {}  average: {}'.format(s1, s2)


def format_render_time(t):
    def f_num(n):
        if n > 100:
            return ' {:.0f}'.format(n)
        if n > 10:
            return '{:.1f}'.format(n)
        else:
            return '{:.2f}'.format(n)

    if t >= 1:
        prefix = ''
        m = 1
    elif t >= 1e-3:
        prefix = 'm'
        m= 1e3
    elif t >= 1e-6:
        prefix = 'u'
        m= 1e6
    elif t >= 1e-9:
        prefix = 'n'
        m= 1e9
    elif t >= 1e-12:
        prefix = 'p'
        m= 1e12
    else:
        return '{} s/s'.format(t)

    return '{} {}s/s'.format(f_num(t*m), prefix)


def test_format_render_time():
    for i in range(-15, 6):
        print format_render_time(1.23 * 10**i)
#test_format_render_time()


def measure(s, total_seconds):
    print s
    r = TimeReporter(indent=2)
    for _ in range(5):
        a = eval(s)
        r.report(a.measure_time() / total_seconds)
    print

#measure('NoOp(360)', 360)
#measure('Silence(36)', 360)
#measure('Saw(220, 360)', 360)
#measure('Pan(NoOp(360), -.5)', 360)
#measure('Pan(Saw(220, 360), -.5)', 360)


def measure_layer():
    measure('Saw(220, 360)', 360)
    measure('Saw(220, 360) + Saw(330, 360)', 360)
    measure('Saw(220, 360) + Saw(330, 360) + Saw(330, 360)', 360)
    measure('Saw(220, 360) + Saw(330, 360) + Saw(330, 360) + Saw(330, 360)', 360)
    measure('Saw(220, 360) + Saw(330, 360) + Saw(330, 360) + Saw(330, 360) + Saw(330, 360)', 360)
    measure('Saw(220, 360) + Saw(330, 360) + Saw(330, 360) + Saw(330, 360) + Saw(330, 360) + Saw(330, 360)', 360)

    measure('(lambda x: x)(Saw(220, 360))', 360)
    measure('(lambda x: x+x)(Saw(220, 360))', 360)
    measure('(lambda x: x+x+x)(Saw(220, 360))', 360)
    measure('(lambda x: x+x+x+x)(Saw(220, 360))', 360)
    measure('(lambda x: x+x+x+x+x)(Saw(220, 360))', 360)
    measure('(lambda x: x+x+x+x+x+x)(Saw(220, 360))', 360)

    measure('NoOp(360)', 360)
    measure('NoOp(360) + NoOp(360)', 360)
    measure('NoOp(360)' + ' + NoOp(360)'*2, 360)
    measure('NoOp(360)' + ' + NoOp(360)'*3, 360)
    measure('NoOp(360)' + ' + NoOp(360)'*4, 360)
    measure('NoOp(360)' + ' + NoOp(360)'*5, 360)

    mem_report()

measure_layer()


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
