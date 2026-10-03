// REQUIRED_ARGS: -O -inline -release
// Rotates by constant and variable amounts, 32 and 64 bits.

import core.bitop : rol, ror;

pragma(inline, false) uint mix32(uint x, uint n)
{
    return ror(x, 7) ^ rol(x, 13) ^ ror(x, n) ^ rol(x, n + 3);
}

pragma(inline, false) ulong mix64(ulong x, uint n)
{
    return rol(x, 31) + ror(x, 17) + rol(x, n) + ror(x, n * 2);
}

void main()
{
    if (!(mix32(0x12345678, 5) == 0x8e2cb04b)) assert(0);
    if (!(mix64(0x0123456789abcdef, 9) == 0xe5d3f6e54c3b27f4)) assert(0);
}
