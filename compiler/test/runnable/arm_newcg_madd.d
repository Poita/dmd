/* REQUIRED_ARGS: -O
 */
// Products added to or taken from other values, at 32 and 64 bits

pragma(inline, false) int at2d(const int[] a, uint w, uint x, uint y) { return a[y * w + x]; }
pragma(inline, false) long mulAdd64(long a, long b, long c) { return c + a * b; }
pragma(inline, false) int mulAdd32(int a, int b, int c) { return a * b + c; }
pragma(inline, false) int mulSub32(int a, int b, int c) { return c - a * b; }
pragma(inline, false) uint wraps(uint a, uint b, uint c) { return a * b + c; }
pragma(inline, false) long twice(long a, long b) { const p = a * b; return p + p * 3; }

void main()
{
    int[20] g;
    foreach (i, ref v; g)
        v = cast(int)(i * 3 + 1);
    if (at2d(g[], 5, 2, 3) != g[17]) assert(0);
    if (mulAdd64(-7, 1L << 40, 5) != 5 - (7L << 40)) assert(0);
    if (mulAdd32(-6, 7, 100) != 58) assert(0);
    if (mulSub32(6, 7, 100) != 58) assert(0);
    if (wraps(0x10000, 0x10001, 3) != 0x10003) assert(0);
    if (twice(5, -3) != -60) assert(0);
}
