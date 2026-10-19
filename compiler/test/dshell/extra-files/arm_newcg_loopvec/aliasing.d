// Vectorized loops whose arrays overlap, so that a lane would read or write what
// an earlier or later iteration of the same 4 writes, are done one iteration at a
// time, decided as they start; arrays that do not overlap, or are the same, are done
// 4 at a time.
module aliasing;

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

void vecCopyAdd(int* d, const(int)* s, size_t n)
{
    foreach (i; 0 .. n)
        d[i] = s[i] + 1;
}

void vecTwoStores(int* d, int* e, const(int)* s, size_t n)
{
    foreach (i; 0 .. n)
    {
        d[i] = s[i];
        e[i] = s[i] * 2;
    }
}

void vecStoreLoad(int* d, int* e, size_t n)
{
    foreach (i; 0 .. n)
    {
        d[i] = cast(int)i;
        e[i] += d[i] * 3;
    }
}

void vecUniform(int* d, const(int)* k, size_t n)
{
    foreach (i; 0 .. n)
        d[i] = *k + cast(int)i;
}

struct S { int[] a; int scale; }

void vecField(ref S s)
{
    foreach (i; 0 .. s.a.length)
        s.a[i] = s.a[i] * s.scale + 1;
}

void vecBytes(ubyte* d, const(int)* s, size_t n)
{
    foreach (i; 0 .. n)
        d[i] = cast(ubyte)((s[i] >> 3) + 1);
}

void refCopyAdd(int* d, const(int)* s, size_t n) { foreach (i; 0 .. n) d[i] = id(s[i] + 1); }
void refTwoStores(int* d, int* e, const(int)* s, size_t n) { foreach (i; 0 .. n) { d[i] = id(s[i]); e[i] = id(s[i] * 2); } }
void refStoreLoad(int* d, int* e, size_t n) { foreach (i; 0 .. n) { d[i] = id(cast(int)i); e[i] = id(e[i] + d[i] * 3); } }
void refUniform(int* d, const(int)* k, size_t n) { foreach (i; 0 .. n) d[i] = id(*k + cast(int)i); }
void refBytes(ubyte* d, const(int)* s, size_t n) { foreach (i; 0 .. n) d[i] = cast(ubyte)id((s[i] >> 3) + 1); }

int main()
{
    enum N = 64;
    foreach (n; 0 .. 24)
        foreach (dd; 0 .. 16)
            foreach (ds; 0 .. 16)
            {
                int[N] x, y;
                foreach (i; 0 .. N) x[i] = y[i] = id(cast(int)(i * 37 + 5));
                vecCopyAdd(x.ptr + dd, x.ptr + ds, n);
                refCopyAdd(y.ptr + dd, y.ptr + ds, n);
                check(x == y);

                foreach (i; 0 .. N) x[i] = y[i] = id(cast(int)(i * 37 + 5));
                vecTwoStores(x.ptr + dd, x.ptr + ds, x.ptr + 8, n);
                refTwoStores(y.ptr + dd, y.ptr + ds, y.ptr + 8, n);
                check(x == y);

                foreach (i; 0 .. N) x[i] = y[i] = id(cast(int)(i * 37 + 5));
                vecStoreLoad(x.ptr + dd, x.ptr + ds, n);
                refStoreLoad(y.ptr + dd, y.ptr + ds, n);
                check(x == y);

                foreach (i; 0 .. N) x[i] = y[i] = id(cast(int)(i * 37 + 5));
                vecUniform(x.ptr + dd, x.ptr + ds, n);
                refUniform(y.ptr + dd, y.ptr + ds, n);
                check(x == y);

                ubyte[N * 4] bx, by;
                foreach (i; 0 .. N) x[i] = y[i] = id(cast(int)(i * 37 + 5));
                foreach (i, ref v; bx) v = by[i] = cast(ubyte)id(cast(int)i);
                auto xb = cast(ubyte*)x.ptr, yb = cast(ubyte*)y.ptr;
                vecBytes(xb + dd * 3, x.ptr + ds, n);
                refBytes(yb + dd * 3, y.ptr + ds, n);
                check(x == y);
            }
    foreach (n; 0 .. 20)
    {
        S s;
        s.a = new int[](n);
        foreach (i, ref v; s.a) v = id(cast(int)i - 3);
        s.scale = 3;
        vecField(s);
        foreach (i, v; s.a) check(v == (id(cast(int)i) - 3) * 3 + 1);
    }
    return 0;
}
