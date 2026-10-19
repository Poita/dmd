// Exceptions thrown through frames set up late: the unwinder restores the callee
// saved registers the late prolog saved, so the values of the catching function
// kept in them across the call are intact in the handler and after it.
module throw_through;

// asserts are compiled out with -release
void check(bool ok, int line = __LINE__)
{
    import core.stdc.stdio : fprintf, stderr;
    import core.stdc.stdlib : exit;
    if (!ok)
    {
        fprintf(stderr, "check failed at line %d\n", line);
        exit(1);
    }
}

class Boom : Exception
{
    long code;
    this(long code) { super("boom"); this.code = code; }
}

__gshared long sink;

pragma(inline, false) void thrower(long k)
{
    if (k == 7)
        throw new Boom(k);
    sink += k;
}

pragma(inline, false) long wrapped_inner(long a, long b, double f, long k)
{
    if (k < 0)
        return a;
    // a, b and f live across the calls, in callee saved registers
    thrower(k);
    const r = a * 3 + b;
    thrower(k + 2);
    return r + b * cast(long)f + a;
}

pragma(inline, false) long wrapped_outer(long a, long b, double f, long k)
{
    if (k < -100)
        return b;
    const g = f * 2 + a;
    long r = wrapped_inner(a + 1, b + 2, f + 0.5, k);
    r += wrapped_inner(b, a, g, k - 3);
    return r + cast(long)g + a * b;
}

long expect(long a, long b, double f, long k)
{
    long inner(long a, long b, double f, long k)
    {
        if (k < 0)
            return a;
        if (k == 7 || k + 2 == 7)
            return long.min;
        return a * 3 + b + b * cast(long)f + a;
    }
    if (k < -100)
        return b;
    const g = f * 2 + a;
    const r1 = inner(a + 1, b + 2, f + 0.5, k);
    if (r1 == long.min)
        return long.min;
    const r2 = inner(b, a, g, k - 3);
    if (r2 == long.min)
        return long.min;
    return r1 + r2 + cast(long)g + a * b;
}

pragma(inline, false) long framed_catch(long seed, long k)
{
    // values live across the call and used after the handler
    long x1 = seed * 5 + 1, x2 = seed ^ 0x55, x3 = seed * seed, x4 = seed - 9;
    long x5 = seed << 3, x6 = seed | 0x100, x7 = seed * 7 - 2, x8 = seed + 1234;
    double d1 = seed * 0.5, d2 = seed + 0.25, d3 = seed * 1.5 - 1, d4 = seed / 4.0;
    double d5 = seed - 0.75, d6 = seed * 2.0, d7 = seed + 3.5, d8 = seed * 0.125;
    long got;
    try
        got = wrapped_outer(seed, x1, d1, k);
    catch (Boom e)
    {
        check(e.code == 7);
        got = -1;
    }
    return got + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 +
        cast(long)((d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8) * 8);
}

long expectCatch(long seed, long k)
{
    long x1 = seed * 5 + 1, x2 = seed ^ 0x55, x3 = seed * seed, x4 = seed - 9;
    long x5 = seed << 3, x6 = seed | 0x100, x7 = seed * 7 - 2, x8 = seed + 1234;
    double d1 = seed * 0.5, d2 = seed + 0.25, d3 = seed * 1.5 - 1, d4 = seed / 4.0;
    double d5 = seed - 0.75, d6 = seed * 2.0, d7 = seed + 3.5, d8 = seed * 0.125;
    long got = expect(seed, x1, d1, k);
    if (got == long.min)
        got = -1;
    return got + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 +
        cast(long)((d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8) * 8);
}

void main()
{
    foreach (seed; [3L, 17, -40])
        foreach (k; [-200L, -1, 0, 1, 5, 7, 8, 9, 10, 12])
        {
            const want = expectCatch(seed, k);
            const got = framed_catch(seed, k);
            check(got == want);
        }
}
