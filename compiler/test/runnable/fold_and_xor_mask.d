/* REQUIRED_ARGS: -O
 */
// ((a & b) ^ c) & d keeps the bits of c that b clears, so the inner mask is
// dropped only where d has no bits outside b

pragma(inline, false) long f(long a, long c)
{
    return ((a & -27) ^ c) & 63;
}

pragma(inline, false) long g(long a, long c)
{
    return ((a & 0xF0) ^ c) & 0x30;
}

pragma(inline, false) uint h(uint a, uint c)
{
    return ((a & 0x0F) ^ c) & 0xFF;
}

pragma(inline, false) ubyte k(ubyte a, ubyte c)
{
    return cast(ubyte)(((a & 0x81) ^ c) & 0x83);
}

void main()
{
    assert(f(299, 306) == 19);
    assert(g(0xFF, 0x3C) == 0x00);
    assert(g(0x5A, 0x0F) == 0x10);
    assert(h(0xFF, 0x1234) == 0x3B);
    assert(k(0xFF, 0x02) == 0x83);
}
