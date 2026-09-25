// Filling arrays of each element size with a value.

struct D2 { double re = 0, im = 0; }

T[] fill(T)(T[] a, T v) { a[] = v; return a; }

void check(T)(T v)
{
    T[7] a;
    T[8] guard;
    fill(a[], v);
    foreach (e; a)
        assert(e == v);
    foreach (e; guard)
        assert(e is T.init);
}

void main()
{
    check!ubyte(0xA5);
    check!ushort(0xA5B6);
    check!uint(0xA5B6_C7D8);
    check!ulong(0xA5B6_C7D8_1234_5678);
    check!double(2.5);
    check!D2(D2(1.5, 2.5));
    ulong[16] b = 1;
    assert(b[15] == 1);
}
