// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Widening 32 bit multiplies, adds and subtracts of shifted and extended
 * operands, and floating point compares with zero.
 */

pragma(inline, false) ulong umul(uint a, uint b) { return ulong(a) * b; }
pragma(inline, false) long smul(int a, int b) { return long(a) * b; }
pragma(inline, false) ulong umulc(uint a) { return ulong(a) * 4_000_000_000u; }
pragma(inline, false) long smulc(int a) { return long(a) * -7; }
pragma(inline, false) size_t addShl(size_t b, uint i) { return b + (size_t(i) << 3); }
pragma(inline, false) long addShlS(long b, int i) { return b + (long(i) << 2); }
pragma(inline, false) size_t subShl(size_t b, size_t i) { return b - (i << 4); }
pragma(inline, false) size_t shlAdd(size_t b, size_t i) { return (i << 1) + b; }
pragma(inline, false) uint addShl32(uint b, uint i) { return b + (i << 3); }
pragma(inline, false) int cmpZero(float f, double d)
{
    int r;
    if (f < 0) r |= 1;
    if (f > 0) r |= 2;
    if (f == 0) r |= 4;
    if (d <= 0) r |= 8;
    if (d >= 0) r |= 16;
    if (d != 0) r |= 32;
    return r;
}

int main()
{
    assert(umul(0xFFFF_FFFF, 0xFFFF_FFFF) == 0xFFFF_FFFE_0000_0001);
    assert(smul(-3, 0x7FFF_FFFF) == -3L * 0x7FFF_FFFF);
    assert(smul(int.min, int.min) == 0x4000_0000_0000_0000);
    assert(umulc(3) == 12_000_000_000);
    assert(smulc(-5) == 35);
    assert(addShl(100, 0xFFFF_FFFF) == 100 + 0x7_FFFF_FFF8);
    assert(addShlS(100, -1) == 96);
    assert(subShl(1000, 3) == 952);
    assert(shlAdd(5, 7) == 19);
    assert(addShl32(1, 0x2000_0001) == 9);
    assert(cmpZero(-1, -1) == 1 + 8 + 32);
    assert(cmpZero(2, 3) == 2 + 16 + 32);
    assert(cmpZero(0, 0) == 4 + 8 + 16);
    assert(cmpZero(-0.0f, -0.0) == 4 + 8 + 16);
    assert(cmpZero(float.nan, double.nan) == 32);
    return 0;
}
