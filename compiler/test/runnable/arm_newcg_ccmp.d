/* REQUIRED_ARGS: -O
 */
// Chains of comparisons joined by || and &&, as values and as branches

pragma(inline, false) bool outside(int x, int y, int w, int h) { return x < 0 || y < 0 || x >= w || y >= h; }
pragma(inline, false) bool inside(int x, int y, int w, int h) { return x >= 0 && y >= 0 && x < w && y < h; }
pragma(inline, false) bool mixedImm(long a, long b) { return a == 3 || b > 100 || a < -5 || b == 31; }
pragma(inline, false) bool unsignedRange(uint a, uint lo, uint hi) { return a >= lo && a <= hi && a != 7; }
pragma(inline, false) int countIn(const int[] xs, int lo, int hi)
{
    int n;
    foreach (x; xs)
        if (x < lo || x > hi || x == 0)
            continue;
        else
            ++n;
    return n;
}
pragma(inline, false) bool both(int a, int b) { bool p = a > 1 || b > 1; bool q = a < 9 && b < 9; return p && q; }

// a test of values the same throughout the loop, made once before it
pragma(inline, false) int sumUnless(const int[] xs, int a, int b, int w, int h)
{
    int s;
    foreach (x; xs)
    {
        if (a < 0 || b < 0 || a >= w || b >= h)
            continue;
        s += x;
    }
    return s;
}

pragma(inline, false) int sumWhen(const int[] xs, long a, long b)
{
    int s;
    foreach (x; xs)
    {
        if (a > 2 && b != 5 && a < 1000)
            s += x;
    }
    return s;
}

bool refOutside(int x, int y, int w, int h) { if (x < 0) return true; if (y < 0) return true; if (x >= w) return true; return y >= h; }

void main()
{
    foreach (x; -2 .. 7)
        foreach (y; -2 .. 7)
        {
            if (outside(x, y, 4, 5) != refOutside(x, y, 4, 5)) assert(0);
            if (inside(x, y, 4, 5) == refOutside(x, y, 4, 5)) assert(0);
            const bo = (x > 1 || y > 1) && (x < 9 && y < 9);
            if (both(x, y) != bo) assert(0);
        }
    foreach (a; [-6L, -5, 3, 4, 31, 1L << 40])
        foreach (b; [0L, 31, 100, 101, -1])
            if (mixedImm(a, b) != (a == 3 || b > 100 || a < -5 || b == 31)) assert(0);
    foreach (a; [0u, 3, 7, 8, 10, 0xFFFF_FFFF])
        if (unsignedRange(a, 3, 10) != (a >= 3 && a <= 10 && a != 7)) assert(0);
    foreach (a; -1 .. 4)
        foreach (b; -1 .. 4)
            if (sumUnless([1, 2, 3], a, b, 3, 2) != (refOutside(a, b, 3, 2) ? 0 : 6)) assert(0);
    foreach (a; [0L, 3, 999, 1000])
        foreach (b; [5L, 6])
            if (sumWhen([1, 2, 3], a, b) != (a > 2 && b != 5 && a < 1000 ? 6 : 0)) assert(0);
    if (countIn([-3, 0, 1, 2, 5, 9, 0, 4], 1, 5) != 4) assert(0);
}
