// Each function named opt<Kind>... has a load optimized by the new AArch64 code
// generator as Kind says: reused across a store (Reuse), taken from a store
// (Forward), moved out of a loop (Hoist), taken from a dominating access
// (Dominated), or kept in a register through a loop (Promote).

struct S { int x; int y; float f; long l; }

void check(bool c, int line = __LINE__)
{
    import core.stdc.stdio : printf;
    import core.stdc.stdlib : exit;
    if (!c)
    {
        printf("check failed at line %d\n", line);
        exit(1);
    }
}

// s.f is what was stored to it, with only a store to another field since
pragma(inline, false) float optForward(S* s, float v)
{
    s.f = v;
    s.x = 4;
    return s.f * 2;
}

// s.y is read again after a store to s.x, which cannot change it
pragma(inline, false) int optReuse(S* s)
{
    const a = s.y;
    s.x = a + 1;
    return s.y * 2 + s.x;
}

// s.y is the same on every iteration, as the loop stores only s.x, and the
// bytes on either side of it are written on the way to the loop, so it is
// accessible before the loop even when the loop does not run
pragma(inline, false) int optHoist(S* s, int n)
{
    s.x = 0;
    s.f = 0;
    foreach (i; 0 .. n)
        s.x += s.y * i;
    return s.x;
}

// the same, with s gone through before a branch on the way to the loop, after
// any call
pragma(inline, false) int pick(int n) { return n + 1; }
pragma(inline, false) int optHoistDominated(S* s, int n, bool b)
{
    int k = n;
    if (b)
        k = pick(n);
    s.x = 0;
    s.f = 0;
    if (b)
        s.l = k;
    foreach (i; 0 .. k)
        s.x += s.y * i;
    return s.x;
}

// s.y is read on entering the loop, which nothing can skip, and only s.x is
// stored in it
pragma(inline, false) int optHoistEntered(S* s, int n)
{
    int i = 0;
    s.x = 0;
    do
        s.x += s.y * i;
    while (++i < n);
    return s.x;
}

// s.y, read before the branch, is read again after it, with only a store to
// s.x on the way
pragma(inline, false) int optDominated(S* s, bool b, int v)
{
    int r = s.y;
    if (b)
    {
        s.x = r + v;
        s.f = v;
    }
    else
        r = r * 3 + v;
    return r + s.y;
}

// s.y is kept in a register through the loop, with the stores to it still made
pragma(inline, false) int optPromote(S* s, int[] a)
{
    s.x = 0;
    foreach (v; a)
    {
        s.y += v;
        s.x += s.y;
    }
    return s.y;
}

// the long is read back from the store made of it
pragma(inline, false) long optForwardLong(S* s, long v, int w)
{
    s.l = v;
    s.y = w;
    return s.l + s.y;
}

void main()
{
    S s;
    check(optForward(&s, 1.5f) == 3.0f && s.x == 4);
    s.y = 5;
    check(optReuse(&s) == 16);
    check(optHoist(&s, 4) == 30);
    check(optHoistDominated(&s, 3, true) == 30 && optHoistDominated(&s, 3, false) == 15);
    check(optHoistEntered(&s, 4) == 30 && optHoistEntered(&s, 0) == 0);
    s.y = 2;
    check(optDominated(&s, true, 5) == 4 && s.x == 7 && optDominated(&s, false, 5) == 13);
    s.y = 1;
    check(optPromote(&s, [1, 2, 3]) == 7 && s.x == 2 + 4 + 7);
    check(optForwardLong(&s, 1L << 40, -2) == (1L << 40) - 2);
}
