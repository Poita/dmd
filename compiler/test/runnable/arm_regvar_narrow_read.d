// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* A register variable read at a narrower size, as when the low bits of a
 * wider variable are tested, keeps its full value for later reads.
 */

uint lowByte(const(uint)[] a)
{
    uint r;
    foreach (x; a)
    {
        uint node = x * 2 + 0x100;
        if ((cast(ubyte) node & 1) == 0)
            r += node >> 1;
        else
            r += node;
    }
    return r;
}

uint lowShort(const(uint)[] a)
{
    uint r;
    foreach (x; a)
    {
        uint node = x * 2 + 0x10000;
        if ((cast(ushort) node & 1) == 0)
            r += node >> 1;
        else
            r += node;
    }
    return r;
}

ulong lowWord(const(ulong)[] a)
{
    ulong r;
    foreach (x; a)
    {
        ulong node = x * 2 + 0x1_0000_0000;
        if ((cast(uint) node & 1) == 0)
            r += node >> 1;
        else
            r += node;
    }
    return r;
}

int lowSignedByte(const(int)[] a)
{
    int r;
    foreach (x; a)
    {
        int node = x * 2 + 0x100;
        if ((cast(byte) node & 1) == 0)
            r += node >> 1;
        else
            r += node;
    }
    return r;
}

int main()
{
    uint[] a = [1, 2, 3];
    assert(lowByte(a) == 0x81 + 0x82 + 0x83);
    assert(lowShort(a) == 0x8001 + 0x8002 + 0x8003);
    ulong[] b = [1, 2, 3];
    assert(lowWord(b) == 0x8000_0001UL + 0x8000_0002UL + 0x8000_0003UL);
    int[] c = [1, 2, 3];
    assert(lowSignedByte(c) == 0x81 + 0x82 + 0x83);
    return 0;
}
