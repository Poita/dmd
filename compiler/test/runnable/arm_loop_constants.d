// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// Constants that take several instructions to load, used in loops

pragma(inline, false) ulong hashAll(const(uint)[] a, ulong seed)
{
    ulong h = seed ^ 0x9E3779B97F4A7C15UL;
    foreach (x; a)
    {
        h ^= x * 0xD6E8FEB86659FD93UL;
        h ^= h >> 32;
        h *= 0xCA5A826395121157UL;
    }
    return h;
}

pragma(inline, false) double scale(float[] a, double[] b)
{
    double s = 0;
    foreach (i, ref x; a)
    {
        x = x * 0.7f + 1.3f;
        if (x > 0.25f)
            s += x * 1e-6;
        b[i] = b[i] * 1.1 - 0.3;
        if (b[i] == 0.0)
            s -= 1;
    }
    return s;
}

pragma(inline, false) long nested(int n)
{
    long t = 0;
    foreach (i; 0 .. n)
    {
        t += 0x12345678;
        foreach (j; 0 .. n)
        {
            t ^= 0x1234_5678_9ABC_DEF0L;
            t -= 0x7654_3210;
            if (t > 0x1_0000_0001L)
                t &= 0xFFFF_0000_FFFFL;
        }
    }
    return t;
}

pragma(inline, false) int inTry(int[] a)
{
    int r;
    try
    {
        foreach (x; a)
        {
            r += x * 100_003;
            if (r > 2_000_000_003)
                throw new Exception("big");
        }
    }
    catch (Exception)
        r = -1;
    return r;
}

void main()
{
    ulong h = 7 ^ 0x9E3779B97F4A7C15UL;
    foreach (x; [1u, 2, 3])
    {
        h ^= x * 0xD6E8FEB86659FD93UL;
        h ^= h >> 32;
        h *= 0xCA5A826395121157UL;
    }
    assert(hashAll([1, 2, 3], 7) == h);
    assert(hashAll([], 7) == (7 ^ 0x9E3779B97F4A7C15UL));

    float[3] f = [1, 2, 3];
    double[3] d = [1, 2, 3];
    const s = scale(f, d);
    assert(f[0] == 1 * 0.7f + 1.3f && d[2] == 3 * 1.1 - 0.3);
    double es = 0;
    foreach (k; 0 .. 3)
        es += ((k + 1) * 0.7f + 1.3f) * 1e-6;
    assert(s == es);
    assert(scale(null, null) == 0);

    long t = 0;
    foreach (i; 0 .. 5)
    {
        t += 0x12345678;
        foreach (j; 0 .. 5)
        {
            t ^= 0x1234_5678_9ABC_DEF0L;
            t -= 0x7654_3210;
            if (t > 0x1_0000_0001L)
                t &= 0xFFFF_0000_FFFFL;
        }
    }
    assert(nested(5) == t);
    assert(nested(0) == 0);

    assert(inTry([1, 2, 3]) == 6 * 100_003);
    assert(inTry([20_000, 20_000]) == -1);
}
