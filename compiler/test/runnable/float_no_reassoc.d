// REQUIRED_ARGS: -O
// Floating point operations are not reassociated: each rounds in source order.

pragma(inline, false) double add2(double x) { return x + 1e20 + -1e20; }
pragma(inline, false) double mul2(double a) { return (a * 3.0) * 5.0; }
pragma(inline, false) double addr(double x) { return -1e20 + (1e20 + x); }
pragma(inline, false) float addf(float x) { return (x + 1e8f) + -1e8f; }

void main()
{
    assert(add2(1) == 0);
    assert(mul2(0.1) == 0.1 * 3.0 * 5.0);
    assert(mul2(0.1) != 0.1 * 15.0);
    assert(addr(1) == 0);
    assert(addf(1) == 0);
}
