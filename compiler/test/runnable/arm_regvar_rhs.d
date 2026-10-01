// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// A register variable assigned an expression with it as the right operand

pragma(inline, false) int ints(const(int)[] a, int k)
{
    int s = 1, t = 2, u = 3, v = 4;
    foreach (x; a)
    {
        s = x * k + s;
        t = x - t;
        u = (x ^ 5) & u;
        v = (x | 8) * v;
        s = (t << 1) + (s * 3 + u);
    }
    return s + t + u + v;
}

pragma(inline, false) double floats(const(double)[] a, double k)
{
    double s = 1, t = 2, u = 3;
    foreach (x; a)
    {
        s = x * k + s;
        t = x - t;
        u = (x + 1) * u;
        s = (t * 2) + (s * 0.5 + u);
    }
    return s + t + u;
}

void main()
{
    int s = 1, t = 2, u = 3, v = 4;
    foreach (x; [3, 7, 11])
    {
        const s1 = x * 2 + s;
        t = x - t;
        u = (x ^ 5) & u;
        v = (x | 8) * v;
        s = (t << 1) + (s1 * 3 + u);
    }
    assert(ints([3, 7, 11], 2) == s + t + u + v);

    double ds = 1, dt = 2, du = 3;
    foreach (x; [0.5, 1.5, 2.5])
    {
        const s1 = x * 3 + ds;
        dt = x - dt;
        du = (x + 1) * du;
        ds = (dt * 2) + (s1 * 0.5 + du);
    }
    assert(floats([0.5, 1.5, 2.5], 3) == ds + dt + du);
}
