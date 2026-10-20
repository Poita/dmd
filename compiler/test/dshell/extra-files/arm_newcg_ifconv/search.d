// Choices of the next bounds of a search

size_t sel2_lowerBound(const(int)[] a, int key)
{
    size_t lo = 0, hi = a.length;
    while (lo < hi)
    {
        const mid = (lo + hi) / 2;
        if (a[mid] < key)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
}

int sel0_absDiff(int a, int b)
{
    int r;
    if (a > b)
        r = a - b;
    else
        r = b - a;
    return r;
}

void main()
{
    static immutable int[] a = [-5, -5, 0, 2, 2, 2, 9, int.max];
    foreach (key; [int.min, -5, -4, 0, 1, 2, 3, 9, 10, int.max])
    {
        size_t want = 0;
        while (want < a.length && a[want] < key)
            ++want;
        foreach (n; 0 .. a.length + 1)
        {
            size_t w = 0;
            while (w < n && a[w] < key)
                ++w;
            if (sel2_lowerBound(a[0 .. n], key) != w) assert(0);
        }
        if (sel2_lowerBound(a, key) != want) assert(0);
    }
    if (sel0_absDiff(3, 10) != 7 || sel0_absDiff(10, 3) != 7) assert(0);
    if (sel0_absDiff(int.min, 1) != int.min + 1) assert(0); // wraps around
}
