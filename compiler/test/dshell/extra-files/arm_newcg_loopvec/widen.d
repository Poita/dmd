// Loops over bytes and shorts, read into 32 bit lanes zero or sign extended and
// written back truncated, give what the scalar loop does.
module widen;

// asserts are compiled out by -release
void check(bool ok, int line = __LINE__)
{
    import core.stdc.stdio : printf;
    import core.stdc.stdlib : abort;
    if (!ok)
    {
        printf("check failed at line %d\n", line);
        abort();
    }
}

pragma(inline, false) int id(int x) { return x; }

void vecUbyte(int[] c, const(ubyte)[] a, const(int)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] * 3 + b[i];
}

void vecByte(int[] c, const(byte)[] a)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] - 1;
}

void vecShort(int[] c, const(short)[] a, const(ushort)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] * b[i];
}

void vecNarrow(ubyte[] c, const(ubyte)[] a, const(ubyte)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = cast(ubyte)(a[i] + b[i]);
}

void vecNarrowShort(short[] c, const(int)[] a)
{
    foreach (i; 0 .. c.length)
        c[i] = cast(short)(a[i] >> 1);
}

int vecMaxByte(const(ubyte)[] a)
{
    int m = 0;
    foreach (v; a)
        m = v > m ? v : m;
    return m;
}

int main()
{
    foreach (n; 0 .. 40)
    {
        auto a = new ubyte[](n), b = new ubyte[](n), sb = new byte[](n);
        auto s = new short[](n), us = new ushort[](n), ib = new int[](n), c = new int[](n);
        auto cb = new ubyte[](n), cs = new short[](n);
        foreach (i; 0 .. n)
        {
            a[i] = cast(ubyte)id(cast(int)(i * 77 + 200));
            b[i] = cast(ubyte)id(cast(int)(i * 13 + 100));
            sb[i] = cast(byte)a[i];
            s[i] = cast(short)id(cast(int)(i * 4099 - 30000));
            us[i] = cast(ushort)s[i];
            ib[i] = id(cast(int)(i * 2654435761u));
        }
        vecUbyte(c, a, ib);
        foreach (i; 0 .. n) check(c[i] == id(a[i]) * 3 + ib[i]);
        vecByte(c, sb);
        foreach (i; 0 .. n) check(c[i] == id(sb[i]) - 1);
        vecShort(c, s, us);
        foreach (i; 0 .. n) check(c[i] == id(s[i]) * us[i]);
        vecNarrow(cb, a, b);
        foreach (i; 0 .. n) check(cb[i] == cast(ubyte)(id(a[i]) + b[i]));
        vecNarrowShort(cs, ib);
        foreach (i; 0 .. n) check(cs[i] == cast(short)(id(ib[i]) >> 1));
        int m = 0;
        foreach (v; a) m = id(v > m ? v : m);
        check(vecMaxByte(a) == m);
    }
    return 0;
}
