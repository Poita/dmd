// Loops of 64 bit integers and doubles are done 2 iterations at a time in 64 bit
// lanes, and give what the scalar loop does: wrapping, rounding and NaNs included.
module lanes64;

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

pragma(inline, false) long idl(long x) { return x; }
pragma(inline, false) double idd(double x) { return x; }

void vecAddLong(long[] d, const(long)[] a, const(long)[] b)
{
    foreach (i; 0 .. d.length)
        d[i] = a[i] + (b[i] << 3) - 7;
}

void vecShiftLong(long[] d, const(long)[] a)
{
    foreach (i; 0 .. d.length)
        d[i] = (a[i] >> 7) ^ cast(long)(cast(ulong)a[i] >> 5);
}

void vecDoubleOps(double[] d, const(double)[] a, const(double)[] b)
{
    foreach (i; 0 .. d.length)
        d[i] = (a[i] - b[i]) / 3.0 + (-a[i]);
}

void vecMinDouble(double[] d, const(double)[] a, const(double)[] b)
{
    foreach (i; 0 .. d.length)
        d[i] = a[i] < b[i] ? a[i] : b[i];
}

void vecToDouble(double[] d, const(long)[] a)
{
    foreach (i; 0 .. d.length)
        d[i] = cast(double)a[i];
}

void vecToLong(long[] d, const(double)[] a)
{
    foreach (i; 0 .. d.length)
        d[i] = cast(long)a[i];
}

void vecSelectLong(long[] d, const(long)[] a, long k)
{
    foreach (i; 0 .. d.length)
        d[i] = a[i] > k ? a[i] : -a[i];
}

long vecSumLong(const(long)[] a)
{
    long s = 3;
    foreach (v; a)
        s += v;
    return s;
}

long vecSumIfLong(const(long)[] a, long k)
{
    long s;
    foreach (v; a)
        if (v > k)
            s -= v;
    return s;
}

ulong vecXorLong(const(ulong)[] a)
{
    ulong r = 0x1234_5678_9ABC_DEF0;
    foreach (v; a)
        r ^= v;
    return r;
}

void vecCopyLong(long* d, const(long)* s, size_t n)
{
    foreach (i; 0 .. n)
        d[i] = s[i] + 1;
}

// no 64 bit lanes multiply
void novecMulLong(long[] d, const(long)[] a)
{
    foreach (i; 0 .. d.length)
        d[i] = a[i] * a[i];
}

// a sum of doubles in another order rounds differently
double novecSumDouble(const(double)[] a)
{
    double s = 0;
    foreach (v; a)
        s += v;
    return s;
}

int main()
{
    foreach (n; 0 .. 66)
    {
        auto a = new long[](n), b = new long[](n), d = new long[](n);
        auto x = new double[](n), y = new double[](n), z = new double[](n);
        foreach (i; 0 .. n)
        {
            a[i] = idl(cast(long)(i * 0x9E37_79B9_7F4A_7C15UL));
            b[i] = idl(cast(long)i * 1_000_000_007 - long.max / 3);
            x[i] = idd(i % 5 == 0 ? double.nan : (cast(double)i - 30.25) * 1.0e10);
            y[i] = idd(i % 7 == 0 ? -double.infinity : cast(double)(n - i) / 3.0);
        }
        vecAddLong(d, a, b);
        foreach (i; 0 .. n) check(d[i] == a[i] + (b[i] << 3) - 7);
        vecShiftLong(d, a);
        foreach (i; 0 .. n) check(d[i] == ((a[i] >> 7) ^ cast(long)(cast(ulong)a[i] >> 5)));
        vecDoubleOps(z, x, y);
        foreach (i; 0 .. n)
        {
            const want = idd(idd(idd(x[i] - y[i]) / 3.0) + idd(-x[i]));
            check(z[i] is want || z[i] != z[i] && want != want);
        }
        vecMinDouble(z, x, y);
        foreach (i; 0 .. n) check(z[i] is (x[i] < y[i] ? x[i] : y[i]));
        vecToDouble(z, a);
        foreach (i; 0 .. n) check(z[i] == cast(double)a[i]);
        auto w = new double[](n);
        foreach (i; 0 .. n) w[i] = idd(i % 2 ? -1.5e15 * i : 0.75 * i);
        vecToLong(d, w);
        foreach (i; 0 .. n) check(d[i] == cast(long)w[i]);
        vecSelectLong(d, a, 12345);
        foreach (i; 0 .. n) check(d[i] == (a[i] > 12345 ? a[i] : -a[i]));
        long s = 3;
        foreach (v; a) s = idl(s + v);
        check(vecSumLong(a) == s);
        s = 0;
        foreach (v; a) if (v > -99) s = idl(s - v);
        check(vecSumIfLong(a, -99) == s);
        ulong r = 0x1234_5678_9ABC_DEF0;
        foreach (v; a) r = idl(r ^ v);
        check(vecXorLong(cast(ulong[])a) == r);
        // overlapping either way, and in place
        foreach (off; [-1, 0, 1, 2, 3])
        {
            auto buf = new long[](n + 8);
            foreach (i, ref v; buf) v = idl(i * 10);
            auto want = buf.dup;
            const dst = 4 + off;
            foreach (i; 0 .. n) want[dst + i] = want[4 + i] + 1;
            vecCopyLong(buf.ptr + dst, buf.ptr + 4, n);
            check(buf == want);
        }
        novecMulLong(d, a);
        foreach (i; 0 .. n) check(d[i] == a[i] * a[i]);
        double ds = 0;
        foreach (v; y) ds = idd(ds + v);
        const got = novecSumDouble(y);
        check(got is ds || got != got && ds != ds);
    }
    return 0;
}
