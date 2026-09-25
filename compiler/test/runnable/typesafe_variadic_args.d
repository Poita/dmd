// Arguments after a typesafe variadic parameter's slice are passed in registers
// like any other argument.

size_t sum(size_t n, size_t[] a...)
{
    size_t s = n;
    foreach (x; a)
        s += x;
    return s;
}

void testBits(size_t numBits, size_t[] bitsToTest...)
{
    import core.bitop : BitRange, bts;
    import core.stdc.stdlib : free, malloc;
    import core.stdc.string : memset;
    immutable numBytes = (numBits + size_t.sizeof * 8 - 1) / 8;
    size_t* bitArr = cast(size_t*) malloc(numBytes);
    scope(exit) free(bitArr);
    memset(bitArr, 0, numBytes);
    foreach (b; bitsToTest)
        bts(bitArr, b);
    auto br = BitRange(bitArr, numBits);
    foreach (b; bitsToTest)
    {
        assert(!br.empty);
        assert(b == br.front);
        br.popFront();
    }
    assert(br.empty);
}

void main()
{
    testBits(100, 0, 1, 31, 63, 85);
    size_t inner(size_t n, size_t[] a...) { return n + a.length + a[$ - 1]; }
    assert(sum(100, 1, 2, 3) == 106);
    assert(inner(100, 0, 1, 31) == 134);
}
