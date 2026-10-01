// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Integers assembled from consecutive bytes in little endian order, at
 * unaligned addresses, and look-alikes that are not.
 */

pragma(inline, false) ulong readU64(const(ubyte)* p)
{
    ulong v;
    foreach (i; 0 .. 8)
        v |= cast(ulong) p[i] << (8 * i);
    return v;
}

pragma(inline, false) uint readU32(const(ubyte)* p)
{
    uint v;
    foreach (i; 0 .. 4)
        v |= cast(uint) p[i] << (8 * i);
    return v;
}

pragma(inline, false) uint expr32(const(ubyte)* p)
{
    return p[1] | p[2] << 8 | p[3] << 16 | p[4] << 24;
}

pragma(inline, false) uint bigEndian32(const(ubyte)* p)
{
    return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
}

pragma(inline, false) uint gap32(const(ubyte)* p)
{
    return p[0] | p[1] << 8 | p[3] << 16 | p[4] << 24;
}

pragma(inline, false) ulong selfRead()
{
    // v is read through p while it is assembled
    ulong v = 0x0807060504030201;
    ubyte* p = cast(ubyte*)&v;
    ulong w;
    w = p[0];
    w |= cast(ulong) p[1] << 8;
    v = 0;
    w |= cast(ulong) p[2] << 16;
    w |= cast(ulong) p[3] << 24;
    return w;
}

void main()
{
    ubyte[16] b;
    foreach (i, ref x; b)
        x = cast(ubyte)(0x10 + i);
    assert(readU64(&b[1]) == 0x1817161514131211);
    assert(readU64(&b[0]) == 0x1716151413121110);
    assert(readU32(&b[3]) == 0x16151413);
    assert(expr32(&b[0]) == 0x14131211);
    assert(bigEndian32(&b[0]) == 0x10111213);
    assert(gap32(&b[0]) == 0x14131110);
    assert(selfRead() == 0x0000_0201);
}
