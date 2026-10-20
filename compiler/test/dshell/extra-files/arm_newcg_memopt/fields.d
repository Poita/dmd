// Functions named opt... each have a load removed, taken from a store, or moved
// out of a loop by the new AArch64 code generator's memory optimizations.

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
    check(optForwardLong(&s, 1L << 40, -2) == (1L << 40) - 2);
}
