// Rotates of values narrower than 32 bits.

import core.bitop : rol, ror;

T id(T)(T x) { return x; }

void main()
{
    ubyte a = id!ubyte(0b11110000);
    assert(rol(a, 1) == 0b11100001);
    assert(ror(a, 1) == 0b01111000);
    assert(rol!3(a) == 0b10000111);
    assert(ror!3(a) == 0b00011110);
    ushort s = id!ushort(0x8001);
    assert(rol(s, 1) == 0x0003);
    assert(ror(s, 1) == 0xC000);
    uint u = id(0x8000_0001u);
    assert(rol(u, 1) == 3 && ror(u, 1) == 0xC000_0000);
    ulong l = id(0x8000_0000_0000_0001UL);
    assert(rol(l, 1) == 3 && ror(l, 4) == 0x1800_0000_0000_0000);
}
