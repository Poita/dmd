// REQUIRED_ARGS: -O -inline -release
// Slice variables held in two registers: read, assigned whole and in part, passed.

pragma(inline, false) int[] make(int n)
{
    auto a = new int[](n);
    foreach (i, ref x; a)
        x = cast(int)i;
    return a;
}

pragma(inline, false) long sumHalves(int n)
{
    int[] a = make(n);
    long s;
    int[] lo = a[0 .. $ / 2];
    int[] hi = a[$ / 2 .. $];
    foreach (x; lo)
        s += x;
    foreach (i; 0 .. hi.length)
        s += hi[i] * 2;
    hi = lo;
    s += hi.length;
    lo.length = 1;
    s += lo.length + lo[0];
    return s;
}

pragma(inline, false) size_t count(const(char)[] s, char c)
{
    size_t n;
    while (s.length)
    {
        if (s[0] == c)
            ++n;
        s = s[1 .. $];
    }
    return n;
}

void main()
{
    // 0+1+2+3 + 2*(4+5+6+7) + 4 + 1 + 0
    if (!(sumHalves(8) == 6 + 44 + 4 + 1)) assert(0);
    if (!(count("abracadabra", 'a') == 5)) assert(0);
}
