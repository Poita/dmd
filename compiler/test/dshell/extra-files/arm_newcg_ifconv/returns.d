// Choices between returning cheap values

int sel0_clamp(int x, int lo, int hi)
{
    if (x < lo)
        return lo;
    if (x > hi)
        return hi;
    return x;
}

int sel0_signum(long x)
{
    if (x > 0)
        return 1;
    if (x < 0)
        return -1;
    return 0;
}

double sel0_clampd(double x, double lo, double hi)
{
    if (x < lo)
        return lo;
    if (x > hi)
        return hi;
    return x;
}

uint sel0_pick(uint a, uint b, uint c)
{
    if (a == b)
        return c + 1;
    return c - 1;
}

pragma(inline, false) int calls(int x) { return x * 3; }

// a call is not made unless chosen
int choose(int x)
{
    if (x > 0)
        return calls(x);
    return x;
}

void main()
{
    if (sel0_clamp(5, 0, 10) != 5 || sel0_clamp(-5, 0, 10) != 0 || sel0_clamp(50, 0, 10) != 10) assert(0);
    if (sel0_clamp(int.min, int.min, int.max) != int.min) assert(0);
    if (sel0_signum(long.min) != -1 || sel0_signum(0) != 0 || sel0_signum(long.max) != 1) assert(0);
    if (sel0_clampd(0.5, 0, 1) != 0.5 || sel0_clampd(-3, 0, 1) != 0 || sel0_clampd(7, 0, 1) != 1) assert(0);
    // a NaN compares false, so is returned
    const n = sel0_clampd(double.nan, 0, 1);
    if (n == n) assert(0);
    if (sel0_pick(1, 1, 0) != 1 || sel0_pick(1, 2, 0) != uint.max) assert(0);
    if (choose(2) != 6 || choose(-2) != -2) assert(0);
}
