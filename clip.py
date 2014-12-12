import sys

import numpy
import scipy.io.wavfile
from numpy import zeros

srate = 48000

class Clip(object):
    def __init__(self, data=None):
        if data == None:
            self.data = zeros(0)
        else:
            self.data = data


    def copy(self):
        return Clip(self.data.copy())


    def compose(self, clip, offset=0):
        offset = int(offset * srate)
        if clip.data.size + offset <= self.data.size:
            self.data[offset : clip.data.size + offset] += clip.data
        else:
            new_data = zeros(clip.data.size + offset)
            new_data[0 : self.data.size] += self.data
            new_data[offset : clip.data.size + offset] += clip.data
            self.data = new_data
        return self


    def normalize(self):
        self.data /= numpy.max(numpy.abs(self.data))
        return self


    def normalized(self):
        return self.copy().normalize()
        

    def wavwrite(self, filename):
        print 'wavwrite({})'.format(repr(filename))
        sys.stdout.flush()
        scipy.io.wavfile.write(filename, srate, self.data)


    # It's more complicated than this.
    #@staticmethod
    #def wavread(self, filename):
        #clip = Clip()
        #clip.data = scipy.io.wavfile.read(filename)
        #return clip
