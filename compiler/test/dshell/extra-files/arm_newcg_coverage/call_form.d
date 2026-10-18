// Calls of C variadic functions, whose variadic arguments are on the stack, and
// calls with more than 16 arguments.
module call_form;

import core.stdc.stdarg;
import core.stdc.stdio : snprintf;

extern (C) pragma(inline, false) long calleeSum(int n, ...)
{
    va_list ap;
    va_start(ap, n);
    long s;
    foreach (i; 0 .. n)
        s = s * 3 + va_arg!long(ap);
    va_end(ap);
    return s;
}

extern (C) pragma(inline, false) double calleeMixed(int n, double scale, ...)
{
    va_list ap;
    va_start(ap, scale);
    double s = 0;
    foreach (i; 0 .. n)
    {
        s += scale * va_arg!int(ap);
        s += va_arg!double(ap);
        s += *va_arg!(int*)(ap);
    }
    va_end(ap);
    return s;
}

// with nine explicit integer arguments, the last of them on the stack too
extern (C) pragma(inline, false) long calleeMany(long a, long b, long c, long d, long e, long f, long g, long h,
    int k, ...)
{
    va_list ap;
    va_start(ap, k);
    long s = a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * k;
    s += 10 * va_arg!int(ap);
    s += 11 * va_arg!long(ap);
    va_end(ap);
    return s;
}

long sums(long x)
{
    return calleeSum(4, x, x + 1, cast(long)ubyte(7), -x);
}

double mixed(int a, double b, int c)
{
    int m = 100;
    return calleeMixed(2, 0.5, a, b, &m, c, -b, &c);
}

long many(long x, int y)
{
    return calleeMany(x, x + 1, x + 2, x + 3, x + 4, x + 5, x + 6, x + 7, y, y * 2, x * 4);
}

const(char)[] format(char[] buf, int i, double d, const(char)* s, long l)
{
    const n = snprintf(buf.ptr, buf.length, "%d %.2f %s %lld %c", i, d, s, l, 'z');
    return buf[0 .. n];
}

pragma(inline, false) long calleeLong(int a0, float f0, int a1, string s0, int a2, double f1, int a3, int a4,
    int a5, int a6, int a7, float f2, int a8, string s1, int a9, double f3, int a10, int a11, ubyte b0,
    float f4, long l0)
{
    return a0 + 2 * a1 + 3 * a2 + 4 * a3 + 5 * a4 + 6 * a5 + 7 * a6 + 8 * a7 + 9 * a8 + 10 * a9 + 11 * a10 +
        12 * a11 + 13 * b0 + 14 * l0 + cast(long)(f0 + 2 * f1 + 3 * f2 + 4 * f3 + 5 * f4) +
        100 * (s0.length + 2 * s1.length);
}

long longCall(int x)
{
    return calleeLong(x, 1.5f, x + 1, "ab", x + 2, 2.25, x + 3, x + 4, x + 5, x + 6, x + 7, 3.0f, x + 8,
        "cdef", x + 9, 4.5, x + 10, x + 11, cast(ubyte)(x + 12), 5.0f, x * 1000L);
}

int main()
{
    assert(sums(5) == ((5 * 3 + 6) * 3 + 7) * 3 - 5);
    assert(mixed(3, 1.25, 4) == 0.5 * 3 + 1.25 + 100 + 0.5 * 4 - 1.25 + 4);
    assert(many(1, 2) == 1 + 2 * 2 + 3 * 3 + 4 * 4 + 5 * 5 + 6 * 6 + 7 * 7 + 8 * 8 + 9 * 2 + 10 * 4 + 11 * 4);
    char[64] buf;
    assert(format(buf[], -12, 3.14159, "str", 1L << 40) == "-12 3.14 str 1099511627776 z");
    const x = 1;
    long want = 0;
    foreach (k; 0 .. 12)
        want += (k + 1) * (x + k);
    want += 13 * (x + 12) + 14 * 1000L + cast(long)(1.5f + 2 * 2.25 + 3 * 3.0f + 4 * 4.5 + 5 * 5.0f) + 100 * (2 + 8);
    assert(longCall(x) == want);
    return 0;
}
