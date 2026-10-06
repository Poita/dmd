// Fills of slices of many lengths and offsets, leaving what is around them

void check(T)(T v)
{
    foreach (off; 0 .. 4)
        foreach (n; [0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 33, 100])
        {
            auto a = new T[](off + n + 3);
            foreach (i, ref x; a)
                x = cast(T)(i + 1);
            a[off .. off + n] = v;
            foreach (i, x; a)
                if (i >= off && i < off + n ? x != v : x != cast(T)(i + 1))
                    assert(0);
        }
}

void main()
{
    check!float(2.5f);
    check!double(-0.125);
    check!int(-7);
    check!uint(0xDEAD_BEEF);
    check!long(-1L << 40);
    check!ulong(0x0123_4567_89AB_CDEF);
}
