// A function large enough to skip the global optimizer must compute the
// same results as an equivalent small, globally optimized function.

ulong big(ulong x, ref double f)
{
    ulong acc = x;
    double d = f;
    static foreach (i; 0 .. 600)
    {
        acc = acc * 6364136223846793005UL + (i ^ (acc >> 7));
        if (acc & 1)
            d += i;
    }
    f = d;
    return acc;
}

ulong small(ulong x, ref double f)
{
    ulong acc = x;
    double d = f;
    foreach (i; 0 .. 600)
    {
        acc = acc * 6364136223846793005UL + (i ^ (acc >> 7));
        if (acc & 1)
            d += i;
    }
    f = d;
    return acc;
}

void main()
{
    foreach (ulong x; [0UL, 1, 42, ulong.max])
    {
        double f1 = 0.5, f2 = 0.5;
        assert(big(x, f1) == small(x, f2));
        assert(f1 == f2);
    }
}
