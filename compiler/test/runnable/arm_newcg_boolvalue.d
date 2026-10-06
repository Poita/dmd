/* REQUIRED_ARGS: -O
 */
// && and || of comparisons as values, nested, and with operands that must not be evaluated

struct P { int x; }

pragma(inline, false) bool inRange(int x, int lo, int hi) { return x >= lo && x <= hi; }
pragma(inline, false) bool either(long a, long b) { return a == 0 || b < -3; }
pragma(inline, false) bool nested(int a, int b, int c) { return (a < b || b < c) && c != 7; }
pragma(inline, false) bool guarded(const(P)* p) { return p !is null && p.x > 2; }
pragma(inline, false) int count(const int[] xs, int lo, int hi)
{
    int n;
    foreach (x; xs)
    {
        const ok = x >= lo && x < hi || x == 100;
        n += ok;
    }
    return n;
}

void main()
{
    foreach (x; -3 .. 9)
    {
        if (inRange(x, 0, 5) != (x >= 0 && x <= 5)) assert(0);
        foreach (y; -5 .. 3)
            if (either(x, y) != (x == 0 || y < -3)) assert(0);
        foreach (y; -2 .. 9)
            foreach (z; [6, 7, 8])
                if (nested(x, y, z) != ((x < y || y < z) && z != 7)) assert(0);
    }
    P p = P(3);
    if (!guarded(&p) || guarded(null)) assert(0);
    p.x = 2;
    if (guarded(&p)) assert(0);
    if (count([1, 5, 9, 100, 3, -1], 1, 6) != 4) assert(0);
}
