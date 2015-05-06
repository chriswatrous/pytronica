
# I have tried buffer sizes of 100, 1000, and 10000.
# I'm not sure why, but some operations are much faster
# with the buffer size at 10000.
# This should always be a multiple of 20 because some loop unrolling depends on that.
DEF BUFFER_SIZE = 10000


DEF PI = 3.14159265358979
