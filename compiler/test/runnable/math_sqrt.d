// core.math.sqrt for each floating point type.

import core.math : sqrt;

float  sf(float x)  { return sqrt(x); }
double sd(double x) { return sqrt(x); }
real   sr(real x)   { return sqrt(x); }

void main()
{
    assert(sf(16.0f) == 4.0f);
    assert(sd(2.25) == 1.5);
    assert(sr(81.0L) == 9.0L);
    assert(sd(-1.0) != sd(-1.0));      // NaN
    assert(sf(0.0f) == 0.0f);
    float f = 2.0f;
    assert(sqrt(f) * sqrt(f) - 2.0f < 1e-6f);
    double d = 1e10;
    assert(sqrt(-d) != sqrt(-d) && sqrt(d) == 1e5);
}
