// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release -g

/* Callee-saved general and floating point registers, saved and restored in
 * pairs, keep their values across calls and through exceptions.
 */

__gshared int depth;

pragma(inline, false) int thrower(int x)
{
    if (x > 2)
        throw new Exception("boom");
    return x + 1;
}

pragma(inline, false) int busy(const(int)[] a, double f)
{
    int s0 = 1, s1 = 2, s2 = 3, s3 = 4, s4 = 5, s5 = 6, s6 = 7;
    double d0 = f, d1 = f * 2, d2 = f * 3, d3 = f * 4, d4 = f * 5;
    foreach (x; a)
    {
        s0 += thrower(x); s1 ^= s0; s2 += s1; s3 ^= s2; s4 += s3; s5 ^= s4; s6 += s5;
        d0 += x; d1 *= 1.5; d2 -= d0; d3 += d1; d4 -= d3;
    }
    return s0 + s1 + s2 + s3 + s4 + s5 + s6 + cast(int)(d0 + d1 + d2 + d3 + d4);
}

pragma(inline, false) int caller(const(int)[] a)
{
    int k0 = 11, k1 = 12, k2 = 13, k3 = 14;
    double e0 = 0.5, e1 = 1.5, e2 = 2.5;
    int r;
    try
        r = busy(a, 0.25);
    catch (Exception)
        r = -1;
    k0 += r; k1 += k0; k2 += k1; k3 += k2;
    return k0 + k1 + k2 + k3 + cast(int)(e0 + e1 + e2);
}

int main()
{
    int[3] ok = [0, 1, 2];
    int[3] bad = [0, 3, 1];
    const good = caller(ok[]);
    const r = busy(ok[], 0.25);
    assert(good == (11 + r) + (23 + r) + (36 + r) + (50 + r) + 4);
    assert(caller(bad[]) == 10 + 22 + 35 + 49 + 4);
    return 0;
}
