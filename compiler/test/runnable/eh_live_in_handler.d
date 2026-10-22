/* PERMUTE_ARGS: -O -inline
 */
// A variable assigned in a try block and read after the exception is caught
// keeps the value it had when the exception was thrown.

__gshared long[64] garr;

class FzEx : Exception { this() { super("fz"); } }

pragma(inline, false) long opq(long x) { return x ^ (x >>> 7) ^ (x << 3); }

pragma(inline, false) long loopThenThrow(long p)
{
    long v = p;
    try
    {
        int w = 1;
        while (w-- > 0)
            v *= (opq(garr[56]) >>> 23) & 7;
        throw new FzEx();
    }
    catch (FzEx e)
    {
    }
    return v;
}

pragma(inline, false) void thrower(int i) { if (i == 3) throw new FzEx(); }

pragma(inline, false) int countThenThrow()
{
    int n = 0;
    try
    {
        foreach (i; 0 .. 10)
        {
            n = i * 2;
            thrower(i);
        }
    }
    catch (FzEx e)
    {
        return n;
    }
    return -1;
}

void main()
{
    if (loopThenThrow(706) != 0)
        assert(0);
    if (countThenThrow() != 6)
        assert(0);
}
