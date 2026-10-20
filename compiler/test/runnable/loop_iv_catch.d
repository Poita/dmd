// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline
/* A variable a loop in a try block only changes is not dead when the loop is
 * left for a block that throws: the catch handler reads it.
 */

class E : Exception { this() { super("e"); } }

pragma(inline, false) long basicIV(long p, int n)
{
    try
    {
        for (int w = 0; w < n; ++w)
            p += 5;
        throw new E();
    }
    catch (E) {}
    return p;
}

pragma(inline, false) long opeqIV(byte p, int n)
{
    try
    {
        for (int w = 0; w < n; ++w)
            p &= cast(byte) 0xD9;
        throw new E();
    }
    catch (E) {}
    return p;
}

void main()
{
    foreach (x; 0 .. 4)
    {
        if (basicIV(x, 1) != x + 5)
            assert(0);
        if (basicIV(x, 3) != x + 15)
            assert(0);
        if (opeqIV(cast(byte) (x + 4), 1) != ((x + 4) & 0xD9))
            assert(0);
    }
}
