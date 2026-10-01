// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// Assignments made under a condition, selected without a branch

pragma(inline, false) float maxOf(const(float)[] a, float e)
{
    float m = -float.max;
    foreach (x; a)
    {
        const d = (x - e) * 0.5f;
        if (d > m) m = d;
    }
    return m;
}

pragma(inline, false) long minOf(const(long)[] a)
{
    long m = long.max;
    foreach (x; a)
        if (x < m) m = x;
    return m;
}

pragma(inline, false) int clampCount(const(int)[] a, int lo)
{
    int n;
    foreach (x; a)
    {
        int v = x;
        if (v < lo) v = lo;         // assigned when the condition holds
        else n += 1;
        n += v;
    }
    return n;
}

pragma(inline, false) uint elseAssign(const(uint)[] a)
{
    uint s = 1;
    foreach (x; a)
    {
        if (x & 1) {} else s = x * 3;   // assigned when it does not
    }
    return s;
}

pragma(inline, false) int selfRef(const(int)[] a)
{
    int c;
    foreach (x; a)
        if (x > 2) c = c + x;       // the value reads the variable
    return c;
}

int calls;
pragma(inline, false) bool tick(int x) { ++calls; return x > 1; }

pragma(inline, false) int withCall(const(int)[] a)
{
    int r;
    foreach (x; a)
        if (tick(x)) r = x;         // the condition has side effects
    return r;
}

pragma(inline, false) double nanMax(const(double)[] a)
{
    double m = 0;
    foreach (x; a)
        if (x > m) m = x;           // a NaN is never greater
    return m;
}

pragma(inline, false) const(int)* ptrSel(const(int)[] a, const(int)* p)
{
    foreach (ref x; a)
        if (x == 7) p = &x;
    return p;
}

pragma(inline, false) size_t lowerBound(const(ulong)[] entries, ulong key)
{
    size_t lo = 0, hi = entries.length;
    while (lo < hi)
    {
        const mid = (lo + hi) / 2;
        if (entries[mid] < key) lo = mid + 1; else hi = mid;
    }
    return lo;
}

void main()
{
    assert(maxOf([1, 5, 3], 1) == 2);
    assert(maxOf([], 1) == -float.max);
    assert(minOf([5, -3, 9, -3, 2]) == -3);
    assert(clampCount([1, 5, 3], 3) == (3 + 0) + (5 + 1) + (3 + 1));
    assert(elseAssign([1, 4, 7, 6, 9]) == 18);
    assert(selfRef([1, 3, 2, 5]) == 8);
    assert(withCall([1, 2, 0, 3, 1]) == 3 && calls == 5);
    assert(nanMax([1.5, double.nan, 0.5, 2.5, double.nan]) == 2.5);
    int[4] arr = [1, 7, 3, 7];
    int z;
    assert(ptrSel(arr[], &z) is &arr[3]);
    assert(ptrSel(arr[0 .. 1], &z) is &z);
    ulong[5] e = [1, 3, 5, 7, 9];
    assert(lowerBound(e, 6) == 3 && lowerBound(e, 0) == 0 && lowerBound(e, 10) == 5 && lowerBound(e, 5) == 2);
}
