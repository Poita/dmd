/* PERMUTE_ARGS: -O -inline
 */
// char is unsigned, so a constant of type char is not the same as one of
// type byte: sharing them would make the comparison of a byte unsigned.

pragma(inline, false) long f(double p5, byte p6)
{
    long[16] loc;       // cleared with a char 0
    if (0 > p6)
        p5 = 3;
    return cast(long)p5 + loc[p6 & 15];
}

pragma(inline, false) double fq(double x) { return x; }

pragma(inline, false) long g(byte p1, double p5, byte p6)
{
    long[16] loc;
    if (0 > p6)
        p5 = fq(p1);
    long[] da;
    foreach (k; 0 .. 2)
        da ~= cast(long)(p5 * 64) + k + loc[k];
    return da[0];
}

void main()
{
    assert(f(15, -128) == 3);
    assert(f(15, 5) == 15);
    assert(g(3, 15, -128) == 192);
    assert(g(3, 15, 1) == 960);
}
