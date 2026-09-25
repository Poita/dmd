// Taking the address of a global at an offset too large for an add
// immediate.

static immutable ulong[256][8] tables = () {
    ulong[256][8] t;
    foreach (i, ref row; t)
        foreach (j, ref x; row)
            x = i * 1000 + j;
    return t;
}();

__gshared ubyte[1 << 25] big;

ulong lookup(uint row, uint i)
{
    switch (row)
    {
        case 4: return tables[4][i];    // offset 8192
        case 7: return tables[7][i];    // offset 14336
        default: return tables[0][i];
    }
}

void main()
{
    assert(lookup(4, 3) == 4003);
    assert(lookup(7, 255) == 7255);
    assert(lookup(0, 1) == 1);

    big[(1 << 24) + 5] = 42;            // offset beyond 24 bits
    ubyte* p = &big[(1 << 24) + 5];
    assert(*p == 42);
    big[4097] = 7;
    assert(*(&big[4097]) == 7);
}
