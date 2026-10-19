// Elementwise int loops, vectorized 4 lanes at a time with a scalar tail, give
// what the scalar loop does for every length, including the wrapping of overflow.
module int_ops;

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

void vecAddMul(int[] c, const(int)[] a, const(int)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] * 3 + b[i] - 7;
}

void vecMulWrap(int* c, const(int)* a, const(int)* b, size_t n)
{
    foreach (i; 0 .. n)
        c[i] = a[i] * b[i] + int.max;
}

void vecLogic(int[] c, const(int)[] a, const(int)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = (a[i] & b[i]) ^ (a[i] | 5) ^ ~b[i];
}

void vecShift(int[] c, const(int)[] a)
{
    foreach (i; 0 .. c.length)
        c[i] = (a[i] << 3) + (a[i] >> 2) + cast(int)(cast(uint)a[i] >>> 5) - a[i];
}

void vecNeg(int[] c, const(int)[] a)
{
    foreach (i; 0 .. c.length)
        c[i] = -a[i];
}

void vecAbsDiff(int[] c, const(int)[] a, const(int)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] > b[i] ? a[i] - b[i] : b[i] - a[i];
}

void vecMin(int[] c, const(int)[] a, const(int)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] < b[i] ? a[i] : b[i];
}

void vecUMax(uint[] c, const(uint)[] a, const(uint)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] > b[i] ? a[i] : b[i];
}

void vecSelectConst(int[] c, const(int)[] a)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] >= 10 ? 100 : -1;
}

void vecEq(int[] c, const(int)[] a, const(int)[] b)
{
    foreach (i; 0 .. c.length)
        c[i] = a[i] == b[i];
}

void vecIota(int[] c)
{
    foreach (i; 0 .. c.length)
        c[i] = cast(int)i * 5 - 3;
}

void vecUintIndex(int[] c, const(int)[] a, uint n)
{
    foreach (uint i; 0 .. n)
        c[i] = a[i] + cast(int)i;
}

void vecIntFor(int* c, const(int)* a, int n)
{
    for (int i = 0; i < n; ++i)
        c[i] = a[i] * 7;
}

void vecInvariant(int[] c, const(int)[] a, int k, int m)
{
    foreach (i; 0 .. c.length)
        c[i] = (a[i] + k) * m;
}

void vecOffsets(int[] c, const(int)[] a)
{
    foreach (i; 1 .. c.length - 1)
        c[i] = a[i - 1] + 2 * a[i] + a[i + 1];
}

int refAddMul(int a, int b) { return id(a) * 3 + b - 7; }

int main()
{
    foreach (n; 0 .. 40)
    {
        auto a = new int[](n), b = new int[](n), c = new int[](n), r = new int[](n);
        foreach (i; 0 .. n)
        {
            a[i] = id(cast(int)(i * 2654435761u)) >> (i % 7);
            b[i] = id(cast(int)(i * 40503u + 17)) - 1000;
        }
        if (n > 3) { a[3] = int.max; b[3] = int.min; }
        if (n > 5) { a[5] = int.min; b[5] = int.min; }

        vecAddMul(c, a, b);
        foreach (i; 0 .. n) check(c[i] == refAddMul(a[i], b[i]));
        vecMulWrap(c.ptr, a.ptr, b.ptr, n);
        foreach (i; 0 .. n) check(c[i] == id(a[i]) * b[i] + int.max);
        vecLogic(c, a, b);
        foreach (i; 0 .. n) check(c[i] == ((id(a[i]) & b[i]) ^ (a[i] | 5) ^ ~b[i]));
        vecShift(c, a);
        foreach (i; 0 .. n) check(c[i] == (id(a[i]) << 3) + (a[i] >> 2) + cast(int)(cast(uint)a[i] >>> 5) - a[i]);
        vecNeg(c, a);
        foreach (i; 0 .. n) check(c[i] == -id(a[i]));
        vecAbsDiff(c, a, b);
        foreach (i; 0 .. n) check(c[i] == (id(a[i]) > b[i] ? a[i] - b[i] : b[i] - a[i]));
        vecMin(c, a, b);
        foreach (i; 0 .. n) check(c[i] == (id(a[i]) < b[i] ? a[i] : b[i]));
        auto uc = new uint[](n);
        vecUMax(uc, cast(uint[])a, cast(uint[])b);
        foreach (i; 0 .. n) check(uc[i] == (cast(uint)id(a[i]) > cast(uint)b[i] ? a[i] : b[i]));
        vecSelectConst(c, a);
        foreach (i; 0 .. n) check(c[i] == (id(a[i]) >= 10 ? 100 : -1));
        b[n / 2 .. $] = a[n / 2 .. $];
        vecEq(c, a, b);
        foreach (i; 0 .. n) check(c[i] == (id(a[i]) == b[i]));
        vecIota(c);
        foreach (i; 0 .. n) check(c[i] == id(cast(int)i) * 5 - 3);
        vecUintIndex(c, a, cast(uint)n);
        foreach (i; 0 .. n) check(c[i] == id(a[i]) + cast(int)i);
        vecIntFor(c.ptr, a.ptr, cast(int)n);
        foreach (i; 0 .. n) check(c[i] == id(a[i]) * 7);
        vecInvariant(c, a, 12345, -3);
        foreach (i; 0 .. n) check(c[i] == (id(a[i]) + 12345) * -3);
        if (n >= 2)
        {
            r[] = c[];
            vecOffsets(c, a);
            check(c[0] == r[0] && c[n - 1] == r[n - 1]);
            foreach (i; 1 .. n - 1) check(c[i] == id(a[i - 1]) + 2 * a[i] + a[i + 1]);
        }
    }
    return 0;
}
