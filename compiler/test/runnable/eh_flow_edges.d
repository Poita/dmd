/* REQUIRED_ARGS: -O
 * PERMUTE_ARGS: -inline -release
 */
// An exception thrown by a call in a try body goes to the handlers of each
// try enclosing it: the handlers, the finally blocks and the code after them
// see each variable as it was at the call that threw.

class E : Exception { this() { super("e"); } }
class F : Exception { this() { super("f"); } }

__gshared int g;

pragma(inline, false) void mayThrow(int i) { if (i == g) throw new E; }
pragma(inline, false) void mayThrowF(int i) { if (i == g) throw new F; }
pragma(inline, false) long opq(long x) { return x ^ (x >>> 7) ^ (x << 3); }
T tmax(T)(T a, T b) { return a < b ? b : a; }

// a constant assigned before the call that throws, another after it
pragma(inline, false) int constantBeforeThrow()
{
    int x = 1;
    try
    {
        x = 2;
        mayThrow(0);
        x = 3;
    }
    catch (E)
    {
        return x;
    }
    return x * 10;
}

// a copy made before the call that throws, its source changed after it
pragma(inline, false) int copyBeforeThrow(int a)
{
    int y = a;
    try
    {
        int x = a + 1;
        y = x;
        mayThrow(1);
        x = a + 2;
        y = x;
    }
    catch (E)
    {
    }
    return y;
}

// a store in one block of the try body overwritten in a later block
pragma(inline, false) int storeOverwritten(int a)
{
    int x = 0;
    try
    {
        x = a;
        if (a > 0)
            mayThrow(2);
        x = a * 2;
        mayThrow(a);
    }
    catch (E)
    {
        return x;
    }
    return -x;
}

// the exception passes the handler of an inner try that does not catch it
pragma(inline, false) int outerCatches(int a)
{
    int x = 0;
    try
    {
        try
        {
            x = a;
            mayThrowF(3);
            x = a * 3;
        }
        catch (E)
        {
            x = -1;
        }
    }
    catch (F)
    {
        return x;
    }
    return -x;
}

// a loop of the try body whose every pass throws: what the handler leaves
// in a variable reaches the next pass
pragma(inline, false) long throwEveryPass(long p0)
{
    long[16] loc;
    for (int w = 0; w < 3; ++w)
    {
        loc[g & 15] += tmax!ulong(100, p0 + 17);
        try
        {
            p0 ^= opq(w);
            throw new E;
        }
        catch (E)
        {
        }
    }
    return loc[0];
}

// the finally sees a variable a later call overwrites
pragma(inline, false) void finallySees(ref int r, int a)
{
    int x = a;
    try
    {
        x = a + 1;
        mayThrow(4);
        x = a + 2;
        mayThrow(4);
    }
    finally
        r = x;
}

// an induction variable read by an outer handler after an inner finally
pragma(inline, false) int inductionThroughFinally(int n)
{
    int k = 0;
    int r;
    try
    {
        try
        {
            for (int i = 0; i < n; ++i)
            {
                k += 2;
                mayThrowF(i);
            }
        }
        finally
            r = 1;
    }
    catch (F)
    {
        return k + r;
    }
    return -k;
}

void main()
{
    g = 0;
    if (!(constantBeforeThrow() == 2)) assert(0);
    g = 1;
    if (!(copyBeforeThrow(5) == 6)) assert(0);
    g = 2;
    if (!(storeOverwritten(7) == 7)) assert(0);
    g = 7;
    if (!(storeOverwritten(7) == 14)) assert(0);
    g = 3;
    if (!(outerCatches(4) == 4)) assert(0);
    g = 0;
    if (!(throwEveryPass(-44) == -72)) assert(0);
    g = 4;
    int r;
    try finallySees(r, 10); catch (E) {}
    if (!(r == 11)) assert(0);
    g = 3;
    if (!(inductionThroughFinally(10) == 9)) assert(0);
}
