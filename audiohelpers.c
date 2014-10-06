#include <math.h>
#include "audiohelpers.h"

#define TWOPI 6.28318530717959

void simple_saw_helper(double *array, int length, double step)
{
    double phase = 0;
    double *array_end = array + length;
    while (array < array_end)
    {
        *array++ = phase;
        phase += step;
        if (phase > 1) phase -= 2;
    }
}

void sin_helper(double *array, int length, double step)
{
    double phase = 0;
    double *array_end = array + length;
    while (array < array_end)
    {
        *array++ = sin(phase);
        phase += step;
        if (phase > TWOPI) phase -= TWOPI;
    }
}


