// Shifting a variable right by half its size, which on 64 bit targets stays a
// shift so the variable can be in a register.

ulong mix(ulong h)
{
    h ^= h >> 32;
    h *= 0xD6E8FEB86659FD93UL;
    h ^= h >> 32;
    return h;
}

uint high16(uint x)
{
    return x >> 16;
}

long ashr32(long x)
{
    return x >> 32;
}

void main()
{
    ulong h = 0x0123_4567_89AB_CDEF;
    h ^= h >> 32;
    assert(h == 0x0123_4567_8888_8888);
    assert(high16(0xABCD_1234) == 0xABCD);
    assert(ashr32(-0x1_0000_0000L) == -1);
    assert(ashr32(0x7_0000_0001L) == 7);
}
