/* REQUIRED_ARGS: -O -inline
 */
// A function whose return blocks are rearranged to return a call in place keeps its
// own blocks as they were for the functions it is inlined into later

pragma(inline, false) real lib(real x, int n) pure nothrow @nogc @safe
{
    foreach (i; 0 .. n)
        x *= 2;
    return x;
}

pragma(inline, true)
real twice(real x, int n) @safe pure nothrow @nogc { return twiceImpl(x, n); }

pragma(inline, true)
private F twiceImpl(F)(F x, int n)
{
    if (__ctfe)
    {
        if (x == F(0.0))
            return x;
    }
    return lib(x, n);
}

void main()
{
    assert(twice(1.5L, 3) == 12.0L);
    assert(twice(-real.infinity, 5) == -real.infinity);
    assert(twice(2.0, 10) == 2048.0);
}
