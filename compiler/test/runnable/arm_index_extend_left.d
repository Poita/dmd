// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Byte sized loads and stores indexed by a 32 bit integer, where the extended
 * index is the left operand of the address addition.
 */

pragma(inline, false) bool all(const(bool)[] g, int n)
{
    bool ok = true;
    foreach (i; 0 .. n)
        ok &= g[i];
    return ok;
}

pragma(inline, false) int sumBack(const(byte)* p, int n)
{
    int r;
    for (int i = -1; i >= -n; --i)
        r += p[i];
    return r;
}

pragma(inline, false) uint sumUnsigned(const(ubyte)* p, uint lo, uint hi)
{
    uint r;
    for (uint i = lo; i < hi; ++i)
        r += p[i];
    return r;
}

pragma(inline, false) void fillBack(byte* p, int n, byte v)
{
    for (int i = -1; i >= -n; --i)
        p[i] = v;
}

void main()
{
    bool[5] a = [true, true, false, true, true];
    assert(all(a[], 2) && !all(a[], 5));

    byte[6] b = [1, -2, 3, -4, 5, -6];
    assert(sumBack(&b[5], 4) == 5 - 4 + 3 - 2);
    assert(sumBack(b.ptr + 6, 6) == -3);

    ubyte[5] u = [10, 20, 30, 40, 250];
    assert(sumUnsigned(u.ptr, 1, 5) == 340);

    fillBack(&b[4], 3, 9);
    assert(b == [1, 9, 9, 9, 5, -6]);
}
