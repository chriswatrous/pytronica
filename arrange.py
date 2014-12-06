import re, math


def ptof(pitch):
    return 440 * math.pow(2.0, (pitch - 69.0) / 12.0)


def ftop(freq):
    return math.log(freq / 440.0, 2) * 12 + 69


def pitches(pstr):
    if '|' in pstr:
        lst = [pitches(x) for x in pstr.split('|')]
        return [x for x in lst if x]
    else:
        return [pitch(x) for x in pstr.split() if x]


pitch_classes = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11,
                 'cb': -1, 'db': 1, 'eb': 3, 'fb': 4, 'gb': 6, 'ab': 8, 'bb': 10,
                 'c#': 1, 'd#': 3, 'e#': 5, 'f#': 6, 'g#': 8, 'a#': 10, 'b#': 12}


def pitch(pname):
    match = re.match('([a-zA-Z#]+)(-?[0-9]+)', pname)
    if not match:
        raise ValueError("Bad pitch name '{}'".format(pname))
    pitch_class, octave = match.groups()
    return pitch_classes[pitch_class.lower()] + 12 * int(octave) + 12

