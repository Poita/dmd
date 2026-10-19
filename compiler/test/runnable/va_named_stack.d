// C variadic functions whose last named parameters are passed on the stack, in
// fewer than 8 bytes, find their variadic arguments where the caller put them.

import core.stdc.stdarg;

extern (C) long nineInt(long a, long b, long c, long d, long e, long f, long g, long h, int k, ...)
{
    va_list ap;
    va_start(ap, k);
    long s = a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * k;
    s += 10 * va_arg!int(ap);
    s += 11 * va_arg!long(ap);
    va_end(ap);
    return s;
}

extern (C) double nineShort(long a, long b, long c, long d, long e, long f, long g, long h, short k, ...)
{
    va_list ap;
    va_start(ap, k);
    double s = a + b + c + d + e + f + g + h + 100 * k;
    s += va_arg!double(ap);
    s += 1000 * va_arg!int(ap);
    va_end(ap);
    return s;
}

extern (C) long tenInt(long a, long b, long c, long d, long e, long f, long g, long h, int k, int m, int n, ...)
{
    va_list ap;
    va_start(ap, n);
    long s = a + b + c + d + e + f + g + h + 10 * k + 100 * m + 1000 * n;
    s += 10_000 * va_arg!int(ap);
    va_end(ap);
    return s;
}

void main()
{
    assert(nineInt(1, 2, 3, 4, 5, 6, 7, 8, 2, 4, 4L) ==
        1 + 2 * 2 + 3 * 3 + 4 * 4 + 5 * 5 + 6 * 6 + 7 * 7 + 8 * 8 + 9 * 2 + 10 * 4 + 11 * 4);
    assert(nineShort(1, 1, 1, 1, 1, 1, 1, 1, cast(short)3, 0.5, 7) == 8 + 300 + 0.5 + 7000);
    assert(tenInt(1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5) == 8 + 20 + 300 + 4000 + 50_000);
}
