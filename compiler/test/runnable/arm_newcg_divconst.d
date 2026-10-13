/* REQUIRED_ARGS: -O
 */
// Division and remainder by constants: every operand size and signedness, against
// the same operations with the divisor not known, and a division by a constant
// compiled without a divide instruction

import core.stdc.stdio;

T divv(T)(T a, T b) { return cast(T)(a / b); }
T modv(T)(T a, T b) { return cast(T)(a % b); }

pragma(inline, false) T divc(T, T d)(T a) { return cast(T)(a / d); }
pragma(inline, false) T modc(T, T d)(T a) { return cast(T)(a % d); }

__gshared int failures;

void check(T, T d)(T a)
{
    auto pd = &divv!T;
    auto pm = &modv!T;
    const q = divc!(T, d)(a);
    const r = modc!(T, d)(a);
    const wq = pd(a, d);
    const wr = pm(a, d);
    if (q != wq || r != wr)
    {
        printf("%s %lld / %lld: %lld %lld, want %lld %lld\n", T.stringof.ptr, cast(long) a, cast(long) d,
            cast(long) q, cast(long) r, cast(long) wq, cast(long) wr);
        ++failures;
    }
}

void checkAll(T, T d)()
{
    static T[] samples()
    {
        T[] s;
        foreach (long v; -1100 .. 1100)
            s ~= cast(T) v;
        foreach (k; 0 .. T.sizeof * 8)
        {
            const T p = cast(T)(cast(T) 1 << k);
            s ~= p;
            s ~= cast(T)(p - 1);
            s ~= cast(T)(p + 1);
            s ~= cast(T)-p;
        }
        s ~= T.min;
        s ~= T.max;
        s ~= cast(T)(T.max - 1);
        s ~= cast(T)(T.min + 1);
        ulong x = 0x9E3779B97F4A7C15;
        foreach (i; 0 .. 2000)
        {
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            s ~= cast(T) x;
            s ~= cast(T)(cast(T) x / d * d);
            s ~= cast(T)(cast(T)(cast(T) x / d * d) - 1);
        }
        return s;
    }
    foreach (a; samples())
        check!(T, d)(a);
}

void checkType(T)()
{
    static foreach (long d; [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 25, 60, 64, 100, 127, 641,
        1000, 3600, 14_007, 65_535, 1_000_000_000, 10_000_000_000, 0x7FFF_FFFF, 0x8000_0001,
        0x7FFF_FFFF_FFFF_FFFF, -2, -3, -7, -8, -10, -1000, 0x8000_0000_0000_0001, -1])
        static if (cast(long) cast(T) d == d || (T.min == 0 && cast(T) d != 0 && T.sizeof == 8))
            static if (cast(T) d != 0 && cast(T) d != 1)
                checkAll!(T, cast(T) d)();
}

pragma(inline, false) ulong byBillion(ulong t) { return t / 1_000_000_000; }
pragma(inline, false) uint byTen(uint t) { return t % 10; }
pragma(inline, false) long bySeven(long t) { return t / 7; }
pragma(inline, false) int byEight(int t) { return t / 8; }

// Whether the code of f, up to its first return, divides
bool divides(void* f)
{
    const(uint)* p = cast(const(uint)*) f;
    for (; *p != 0xD65F03C0; ++p)
        if ((*p & 0x7FE0_F800) == 0x1AC0_0800)
            return true;
    return false;
}

void main()
{
    checkType!byte();
    checkType!ubyte();
    checkType!short();
    checkType!ushort();
    checkType!int();
    checkType!uint();
    checkType!long();
    checkType!ulong();
    assert(failures == 0);

    assert(byBillion(12_345_678_901_234) == 12_345);
    assert(byTen(1234) == 4);
    assert(bySeven(-50) == -7);
    assert(byEight(-15) == -1);
    version (AArch64)
    {
        assert(!divides(&byBillion));
        assert(!divides(&byTen));
        assert(!divides(&bySeven));
        assert(!divides(&byEight));
    }
}
