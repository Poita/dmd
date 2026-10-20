// Sums and bitwise reductions done only in the iterations a condition holds are
// done in 4 lanes, each lane keeping its own value where the condition does not
// hold, and give what the scalar loop does, wrapping included.
module cond_reductions;

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

uint vecCountIf(const(int)[] a, int k)
{
    uint n;
    foreach (v; a)
        if (v == k)
            ++n;
    return n;
}

int vecSumIf(const(int)[] a)
{
    int s = 5;
    foreach (v; a)
        if (v > 0)
            s += v;
    return s;
}

int vecSubIf(const(int)[] a, const(int)[] b)
{
    int s;
    foreach (i, v; a)
        if (v < b[i])
            s -= v * 3;
    return s;
}

uint vecOrIf(const(uint)[] a)
{
    uint r = 0x10;
    foreach (v; a)
        if (v & 4)
            r |= v;
    return r;
}

uint vecXorIf(const(uint)[] a, uint t)
{
    uint r = 9;
    foreach (v; a)
        if (v >= t)
            r ^= v;
    return r;
}

uint vecAndIf(const(uint)[] a)
{
    uint r = uint.max;
    foreach (v; a)
        if (v > 1000)
            r &= v;
    return r;
}

// the condition reads the sum, so each iteration depends on all before it
int novecSumBelow(const(int)[] a)
{
    int s;
    foreach (v; a)
        if (s < 1000)
            s += v;
    return s;
}

int main()
{
    foreach (n; 0 .. 66)
    {
        auto a = new int[](n), b = new int[](n);
        foreach (i; 0 .. n)
        {
            a[i] = id(cast(int)(i * 2654435761u)) >> (i % 7);
            b[i] = id(cast(int)(i * 977 - 9000));
            if (i % 3 == 0)
                a[i] = 42;
        }
        auto u = cast(uint[])a;
        uint c;
        foreach (v; a) if (v == 42) c = id(c + 1);
        check(vecCountIf(a, 42) == c);
        int s = 5;
        foreach (v; a) if (v > 0) s = id(s + v);
        check(vecSumIf(a) == s);
        s = 0;
        foreach (i; 0 .. n) if (a[i] < b[i]) s = id(s - a[i] * 3);
        check(vecSubIf(a, b) == s);
        uint r = 0x10;
        foreach (v; u) if (v & 4) r = id(r | v);
        check(vecOrIf(u) == r);
        r = 9;
        foreach (v; u) if (v >= 0x8000_0000) r = id(r ^ v);
        check(vecXorIf(u, 0x8000_0000) == r);
        r = uint.max;
        foreach (v; u) if (v > 1000) r = id(r & v);
        check(vecAndIf(u) == r);
        s = 0;
        foreach (v; a) if (s < 1000) s = id(s + v);
        check(novecSumBelow(a) == s);
    }
    return 0;
}
