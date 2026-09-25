// core.bitop.bt tests one bit of a bit array.

import core.bitop : bt;

bool test(const(size_t)* p, size_t i) { return bt(p, i) != 0; }

void main()
{
    size_t[3] a = [0b1001, 0, 1UL << 63];
    assert(test(a.ptr, 0));
    assert(!test(a.ptr, 1));
    assert(test(a.ptr, 3));
    assert(!test(a.ptr, 64));
    assert(test(a.ptr, 191));
    assert(!test(a.ptr, 190));
    foreach (i; 0 .. 192)
        assert(test(a.ptr, i) == (i == 0 || i == 3 || i == 191));
    assert(bt(a.ptr, 3));
    if (bt(a.ptr, 2))
        assert(0);
}
