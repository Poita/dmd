/* REQUIRED_ARGS: -O
 */
// Selects with a zero arm, and narrow constants added as their negation

pragma(inline, false) uint low(uint x) { return x >= 2 ? x - 2 : 0; }
pragma(inline, false) long high(long x, long y) { return x < y ? 0 : x; }
pragma(inline, false) ushort sub3(ushort x) { return cast(ushort)(x + cast(ushort)0xFFFD); }
pragma(inline, false) ubyte dec(ubyte x) { return cast(ubyte)(x + cast(ubyte)0xFF); }

void main()
{
    if (low(5) != 3 || low(2) != 0 || low(1) != 0 || low(0) != 0 || low(uint.max) != uint.max - 2)
        assert(0);
    if (high(3, 4) != 0 || high(5, 4) != 5 || high(-1L << 40, 0) != 0)
        assert(0);
    if (sub3(10) != 7 || sub3(1) != 0xFFFE || dec(0) != 255 || dec(7) != 6)
        assert(0);
}
