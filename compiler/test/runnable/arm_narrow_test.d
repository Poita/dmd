// PERMUTE_ARGS: -O -inline

// Testing a value narrower than its register, whose register holds other bits above it

pragma(inline, false) int narrow(int a, int b, int k)
{
    int n;
    foreach (i; 0 .. k)
    {
        ubyte x = cast(ubyte)(a + b + i);
        ushort y = cast(ushort)(a * b + i);
        byte z = cast(byte)(a - i);
        if (x) n += 1;
        if (!x) n += 10;
        if (y) n += 100;
        if (!y) n += 1000;
        if (z < 0) n += 10_000;
        if (z >= 0) n += 100_000;
    }
    return n;
}

int narrowRef(int a, int b, int k)
{
    int n;
    foreach (i; 0 .. k)
    {
        n += ((a + b + i) & 0xFF) ? 1 : 10;
        n += ((a * b + i) & 0xFFFF) ? 100 : 1000;
        n += ((a - i) & 0x80) ? 10_000 : 100_000;
    }
    return n;
}

void main()
{
    // a + b + i reaches 256, a * b + i reaches 65536, a - i crosses 128
    assert(narrow(255, 0, 3) == narrowRef(255, 0, 3));
    assert(narrow(65535, 1, 3) == narrowRef(65535, 1, 3));
    assert(narrow(129, 300, 70) == narrowRef(129, 300, 70));
}
