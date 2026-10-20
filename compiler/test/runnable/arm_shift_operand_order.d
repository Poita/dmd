/* PERMUTE_ARGS: -O -inline
 */
// An operator fused with a shifted left operand evaluates the shift's operand
// before the right operand, which may reuse it as a common subexpression.

pragma(inline, false) long ident(long x) { return x; }

pragma(inline, false) long orShiftLeft(long p1, long p2, long p5)
{
    long[16] loc;
    long r = ((p1 << 8) | ((p5 < p2) ? p2 : p1));
    auto dg = (long q) => q + p1;
    return r + dg(loc[3]);
}

pragma(inline, false) long orShiftRight(long p1, long p2, long p5)
{
    long[16] loc;
    long r = (((p5 < p2) ? p2 : p1) | (p1 << 8));
    auto dg = (long q) => q + p1;
    return r + dg(loc[3]);
}

pragma(inline, false) long addSmallShift(long p1, long p2, long p5)
{
    long[16] loc;
    long r = (((p5 < p2) ? p2 : p1) + (p1 << 3));
    auto dg = (long q) => q + p1;
    return r + dg(loc[3]);
}

pragma(inline, false) long xorCall(long p1, long p2, long p5)
{
    long[16] loc;
    p2 ^= ident((((p5 < p2) ? p2 : p1) | (p1 << 8)));
    auto dg = (long q) => q + p1;
    return p2 + dg(loc[3]);
}

void main()
{
    if (orShiftLeft(1, 2, 3) != ((1 << 8) | 1) + 1) assert(0);
    if (orShiftLeft(1, 5, 3) != ((1 << 8) | 5) + 1) assert(0);
    if (orShiftRight(1, 2, 3) != ((1 << 8) | 1) + 1) assert(0);
    if (orShiftRight(1, 5, 3) != ((1 << 8) | 5) + 1) assert(0);
    if (addSmallShift(1, 2, 3) != (1 + 8) + 1) assert(0);
    if (addSmallShift(1, 5, 3) != (5 + 8) + 1) assert(0);
    if (xorCall(1, 2, 3) != (2 ^ (1 | 256)) + 1) assert(0);
    if (xorCall(1, 5, 3) != (5 ^ (5 | 256)) + 1) assert(0);
}
