from __future__ import division

from collections import deque
from random import random

from pytronica.osc import Saw, Sine
from pytronica.util import f_range, p2f
from pytronica.compose import Compose, Chain
from pytronica.combiners import Layer


def psaw(p, *args, **kwargs):
    return Saw(p2f(p), *args, **kwargs)

def psine(p, *args, **kwargs):
    return Sine(p2f(p), *args, **kwargs)

def multi_saw(*args):
    def f(f, phase=0):
        a = Layer()
        for amp, ph in args:
            a.add(amp * Saw(f, phase+ph))
        return a
    return f

def pitch_spread(p, osc, voices=3, spread=.1, stereo_spread=0, phase_spread=0, random_phase=0):
    a = []
    for x in f_range(-1, 1, voices):
        if phase_spread or random_phase:
            a.append(osc(p2f(p + x*spread), x*phase_spread + random_phase*random()))
        else:
            a.append(osc(p2f(p + x*spread)))
    if stereo_spread:
        return st_sp(a, stereo_spread)
    else:
        return Layer(a)


def stereo_spread(signals, spread, center_first = False):
    signals = list(signals)
    if center_first:
        signals = first_to_center(signals)
    pans = f_range(-spread, spread, len(signals))
    return sum(s.pan(p) for (s, p) in zip(signals, pans))

st_sp = stereo_spread # an alias used by pitch_spread

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
