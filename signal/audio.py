import pyximport
pyximport.install()

from osc import Saw
from sig import get_sample_rate, set_sample_rate
from compose import Compose
from envelopes import ExpDecay
from combiners import Layer, AmpMod
from modifiers import Mul
