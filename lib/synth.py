from __future__ import division

from collections import deque

from osc import Saw
from util import f_range, p2f
from compose import Compose

def pSaw(p, *args, **kwargs):
    return Saw(p2f(p), *args, **kwargs)

def stereo_spread(signals, spread, center_first = False):
    signals = list(signals)
    if center_first:
        signals = first_to_center(signals)
    pans = f_range(-spread, spread, len(signals))
    return sum(s.Pan(p) for (s, p) in zip(signals, pans))

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
