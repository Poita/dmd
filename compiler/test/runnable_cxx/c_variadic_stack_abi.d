/* The named arguments of a C variadic function that go on the stack are at
 * their own size and alignment, the last one too, and the variadic ones
 * follow from the next multiple of 8 bytes
 *
 * EXTRA_CPP_SOURCES: c_variadic_stack_abi.cpp
 */
import core.stdc.stdarg;

extern (C)
{
long c_var(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int n, ...);
long call_d_var();

long d_var(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int n, ...)
{
    va_list ap;
    va_start(ap, n);
    long s = a8 * 1000 + n * 100;
    foreach (i; 0 .. n)
        s += va_arg!long(ap) * (i + 1);
    va_end(ap);
    return s;
}
}

void main()
{
    enum expect = 9 * 1000 + 2 * 100 + 11 + 12 * 2;
    if (c_var(1, 2, 3, 4, 5, 6, 7, 8, 9, 2, 11L, 12L) != expect)
        assert(0, "D calling C");
    if (call_d_var() != expect)
        assert(0, "C calling D");
    if (d_var(1, 2, 3, 4, 5, 6, 7, 8, 9, 2, 11L, 12L) != expect)
        assert(0, "D calling D");
}
