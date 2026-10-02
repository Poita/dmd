// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline

/* Loops whose if-else arms each go on to the loop's test, which each arm
 * then tests itself.
 */

pragma(inline, false) size_t lowerBound(const(ulong)[] entries, ulong key)
{
    size_t lo = 0;
    size_t hi = entries.length;
    while (lo < hi)
    {
        const mid = (lo + hi) / 2;
        if (entries[mid] < key)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
}

pragma(inline, false) int collatz(int n)
{
    int steps;
    while (n != 1)
    {
        if (n & 1)
            n = 3 * n + 1;
        else
            n /= 2;
        ++steps;
    }
    return steps;
}

pragma(inline, false) int skipping(const(int)[] a)
{
    int r;
    size_t i;
    while (i < a.length)
    {
        if (a[i] < 0)
        {
            i += 2;
            continue;
        }
        r += a[i];
        ++i;
    }
    return r;
}

void main()
{
    ulong[] e = [1, 3, 3, 5, 8, 13, 21];
    foreach (k, want; [0, 0, 1, 1, 3, 3, 4, 4, 4, 5])
        assert(lowerBound(e, k) == want);
    assert(lowerBound(e, 22) == 7);
    assert(lowerBound([], 5) == 0);
    assert(collatz(1) == 0 && collatz(6) == 8 && collatz(27) == 111);
    assert(skipping([1, -1, 100, 2, -5, 7, 3]) == 1 + 2 + 3);
}
