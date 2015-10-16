
# I have tried buffer sizes of 100, 1000, and 10000.
# I'm not sure why, but some operations are much faster
# with the buffer size at 10000.
# This should always be a multiple of 20 because some loop unrolling depends on that.
# An actual song seems to render the fastest with a buffer size of 1000.
DEF BUFFER_SIZE = 1000


DEF PI = 3.14159265358979
