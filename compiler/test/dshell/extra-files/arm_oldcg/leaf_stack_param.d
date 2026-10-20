// A function calling nothing has no frame record, and reads the parameters
// passed on the stack relative to SP, also those it keeps in registers
struct S6 { double a, b, c, d; }

pragma(inline, false) double callee(double a0, double a1, double a2, double a3, double a4, double a5, S6 s)
{
    return a0 + s.a + 2 * s.b + 4 * s.c + 8 * s.d;
}

pragma(inline, false) long many(long a0, long a1, long a2, long a3, long a4, long a5, long a6, long a7,
    long a8, long a9, long a10)
{
    return a0 * 3 + a8 * 5 + a9 * 7 + a10 * 11;
}

int main()
{
    if (callee(1, 2, 3, 4, 5, 6, S6(10, 20, 30, 40)) != 491)
        return 1;
    if (many(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) != 3 + 45 + 70 + 121)
        return 2;
    return 0;
}
