/* REQUIRED_ARGS: -O
 */
// core.bitop's bsf, bsr, popcnt and bswap of every size, at the lowest and
// highest bits and in a loop over a mask

import core.bitop;

int slowBsf(ulong v) { int i; while (!(v & 1)) { v >>= 1; ++i; } return i; }
int slowBsr(ulong v) { int i = -1; while (v) { v >>= 1; ++i; } return i; }
int slowPop(ulong v) { int n; while (v) { n += v & 1; v >>= 1; } return n; }

void check(ulong v)
{
    if (v)
    {
        assert(bsf(v) == slowBsf(v));
        assert(bsr(v) == slowBsr(v));
        if (cast(uint) v)
        {
            assert(bsf(cast(uint) v) == slowBsf(cast(uint) v));
            assert(bsr(cast(uint) v) == slowBsr(cast(uint) v));
        }
    }
    assert(popcnt(v) == slowPop(v));
    assert(popcnt(cast(uint) v) == slowPop(cast(uint) v));
    assert(bswap(v) == ((v & 0xFF) << 56 | (v >> 8 & 0xFF) << 48 | (v >> 16 & 0xFF) << 40 | (v >> 24 & 0xFF) << 32 |
                        (v >> 32 & 0xFF) << 24 | (v >> 40 & 0xFF) << 16 | (v >> 48 & 0xFF) << 8 | v >> 56));
    const w = cast(uint) v;
    assert(bswap(w) == ((w & 0xFF) << 24 | (w >> 8 & 0xFF) << 16 | (w >> 16 & 0xFF) << 8 | w >> 24));
    const h = cast(ushort) v;
    assert(byteswap(h) == cast(ushort)((h & 0xFF) << 8 | h >> 8));
}

// the squares of a mask, lowest first, as move generators walk bitboards
int[] squares(ulong mask)
{
    int[] r;
    while (mask)
    {
        r ~= bsf(mask);
        mask &= mask - 1;
    }
    return r;
}

void main()
{
    foreach (i; 0 .. 64)
    {
        check(1UL << i);
        check(~0UL << i);
        check(~0UL >> i);
        check((1UL << i) | 1);
        check(0x9E37_79B9_7F4A_7C15UL * (i + 1));
    }
    check(0);
    check(ulong.max);
    assert(squares(0x8000_0000_0000_0011UL) == [0, 4, 63]);
    assert(squares(0) == []);
}
