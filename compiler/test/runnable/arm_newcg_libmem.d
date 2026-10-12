/* REQUIRED_ARGS: -O
 */
// memset, memcpy and memmove of a few bytes known at compile time, done in
// place, for every size, offset and overlap

import core.stdc.string : memcpy, memmove, memset;

ubyte[80] a, b;

void fill()
{
    foreach (i, ref x; a) x = cast(ubyte)(i * 7 + 1);
    foreach (i, ref x; b) x = cast(ubyte)(i * 13 + 5);
}

void checkSet(size_t n)(int v, size_t off)
{
    fill();
    auto r = memset(&a[off], v, n);
    assert(r is &a[off]);
    foreach (i, x; a)
        assert(x == (i >= off && i < off + n ? cast(ubyte)v : cast(ubyte)(i * 7 + 1)));
}

void checkCopy(size_t n)(size_t off)
{
    fill();
    auto r = memcpy(&a[off], &b[3], n);
    assert(r is &a[off]);
    foreach (i, x; a)
        assert(x == (i >= off && i < off + n ? cast(ubyte)((i - off + 3) * 13 + 5) : cast(ubyte)(i * 7 + 1)));
}

void checkMove(size_t n)(size_t from, size_t to)
{
    fill();
    ubyte[80] want = a;
    foreach (i; 0 .. n)
        want[to + i] = a[from + i];
    auto r = memmove(&a[to], &a[from], n);
    assert(r is &a[to]);
    assert(a == want);
}

void main()
{
    static foreach (n; [0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64])
    {
        foreach (off; 0 .. 9)
        {
            checkSet!n(0, off);
            checkSet!n(0x1A5, off);     // only the low byte is stored
            checkCopy!n(off);
            foreach (d; 0 .. 9)
                checkMove!n(off, d + 3);
        }
    }
}
