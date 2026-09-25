// Locals aligned beyond the 16 byte stack alignment, next to parameters and calls.
struct A64 { align(64) int[4] v; }
struct A32 { align(32) double d; }

__gshared size_t seen;

pragma(inline, false) void touch(void* p) { seen = cast(size_t) p; }

pragma(inline, false)
long f(long a, long b, long c, long d, long e, long g, long h, long i, long j, long k)
{
    A64 x;
    A32 y;
    int small = 7;
    assert((cast(size_t) &x) % 64 == 0);
    assert((cast(size_t) &y) % 32 == 0);
    x.v[] = 3;
    y.d = 2.5;
    touch(&x);
    touch(&y);
    touch(&small);
    return a + b + c + d + e + g + h + i + j + k + x.v[2] + cast(long) y.d + small;
}

pragma(inline, false) long outer(int depth)
{
    A64 z;
    assert((cast(size_t) &z) % 64 == 0);
    z.v[0] = depth;
    return depth ? outer(depth - 1) + z.v[0] : f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
}

pragma(inline, false) long nested(long p, long q)
{
    A64 x;
    x.v[] = 5;
    long local = 11;
    long inner(long r)
    {
        assert((cast(size_t) &x) % 64 == 0);
        return x.v[1] + local + p + q + r;
    }
    return inner(100);
}

void main()
{
    assert(nested(1000, 2000) == 5 + 11 + 1000 + 2000 + 100);
    assert(f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == 55 + 3 + 2 + 7);
    assert(outer(3) == 55 + 12 + 6);
    try
    {
        A64 w;
        assert((cast(size_t) &w) % 64 == 0);
        throw new Exception("x");
    }
    catch (Exception) {}
}
