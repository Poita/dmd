/* REQUIRED_ARGS: -O
 */
// A variable assigned in a try body that always throws keeps that value in
// the catch handler and after it, though only the exception reaches them

class E : Exception { this() { super("e"); } }
__gshared uint g = 3;

pragma(inline, false) long assignedInLoop(uint p1)
{
    try
    {
        for (int w = 0; w < 2; ++w)
            p1 *= g;
        throw new E;
    }
    catch (E)
    {
    }
    return p1;
}

pragma(inline, false) long seenInCatch(uint p1)
{
    long r;
    try
    {
        for (int w = 0; w < 2; ++w)
            p1 *= g;
        throw new E;
    }
    catch (E)
    {
        r = p1;
    }
    return r;
}

pragma(inline, false) long h(long x) { return x * 7 + 3; }

pragma(inline, false) long reachesLoopHead(ulong p0, int p2)
{
    for (int w = 0; w < 4; ++w)
    {
        long x = p2;
        p0 += x;
        try
        {
            p2 -= cast(int)h(p2);
            throw new E;
        }
        catch (E)
        {
        }
    }
    return p0;
}

pragma(inline, false) long nested(uint p1)
{
    try
    {
        try
        {
            for (int w = 0; w < 4; ++w)
                p1 *= g;
            throw new E;
        }
        catch (E)
        {
        }
    }
    catch (Exception)
    {
    }
    return p1;
}

void main()
{
    assert(assignedInLoop(5) == 45);
    assert(seenInCatch(5) == 45);
    assert(reachesLoopHead(1, 64) == -11920);
    assert(nested(1) == 81);
}
