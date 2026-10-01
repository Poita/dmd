// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Floating point temporaries in the registers a function need not save,
 * and kept across calls
 */

pragma(inline, false) float sq(float x) { return x * x; }

pragma(inline, false) float leaf(float a, float b, float c, float d)
{
    return (a + c) / d + (b + c) / d + (a - b) * (c - d);
}

pragma(inline, false) float acrossCalls(float a, float b)
{
    const t = a * 3 + b;            // live across both calls
    const u = sq(a) + sq(b);
    return t * u + (a - b) * t;
}

pragma(inline, false) double sum(const double[] xs)
{
    double s = 0, c = 0;
    foreach (x; xs)
    {
        const y = x * 0.5 + c;
        s += y;
        c = y * 0.25;
    }
    return s;
}

void main()
{
    assert(leaf(1, 2, 3, 4) == 3.25f);
    assert(acrossCalls(1, 2) == 25 - 5);
    assert(sum([2.0, 4.0, 8.0]) == 1 + 2.25 + (4 + 2.25 * 0.25));
}
