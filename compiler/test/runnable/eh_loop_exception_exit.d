/* REQUIRED_ARGS: -O
 * PERMUTE_ARGS: -inline -release
 */
// A loop in a try body is also left by an exception, at any call in it: the
// handler sees each variable as it was at the throw, so a definition read by
// the handler is neither moved out of the loop nor eliminated

class E : Exception { this() { super("e"); } }
__gshared int g;
__gshared int h;

pragma(inline, false) void mayThrow(int i) { if (i == g) throw new E; }

// an invariant assignment after the call that throws
pragma(inline, false) int invariantAfterThrow(int n)
{
    int x = 0;
    try
    {
        foreach (i; 0 .. n)
        {
            mayThrow(i);
            x = 5;
        }
    }
    catch (E) { return x; }
    return -x;
}

// the same, with the value read after the handler instead of in it
pragma(inline, false) int invariantReadAfter(int n, int a, int b)
{
    int x = 1;
    try
    {
        for (int i = 0; i < n; ++i)
        {
            mayThrow(i - h);
            x = a * b;
        }
    }
    catch (E) {}
    return x;
}

// a loop left only by the exception: an induction variable read in the handler
pragma(inline, false) int inductionEndless()
{
    int k = 0;
    try
    {
        for (int i = 0; ; ++i)
        {
            k += 4;
            mayThrow(i);
        }
    }
    catch (E) { return k; }
}

// a loop left only by the exception: an invariant assignment after the throw
pragma(inline, false) int invariantEndless(int a)
{
    int x = 1;
    try
    {
        for (int i = 0; ; ++i)
        {
            mayThrow(i - h);
            x = a * 2;
        }
    }
    catch (E) { return x; }
}

// a finally reads the induction variable as the exception passes through
pragma(inline, false) void inductionInFinally(ref int r)
{
    int k = 0;
    try
    {
        for (int i = 0; ; ++i)
        {
            k += 3;
            mayThrow(i);
        }
    }
    finally
        r = k;
}

// the finally reads the induction variable after a nested try/finally
pragma(inline, false) void inductionAfterNestedFinally(ref int r)
{
    int k = 0;
    try
    {
        for (int i = 0; ; ++i)
        {
            k += 5;
            mayThrow(i);
        }
    }
    finally
    {
        try
            mayThrow(-1);
        finally
            r = 1;
        r += k;
    }
}

void main()
{
    g = 0;
    h = 0;
    if (invariantAfterThrow(5) != 0) assert(0);
    if (invariantReadAfter(10, 3, 4) != 1) assert(0);
    h = 2;
    if (invariantReadAfter(10, 3, 4) != 12) assert(0);
    g = 3;
    if (inductionEndless() != 16) assert(0);
    g = 0;
    h = 0;
    if (invariantEndless(5) != 1) assert(0);
    h = 3;
    if (invariantEndless(5) != 10) assert(0);
    g = 4;
    int r;
    try inductionInFinally(r); catch (E) {}
    if (r != 15) assert(0);
    g = 2;
    r = 0;
    try inductionAfterNestedFinally(r); catch (E) {}
    if (r != 16) assert(0);
}
