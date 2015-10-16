cdef inline int imax(int a, int b):
    return a if a > b else b

cdef inline int imin(int a, int b):
    return a if a < b else b

cdef inline double dmax(double a, double b):
    return a if a > b else b

cdef inline double dmin(double a, double b):
    return a if a < b else b
