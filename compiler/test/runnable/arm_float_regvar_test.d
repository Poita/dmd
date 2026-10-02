// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline

/* Float and double register variables tested against zero, including -0.0
 * and NaN.
 */

pragma(inline, false) int tests(const(float)[] a, double d)
{
    int r;
    foreach (x; a)
    {
        float t = x * 2;
        if (t != 0)
            r += 1;
        if (!t)
            r += 10;
        double u = d + x;
        if (u)
            r += 100;
        if (t != 0 && u != 0)
            r += 1000;
    }
    return r;
}

void main()
{
    float[5] a = [0.0f, -0.0f, 1.5f, float.nan, -2.0f];
    // with d = 0: t is nonzero for 1.5, NaN and -2; u likewise
    assert(tests(a[], 0.0) == 3 + 20 + 300 + 3000);
    // with d = 2: u is 2, 2, 3.5, NaN, 0
    assert(tests(a[], 2.0) == 3 + 20 + 400 + 2000);
}
