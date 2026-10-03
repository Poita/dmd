// REQUIRED_ARGS: -O -release
// Float variables held in registers that are read and written as integers of the same size.

pragma(inline, false) float sfloor(float x)
{
    uint bits = *cast(uint*)&x;
    bits &= 0xFFFF_0000;
    return *cast(float*)&bits;
}

pragma(inline, false) double setSign(double d, ulong sign)
{
    *cast(ulong*)&d |= sign << 63;
    return d;
}

pragma(inline, false) float fromBits(uint u)
{
    float f;
    *cast(uint*)&f = u + 1;
    return f + 1;
}

void main()
{
    if (sfloor(1.2345f) != 1.234375f) assert(0);
    if (setSign(2.5, 1) != -2.5) assert(0);
    if (fromBits(0x3F7F_FFFF) != 2.0f) assert(0);
}
