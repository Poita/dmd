/* REQUIRED_ARGS: -O
 */
// Fills of 4 and 8 byte elements, and copies of large aggregates

struct Big { long[40] a; }

pragma(inline, false) void fillU(uint[] a, uint v) { a[] = v; }
pragma(inline, false) void fillF(float[] a, float v) { a[] = v; }
pragma(inline, false) void fillL(long[] a, long v) { a[] = v; }
pragma(inline, false) void fillD(double[] a, double v) { a[] = v; }
pragma(inline, false) void copyBig(ref Big d, ref const Big s) { d = s; }
pragma(inline, false) Big makeBig(long x) { Big b; foreach (i, ref e; b.a) e = x + i; return b; }

void main()
{
    uint[7] u;
    fillU(u[1 .. 6], 0xDEADBEEF);
    if (u[0] != 0 || u[6] != 0)
        assert(0);
    foreach (x; u[1 .. 6])
        if (x != 0xDEADBEEF)
            assert(0);
    float[5] f;
    fillF(f[], 2.5f);
    foreach (x; f)
        if (x != 2.5f)
            assert(0);
    long[3] l;
    fillL(l[], -3);
    foreach (x; l)
        if (x != -3)
            assert(0);
    double[4] d;
    fillD(d[0 .. 3], 0.25);
    if (d[0] != 0.25 || d[2] != 0.25 || d[3] == d[3])
        assert(0);
    Big a = makeBig(5), b;
    copyBig(b, a);
    foreach (i, x; b.a)
        if (x != 5 + i)
            assert(0);
}
