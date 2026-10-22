/* PERMUTE_ARGS: -O -inline
 */
// A value used again after a narrowing and zero or sign extension of it keeps
// its bits: the extension works on a copy when the value is a common
// subexpression.

pragma(inline, false) long u8(double p, ushort q)
{
    q |= cast(ubyte)(cast(long)(p * 64));
    return cast(long)(p * 64) + q;
}

pragma(inline, false) long s8(double p, short q)
{
    q |= cast(byte)(cast(long)(p * 64));
    return cast(long)(p * 64) + q;
}

pragma(inline, false) long u16(double p, uint q)
{
    q |= cast(ushort)(cast(long)(p * 64));
    return cast(long)(p * 64) + q;
}

pragma(inline, false) long s16(double p, int q)
{
    q |= cast(short)(cast(long)(p * 64));
    return cast(long)(p * 64) + q;
}

pragma(inline, false) long u32(double p, ulong q)
{
    q |= cast(uint)(cast(long)(p * 64));
    return cast(long)(p * 64) + q;
}

pragma(inline, false) long s32(double p, long q)
{
    q |= cast(int)(cast(long)(p * 64));
    return cast(long)(p * 64) + q;
}

void main()
{
    // p * 64 == -1084160 == -0x108B00
    assert(u8(-16940.0, 0) == -1084160);
    assert(s8(-16940.0, 0) == -1084160);
    assert(u16(-16940.0, 0) == -1084160 + 0x7500);
    assert(s16(-16940.0, 0) == -1084160 + 0x7500);
    assert(u32(-16940.0, 0) == -1084160 + 0xFFEF_7500);
    assert(s32(-16940.0, 0) == -1084160 - 1084160);
    assert(u8(1.5, 1) == 96 + 97);
}
