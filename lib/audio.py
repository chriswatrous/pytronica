#! /usr/bin/python

import pyximport
pyximport.install()

from osc import Saw
from sig import get_sample_rate, set_sample_rate
from util import p2f, f2p, to_dB, from_dB, note, notes, note_freq, note_freqs, f_range
from synth import stereo_spread
from compose import Compose
from envelopes import ExpDecay, LinearDecay
from combiners import Layer
from modifiers import Pan
import sig
