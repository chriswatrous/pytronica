#! /usr/bin/python

import pyximport
pyximport.install()

from sig import get_sample_rate, set_sample_rate
from util import p2f, f2p, to_dB, from_dB, note, notes, note_freq, note_freqs, f_range
from synth import stereo_spread, pSaw
from compose import Compose
from envelopes import ExpDecay, LinearDecay
from combiners import Layer, Chain
from controller import Controller
import sig

# new architecture
from misc import Silence, NoOp
from buffernode import mem_report, mem_report_clear
from osc import Saw
from modifiers import Pan
