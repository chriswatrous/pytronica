from __future__ import division

from collections import deque

from osc import Saw, Sine
from util import f_range, p2f
from compose import Compose, Chain

def psaw(p, *args, **kwargs):
    return Saw(p2f(p), *args, **kwargs)

def psine(p, *args, **kwargs):
    return Sine(p2f(p), *args, **kwargs)

def stereo_spread(signals, spread, center_first = False):
    signals = list(signals)
    if center_first:
        signals = first_to_center(signals)
    pans = f_range(-spread, spread, len(signals))
    return sum(s.pan(p) for (s, p) in zip(signals, pans))

def first_to_center(xs):
    left = True
    d = deque()
    for x in xs:
        if left:
            d.appendleft(x)
        else:
            d.append(x)
        left = not left
    return list(d)

def repeat(sound, times, interval=None):
    if interval == None:
        ch = Chain()
        for _ in range(times):
            ch.add(sound)
        return ch
    else:
        c = Compose()
        delay = 0
        for _ in range(times):
            c.add(sound, delay)
            delay += interval
