/* REQUIRED_ARGS: -O
 * PERMUTE_ARGS: -inline
 */
// A comparison of a signed with an unsigned operand is unsigned, also for the
// relations the optimizer derives from it. `(x ? 1 : 0) != 0` becomes the
// comparison `x >= 1u`, whose truth leaves x negative possible.

pragma(inline, false) int f(int x, int[] a)
{
    int r = a[0];
    if ((x ? 1 : 0) != 0)
    {
        if (x < 0)
            r += 1;
        else
            r += 2;
    }
    return r;
}

pragma(inline, false) int g(long x, int[] a)
{
    int r = a[0];
    if ((x ? 1 : 0) != 0)
    {
        if (x <= -1)
            r += 1;
        else
            r += 2;
    }
    else if (x > 0)
        r += 4;
    return r;
}

void main()
{
    int[1] a;
    assert(f(-5, a[]) == 1);
    assert(f(int.min, a[]) == 1);
    assert(f(5, a[]) == 2);
    assert(f(0, a[]) == 0);
    assert(g(-5, a[]) == 1);
    assert(g(long.min, a[]) == 1);
    assert(g(5, a[]) == 2);
    assert(g(0, a[]) == 0);
}
