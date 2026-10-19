// Functions whose early returns need no frame: the frame is set up and the callee
// saved registers saved only on the paths that call, and the arguments copied to
// callee saved registers are copied there only then.
module early_exit;

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

__gshared long sink;

pragma(inline, false) void heavy(long x) { sink += x; }

pragma(inline, false) int wrapped_sum(const(int)* p, int n)
{
    if (p is null)
        return -1;
    int s;
    foreach (i; 0 .. n)
    {
        heavy(p[i]);
        s += p[i];
    }
    return s;
}

pragma(inline, false) long wrapped_fib(long n)
{
    if (n < 2)
        return n;
    return wrapped_fib(n - 1) + wrapped_fib(n - 2);
}

pragma(inline, false) double wrapped_mix(double x, double y, long k)
{
    if (k == 0)
        return x + y;
    heavy(k);
    const t = x * y;
    heavy(k + 1);
    return t + x - y + k;
}

pragma(inline, false) long wrapped_tail(long a, long b)
{
    if (a > b)
        return a - b;
    heavy(a);
    heavy(b);
    return a * b;
}

// the path without the frame laid out after the one with it
pragma(inline, false) long wrapped_late(long a, long b)
{
    if (a != 0)
    {
        heavy(a);
        heavy(b);
        return a + b;
    }
    return b * 3;
}

pragma(inline, false) long framed_both(long a)
{
    if (a < 0)
    {
        heavy(a);
        return 1;
    }
    heavy(-a);
    return 2;
}

pragma(inline, false) long framed_loop(long n)
{
    long s;
    foreach (i; 0 .. n)
        if (i & 1)
            heavy(i);
        else
            s += i;
    return s;
}

void main()
{
    int[4] a = [1, 2, 3, 4];
    check(wrapped_sum(null, 4) == -1);
    check(sink == 0);
    check(wrapped_sum(a.ptr, 4) == 10);
    check(sink == 10);
    check(wrapped_fib(1) == 1);
    check(wrapped_fib(20) == 6765);
    check(wrapped_mix(1.5, 2.25, 0) == 3.75);
    sink = 0;
    check(wrapped_mix(2, 3, 4) == 6 + 2 - 3 + 4);
    check(sink == 9);
    check(wrapped_tail(9, 4) == 5);
    check(wrapped_tail(3, 4) == 12);
    check(wrapped_late(0, 5) == 15);
    check(wrapped_late(2, 5) == 7);
    check(framed_both(-1) == 1);
    check(framed_both(1) == 2);
    check(framed_loop(10) == 0 + 2 + 4 + 6 + 8);
}
