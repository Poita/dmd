/* REQUIRED_ARGS: -O
 */
// Right shifts of signed values folded by the optimizer, where the shift count
// is unsigned and the value is typed as the unsigned type it combines with

int field(ulong bf, uint lo, uint width)
{
    int result = cast(int)(bf >> lo);
    result <<= 32 - width;
    result >>= 32 - width;
    return result;
}

void main()
{
    ulong bf = (cast(ulong)-5 << 32) & 64424509440UL;
    int result = cast(int)(bf >> 32U);
    result <<= 28U;
    result >>= 28U;
    assert(result == -5);

    short s = -300;
    s >>= 2U;
    assert(s == -75);
    byte b = -100;
    b >>= 3U;
    assert(b == -13);
    long l = -(1L << 40);
    l >>= 8U;
    assert(l == -(1L << 32));

    assert(field(bf, 32, 4) == -5);
}
