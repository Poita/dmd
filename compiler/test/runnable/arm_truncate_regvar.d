// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline

/* Values narrowed from wider ones, assigned to register variables
 */

pragma(inline, false) uint mix(ulong x, int n)
{
    uint a, b;
    ushort c;
    ubyte d;
    foreach (i; 0 .. n)
    {
        a = cast(uint)(x >> 7);
        b = cast(uint)(x >> 40) ^ a;
        c = cast(ushort)(a + b);
        d = cast(ubyte)(c >> 3);
        x = x * 6364136223846793005UL + (a ^ c ^ d);
    }
    return a + b + c + d;
}

uint refMix(ulong x, int n)
{
    ulong a, b, c, d;
    foreach (i; 0 .. n)
    {
        a = (x >> 7) & 0xFFFF_FFFF;
        b = ((x >> 40) ^ a) & 0xFFFF_FFFF;
        c = (a + b) & 0xFFFF;
        d = (c >> 3) & 0xFF;
        x = x * 6364136223846793005UL + (a ^ c ^ d);
    }
    return cast(uint)(a + b + c + d);
}

void main()
{
    foreach (n; 0 .. 6)
        foreach (ulong x; [0UL, 1, 0xFFFF_FFFF_FFFF_FFFF, 0x0123_4567_89AB_CDEF])
            assert(mix(x, n) == refMix(x, n));
}
