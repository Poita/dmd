// Integer sums, minimums, maximums and bitwise reductions over a loop are done in
// 4 lanes and combined after it, starting from the value before the loop, and
// give what the scalar loop does, wrapping included.
module reductions;

// asserts are compiled out by -release
void check(bool ok, int line = __LINE__)
{
    import core.stdc.stdio : printf;
    import core.stdc.stdlib : abort;
    if (!ok)
    {
        printf("check failed at line %d\n", line);
        abort();
    }
}

pragma(inline, false) int id(int x) { return x; }

int vecSum(const(int)[] a, int s)
{
    foreach (v; a)
        s += v;
    return s;
}

uint vecSumSquares(const(uint)[] a)
{
    uint s = 7;
    foreach (i; 0 .. a.length)
        s += a[i] * a[i];
    return s;
}

int vecSubtract(const(int)[] a)
{
    int s = 1000;
    foreach (v; a)
        s -= v;
    return s;
}

int vecMax(const(int)[] a)
{
    int m = int.min;
    foreach (v; a)
        m = v > m ? v : m;
    return m;
}

int vecMinStart(const(int)[] a, int m)
{
    foreach (v; a)
        m = m < v ? m : v;
    return m;
}

uint vecUMin(const(uint)[] a)
{
    uint m = uint.max;
    foreach (v; a)
        m = v <= m ? v : m;
    return m;
}

uint vecUMaxGe(const(uint)[] a)
{
    uint m = 3;
    foreach (v; a)
        if (v >= m)
            m = v;
    return m;
}

int vecCount(const(int)[] a, int k)
{
    int n;
    foreach (v; a)
        n += v > k;
    return n;
}

uint vecOr(const(uint)[] a)
{
    uint r = 0x100;
    foreach (v; a)
        r |= v;
    return r;
}

uint vecXor(const(uint)[] a)
{
    uint r = 5;
    foreach (v; a)
        r ^= v * 3;
    return r;
}

uint vecAnd(const(uint)[] a)
{
    uint r = uint.max;
    foreach (v; a)
        r &= v | 1;
    return r;
}

int vecTwo(const(int)[] a, const(int)[] b)
{
    int s, m = int.max;
    foreach (i; 0 .. a.length)
    {
        s += a[i] * b[i];
        m = a[i] < m ? a[i] : m;
    }
    return s ^ m;
}

int novecPrefix(int[] c, const(int)[] a)
{
    int s;
    foreach (i; 0 .. a.length)
    {
        s += a[i];
        c[i] = s;
    }
    return s;
}

int main()
{
    foreach (n; 0 .. 41)
    {
        auto a = new int[](n), b = new int[](n), c = new int[](n);
        foreach (i; 0 .. n)
        {
            a[i] = id(cast(int)(i * 2654435761u)) >> (i % 5);
            b[i] = id(cast(int)(i * 7 - 50));
        }
        auto u = cast(uint[])a;
        int s = 99;
        foreach (v; a) s = id(s + v);
        check(vecSum(a, 99) == s);
        uint us = 7;
        foreach (v; u) us = id(us + v * v);
        check(vecSumSquares(u) == us);
        s = 1000;
        foreach (v; a) s = id(s - v);
        check(vecSubtract(a) == s);
        int m = int.min;
        foreach (v; a) m = id(v > m ? v : m);
        check(vecMax(a) == m);
        m = 12;
        foreach (v; a) m = id(m < v ? m : v);
        check(vecMinStart(a, 12) == m);
        uint um = uint.max;
        foreach (v; u) um = id(v <= um ? v : um);
        check(vecUMin(u) == um);
        um = 3;
        foreach (v; u) um = id(v >= um ? v : um);
        check(vecUMaxGe(u) == um);
        int k = 0;
        foreach (v; a) k = id(k + (v > 100));
        check(vecCount(a, 100) == k);
        um = 0x100;
        foreach (v; u) um = id(um | v);
        check(vecOr(u) == um);
        um = 5;
        foreach (v; u) um = id(um ^ (v * 3));
        check(vecXor(u) == um);
        um = uint.max;
        foreach (v; u) um = id(um & (v | 1));
        check(vecAnd(u) == um);
        s = 0; m = int.max;
        foreach (i; 0 .. n) { s = id(s + a[i] * b[i]); m = id(a[i] < m ? a[i] : m); }
        check(vecTwo(a, b) == (s ^ m));
        s = 0;
        check(novecPrefix(c, a) == vecSum(a, 0));
        foreach (i; 0 .. n) { s = id(s + a[i]); check(c[i] == s); }
    }
    return 0;
}
