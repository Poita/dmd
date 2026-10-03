// REQUIRED_ARGS: -O -release
// An expression statement whose value is unused keeps only its side effects,
// even after the optimizer strips the conversions around float-returning calls.

int calls;

pragma(inline, false) float f0(ulong a, double b)
{
    ++calls;
    return cast(float)(a + b);
}

pragma(inline, false) short f2(ulong p1)
{
    uint dead = cast(uint)f0(p1, 3) / cast(uint)f0(3 % (p1 ? p1 : 1), 127);
    return 255;
}

void main()
{
    if (!(f2(5) == 255)) assert(0);
    if (!(calls == 2)) assert(0);
}
