// The core.math functions that are compiler intrinsics on some targets.

import core.math;

T id(T)(T x) { return x; }

void main()
{
    assert(fabs(sin(id(0.5)) - 0.479425538604203) < 1e-12);
    assert(fabs(cos(id(0.5f)) - 0.87758255f) < 1e-6f);
    assert(fabs(sin(id(1.0L)) - 0.8414709848078965L) < 1e-12L);
    assert(rndtol(id(2.5)) == 2 && rndtol(id(3.5f)) == 4 && rndtol(id(-1.5L)) == -2);
    assert(ldexp(id(1.5), 3) == 12.0 && ldexp(id(1.0f), -2) == 0.25f && ldexp(id(1.0L), 10) == 1024.0L);
    assert(rint(id(2.5)) == 2.0 && rint(id(-0.5f)) == -0.0f && rint(id(7.5L)) == 8.0L);
    assert(yl2x(id(1024.0), 1.0) == 10 && yl2x(id(8.0f), 2.0f) == 6);
    assert(fabs(yl2xp1(id(1.0), 3.0) - 3.0) < 1e-12);
    assert(fabs(yl2xp1(id(1023.0L), 1.0L) - 10.0L) < 1e-12L);
}
