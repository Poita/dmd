// C variadic functions whose named arguments run out of registers
#include <stdarg.h>

extern "C" {

long long c_var(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int n, ...)
{
    va_list ap;
    va_start(ap, n);
    long long s = a8 * 1000 + n * 100;
    for (int i = 0; i < n; ++i)
        s += va_arg(ap, long long) * (i + 1);
    va_end(ap);
    return s;
}

long long d_var(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int n, ...);

long long call_d_var()
{
    return d_var(1, 2, 3, 4, 5, 6, 7, 8, 9, 2, 11LL, 12LL);
}

}
