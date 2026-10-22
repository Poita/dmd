/* PERMUTE_ARGS: -O -inline
 */
// The test of a loop counter is not moved onto a value derived from it, as
// c * i + d, when d is not known: that value can wrap around within the loop,
// where the comparison of the counter does not.

__gshared long[64] garr;

pragma(inline, false) ulong f(int p)
{
    ulong v = 0;
    for (int w = 0; w < 3; ++w)
    {
        if ((garr[garr[38] & 63] & 7) == 5)
            break;
        v += cast(ulong)((p + (w + 20469)) << 29);
    }
    return v;
}

pragma(inline, false) ulong g(long p)
{
    ulong v = 0;
    for (long w = 0; w < 3; ++w)
    {
        if ((garr[garr[38] & 63] & 7) == 5)
            break;
        v += cast(ulong)((p + w) << 61);
    }
    return v;
}

pragma(inline, false) int h(int p)
{
    int n;
    for (int w = 0; w < 4; ++w)
    {
        if (garr[w] == 5)
            break;
        n += (w + p) * 1000;
    }
    return n;
}

void main()
{
    assert(f(64) == 0xFFFF_FFFF_4000_0000);
    assert(g(1) == 0xC000_0000_0000_0000);
    assert(h(int.max - 1) == cast(int)(4 * (int.max - 1) + 6) * 1000);
}
