// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release
/* A variable a loop in a try block only changes stays live for the code that
 * runs when an exception leaves the loop: a throw in the loop body, a finally
 * block, scope(failure), or a handler of an enclosing try.
 */

class E : Exception { this() { super("e"); } }

pragma(inline, false) void maybe(int w, int n)
{
    if (w == n)
        throw new E();
}

pragma(inline, false) long throwInLoop(long p, int n)
{
    try
    {
        for (int w = 0; w < 10; ++w)
        {
            p += 3;
            maybe(w, n);
        }
    }
    catch (E) {}
    return p;
}

pragma(inline, false) long viaFinally(long p, int n)
{
    long r;
    try
    {
        try
        {
            for (int w = 0; w < n; ++w)
                p *= 3;
            throw new E();
        }
        finally
            r = p;
    }
    catch (E) {}
    return r;
}

pragma(inline, false) int outerHandler(int p, int n)
{
    try
    {
        try
        {
            for (int w = 0; w < n; ++w)
                p ^= 0x55;
            throw new E();
        }
        catch (Error) {}
    }
    catch (E)
        return p;
    return -1;
}

pragma(inline, false) uint scopeFailure(uint p, int n)
{
    uint r;
    try
    {
        scope (failure) r = p;
        for (int w = 0; w < n; ++w)
            p <<= 1;
        throw new E();
    }
    catch (E) {}
    return r;
}

pragma(inline, false) long whileLoop(long p, int n)
{
    try
    {
        int w;
        while (w++ < n)
            p -= 7;
        maybe(0, 0);
    }
    catch (E) {}
    return p;
}

void main()
{
    foreach (n; 0 .. 5)
    {
        if (throwInLoop(1, n) != 1 + 3 * (n + 1))
            assert(0);
        long v = 2;
        foreach (i; 0 .. n)
            v *= 3;
        if (viaFinally(2, n) != v)
            assert(0);
        if (outerHandler(9, n) != ((n & 1) ? (9 ^ 0x55) : 9))
            assert(0);
        if (scopeFailure(3, n) != (3u << n))
            assert(0);
        if (whileLoop(100, n) != 100 - 7 * n)
            assert(0);
    }
}
