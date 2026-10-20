// An aggregate argument the optimizer replaced with a plain value takes its
// type from the prototype, matching each argument of an extern(C) function,
// whose arguments are in reverse order, with its own parameter
struct F1 { float f; }
struct D2 { double a, b; }
struct Big { double a, b, c, d, e; }

extern (C) pragma(inline, false) long take(F1 a, float b, short c, int d)
{
    return cast(long)(a.f * 4) * 1000000 + cast(long)(b * 4) * 10000 + c * 100 + d;
}

extern (C) pragma(inline, false) Big takeBig(F1 a, float b, short c, int d)
{
    return Big(a.f, b, c, d, 1);
}

extern (C) pragma(inline, false) long takeD2(int a, D2 b, long c)
{
    return a * 10000 + cast(long)(b.a * 100) + cast(long)(b.b * 10) + c;
}

extern (D) pragma(inline, false) long takeDlink(F1 a, float b, short c, int d)
{
    return cast(long)(a.f * 4) * 1000000 + cast(long)(b * 4) * 10000 + c * 100 + d;
}

void main()
{
    assert(take(F1(2.25f), 1.5f, 7, 42) == 9 * 1000000 + 6 * 10000 + 700 + 42);
    const big = takeBig(F1(2.25f), 1.5f, 7, 42);
    assert(big.a == 2.25 && big.b == 1.5 && big.c == 7 && big.d == 42 && big.e == 1);
    assert(takeD2(3, D2(0.5, 0.25), 9) == 30000 + 50 + 2 + 9);
    assert(takeDlink(F1(2.25f), 1.5f, 7, 42) == 9 * 1000000 + 6 * 10000 + 700 + 42);
}
