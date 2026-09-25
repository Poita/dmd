// Right shift-assign of a narrow variable after a left shift-assign,
// the pattern std.bitmanip uses to sign-extend a bitfield.

pragma(inline, false)
short signExtend4(ubyte b)
{
    auto result = cast(short) (b >> 4U);
    result <<= 12U;
    result >>= 12U;
    return result;
}

pragma(inline, false)
byte signExtend4b(ubyte b)
{
    auto result = cast(byte) (b >> 4U);
    result <<= 4U;
    result >>= 4U;
    return result;
}

pragma(inline, false)
ushort zeroExtend4(ubyte b)
{
    auto result = cast(ushort) (b >> 4U);
    result <<= 12U;
    result >>>= 12U;
    return result;
}

pragma(inline, false)
ubyte zeroExtend4b(ubyte b)
{
    auto result = cast(ubyte) (b >> 4U);
    result <<= 4U;
    result >>>= 4U;
    return result;
}

void main()
{
    assert(signExtend4(0x80) == -8);
    assert(signExtend4(0x70) == 7);
    assert(signExtend4b(0x80) == -8);
    assert(signExtend4b(0x70) == 7);
    assert(zeroExtend4(0xF0) == 15);
    assert(zeroExtend4b(0xF0) == 15);
}
