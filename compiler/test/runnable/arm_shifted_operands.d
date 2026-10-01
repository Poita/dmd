// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// Operands shifted by a constant, shifted by the instruction using them

pragma(inline, false) ulong readU64(const(ubyte)* p)
{
    ulong v;
    foreach (i; 0 .. 8)
        v |= cast(ulong) p[i] << (8 * i);
    return v;
}

pragma(inline, false) uint mix32(uint a, uint b, int c)
{
    return (a ^ (b >> 3)) + (b << 7) - (a >> 2) + (c >> 5) & (a << 1) | (b >> 31);
}

pragma(inline, false) long mix64(ulong a, ulong b, long c)
{
    return ((a ^ (b >> 33)) + (b << 17) - (a >> 2) + (c >> 63)) & (a << 1) | (b >> 40);
}

pragma(inline, false) ulong opAssign(ulong h, ulong k, ref ulong m)
{
    h ^= h >> 32;
    h += k << 3;
    h -= k >> 7;
    h &= ~(k << 60);
    m |= h << 4;
    m ^= cast(long) h >> 9;
    return h;
}

pragma(inline, false) int flags(uint a, uint b)
{
    int n;
    if (a & (b << 2)) n += 1;
    if ((a & (b >> 1)) == 0) n += 2;
    return n;
}

void main()
{
    ubyte[8] bytes = [1, 2, 3, 4, 5, 6, 7, 0x88];
    assert(readU64(bytes.ptr) == 0x8807060504030201);

    uint a = 0x12345678, b = 0x9abcdef0;
    int c = -12345;
    assert(mix32(a, b, c) == ((a ^ (b >> 3)) + (b << 7) - (a >> 2) + (c >> 5) & (a << 1) | (b >> 31)));

    ulong la = 0x123456789abcdef0, lb = 0xfedcba9876543210;
    long lc = -1234567890123;
    assert(mix64(la, lb, lc) == (((la ^ (lb >> 33)) + (lb << 17) - (la >> 2) + (lc >> 63)) & (la << 1) | (lb >> 40)));

    ulong h = 0x0123456789abcdef, k = 0x1111, m = 3, m2 = 3;
    ulong h2 = h;
    h2 ^= h2 >> 32;
    h2 += k << 3;
    h2 -= k >> 7;
    h2 &= ~(k << 60);
    m2 |= h2 << 4;
    m2 ^= cast(long) h2 >> 9;
    assert(opAssign(h, k, m) == h2 && m == m2);

    assert(flags(4, 1) == 1 + 2);
    assert(flags(1, 2) == 0);
}
