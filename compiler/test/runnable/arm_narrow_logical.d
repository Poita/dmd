// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// Logical operations on values narrower than 32 bits, with constants and op=

pragma(inline, false) bool all(const(bool)[] g)
{
    bool ok = true;
    foreach (x; g)
        ok &= x;
    return ok;
}

pragma(inline, false) bool any(const(bool)[] g)
{
    bool r;
    foreach (x; g)
        r |= x;
    return r;
}

pragma(inline, false) ubyte mixBytes(const(ubyte)[] g)
{
    ubyte r = 0x5A;
    foreach (x; g)
    {
        r |= x & 3;
        r ^= x & 0xF0;
        r &= cast(ubyte)(x | 0xFE);     // a mask with the high bits set
        r += x;                          // wraps at 8 bits
        r -= 7;
    }
    return r;
}

pragma(inline, false) short mixShorts(const(short)[] g)
{
    short r = -3;
    foreach (x; g)
    {
        r ^= x & 0x7FFF;
        r |= x & -16;                    // sign extended constant
        r &= cast(short)0xFF0F;
        r += x;
    }
    return r;
}

void main()
{
    bool[5] a = [true, true, false, true, true];
    assert(!all(a) && all(a[0 .. 2]) && any(a) && !any(a[2 .. 3]));

    ubyte[4] b = [4, 0x9F, 0xFF, 1];
    ubyte r = 0x5A;
    foreach (x; b)
    {
        r |= x & 3;
        r ^= x & 0xF0;
        r &= cast(ubyte)(x | 0xFE);
        r += x;
        r -= 7;
    }
    assert(mixBytes(b) == r);

    short[3] s = [0x1234, -2, short.min];
    short q = -3;
    foreach (x; s)
    {
        q ^= x & 0x7FFF;
        q |= x & -16;
        q &= cast(short)0xFF0F;
        q += x;
    }
    assert(mixShorts(s) == q);
}
