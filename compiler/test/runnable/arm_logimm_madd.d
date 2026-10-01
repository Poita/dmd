// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* AND, ORR and EOR with bitmask immediates, and multiply-add and
 * multiply-subtract.
 */

pragma(inline, false) uint and1(uint x) { return x & 1; }
pragma(inline, false) uint andMask(uint x) { return x & 0x00FF_FF00; }
pragma(inline, false) uint notBitmask(uint x) { return x & 0x1234_5678; }
pragma(inline, false) ulong orr64(ulong x) { return x | 0xFFFF_0000_0000_FFFF; }
pragma(inline, false) uint eorTop(uint x) { return x ^ 0x8000_0000; }
pragma(inline, false) ulong eor64(ulong x) { return x ^ 0x5555_5555_5555_5555; }
pragma(inline, false) int test4(int x) { return (x & 4) ? 1 : 0; }
pragma(inline, false) int test4if(int x) { if (x & 4) return 7; return 9; }

pragma(inline, false) size_t index(size_t row, size_t n, size_t x) { return row * n + x; }
pragma(inline, false) size_t indexR(size_t row, size_t n, size_t x) { return x + row * n; }
pragma(inline, false) long msub(long a, long b, long c) { return c - a * b; }
pragma(inline, false) uint madd32(uint a, uint b, uint c) { return a * b + c; }
pragma(inline, false) int msub32(int a, int b, int c) { return c - a * b; }

/* The multiply defines a common subexpression that the other addend, with
 * a branch, uses too, so the multiply is evaluated first.
 */
struct Grid { uint ring; uint[16] pad; }
pragma(inline, false) size_t key(const(Grid)* g, uint qz, uint qx, bool skirt)
{
    return (skirt ? size_t(g.ring) * g.ring : 0) + size_t(qz) * g.ring + qx;
}

__gshared int counter;
pragma(inline, false) int next() { return ++counter; }

int main()
{
    assert(and1(7) == 1 && and1(6) == 0);
    assert(andMask(0xFFFF_FFFF) == 0x00FF_FF00);
    assert(notBitmask(0xFFFF_FFFF) == 0x1234_5678);
    assert(orr64(0x1234_0000_0000_5678) == 0xFFFF_0000_0000_FFFF);
    assert(eorTop(1) == 0x8000_0001);
    assert(eor64(0xFFFF_FFFF_FFFF_FFFF) == 0xAAAA_AAAA_AAAA_AAAA);
    assert(test4(5) == 1 && test4(3) == 0);
    assert(test4if(12) == 7 && test4if(8) == 9);

    assert(index(3, 10, 7) == 37);
    assert(indexR(3, 10, 7) == 37);
    assert(msub(6, 7, 50) == 8);
    assert(madd32(0x10000, 0x10000, 5) == 5);          // the product wraps in 32 bits
    assert(msub32(-3, 4, 1) == 13);

    // the operands are evaluated in order
    counter = 0;
    const r = next() + next() * next();                 // 1 + 2 * 3
    assert(r == 7);
    counter = 0;
    const s = next() * next() + next();                 // 1 * 2 + 3
    assert(s == 5);
    counter = 0;
    const t = next() - next() * next();                 // 1 - 2 * 3
    assert(t == -5);

    Grid g;
    g.ring = 5;
    assert(key(&g, 3, 2, false) == 17);
    assert(key(&g, 3, 2, true) == 42);
    return 0;
}
