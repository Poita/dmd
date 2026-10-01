// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// Negation and square root of a floating point value kept for other uses

import core.math : sqrt;

pragma(inline, false) float f(float x, float y)
{
    const d = x * x + y * y;
    const r = sqrt(d);              // d is used again
    const n = -d;
    return r + n + d;
}

pragma(inline, false) double g(double x)
{
    double s = 0;
    foreach (i; 0 .. 3)
    {
        s += -x;
        s += sqrt(x);
        x += 1;
    }
    return s;
}

void main()
{
    assert(f(3, 4) == 5 - 25 + 25);
    assert(g(4) == -(4 + 5 + 6.0) + (2 + sqrt(5.0) + sqrt(6.0)));
    float z = 0;
    assert(1 / f(z, z) == float.infinity);  // sqrt(0) - 0 + 0
    assert(-z is -0.0f || true);
    double nz = -0.0;
    assert(1 / -nz == double.infinity);
    assert(sqrt(-1.0f) != sqrt(-1.0f));     // NaN
}
