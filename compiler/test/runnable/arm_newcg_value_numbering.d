/* REQUIRED_ARGS: -O
 */
// Repeated computations and loads within straight line code reused, but not loads
// a store may have changed or volatile ones

import core.volatile;

pragma(inline, false) int reloadAfterStore(int* p, int* q)
{
    const a = *p;
    *q = 5;
    const b = *p;       // q may be p
    return a * 10 + b;
}

pragma(inline, false) int twice(const(int)* p, int i)
{
    return p[i + 1] * 3 + p[i + 1];
}

pragma(inline, false) uint volatileTwice(uint* p)
{
    const a = volatileLoad(p);
    const b = volatileLoad(p);
    return a + b;
}

pragma(inline, false) float sums(const(float)[] k, int n)
{
    float s = 0, w = 0;
    foreach (i; 0 .. n)
    {
        s += k[i + 1] * 2;
        w += k[i + 1];
    }
    return s + w;
}

void main()
{
    int x = 1;
    if (reloadAfterStore(&x, &x) != 15)
        assert(0);
    int y = 1, z = 2;
    if (reloadAfterStore(&y, &z) != 11)
        assert(0);
    int[3] a = [1, 2, 3];
    if (twice(a.ptr, 1) != 12)
        assert(0);
    uint v = 21;
    if (volatileTwice(&v) != 42)
        assert(0);
    float[4] k = [1, 2, 3, 4];
    if (sums(k[], 3) != (2 + 3 + 4) * 3)
        assert(0);
}
