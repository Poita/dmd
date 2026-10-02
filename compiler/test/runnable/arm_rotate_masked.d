// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline

/* Rotates written with a masked negated count, as in PCG32
 */

pragma(inline, false) uint rotr(uint x, uint r) { return (x >> r) | (x << ((-int(r)) & 31)); }
pragma(inline, false) uint rotl(uint x, uint r) { return (x << r) | (x >> (-r & 31)); }
pragma(inline, false) ulong rotr64(ulong x, uint r) { return (x >> r) | (x << (-r & 63)); }

uint refRotr(uint x, uint r) { r &= 31; return r ? (x >> r) | (x << (32 - r)) : x; }

pragma(inline, false) uint pcg(ref ulong state)
{
    const old = state;
    state = old * 6364136223846793005UL + 1442695040888963407UL;
    const xorshifted = cast(uint)(((old >> 18) ^ old) >> 27);
    const rot = cast(uint)(old >> 59);
    return (xorshifted >> rot) | (xorshifted << ((-int(rot)) & 31));
}

void main()
{
    foreach (r; 0 .. 32)
    {
        assert(rotr(0x12345678, r) == refRotr(0x12345678, r));
        assert(rotl(0x12345678, r) == refRotr(0x12345678, (32 - r) & 31));
    }
    assert(rotr64(0x0123456789ABCDEF, 4) == 0xF0123456789ABCDE);
    assert(rotr64(0x0123456789ABCDEF, 0) == 0x0123456789ABCDEF);
    ulong st = 42;
    uint h;
    foreach (i; 0 .. 100)
        h = h * 31 + pcg(st);
    assert(h == 0x5FA6_E280);
}
