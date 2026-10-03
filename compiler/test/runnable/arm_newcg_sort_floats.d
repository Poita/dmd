// REQUIRED_ARGS: -O -inline -release -boundscheck=off
// std.algorithm's sort of floats, without bounds checks.

import std.algorithm.sorting : sort;

pragma(inline, false) float[] build(uint n, uint seed)
{
    auto a = new float[](n);
    foreach (ref x; a)
    {
        seed = seed * 1664525 + 1013904223;
        x = (seed >> 8) * (1.0f / (1 << 24)) - 0.5f;
    }
    return a;
}

void main()
{
    foreach (n; [1u, 2, 3, 7, 16, 31, 100, 1000, 5000])
    {
        auto a = build(n, n * 7 + 1);
        sort(a);
        foreach (i; 1 .. a.length)
            if (!(a[i - 1] <= a[i])) assert(0);
    }
}
