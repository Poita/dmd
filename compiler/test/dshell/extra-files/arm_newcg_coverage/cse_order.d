// An expression the optimizer shares between blocks, first used in a block laid out
// before the one that dominates it.
module cse_order;

pragma(inline, false) long opq(long x) { return x ^ (x >> 3); }
struct Big { long a, b, c, d; }
pragma(inline, false) Big mkBig(long x) { return Big(x, x + 1, x * 2, x - 7); }
__gshared long[64] garr;

pragma(inline, false) long shared2(short p0, uint p1, long p2, uint p3, short p4, ulong p5, long p6, ulong p7, uint p8)
{
    int v0 = cast(int)(-37);
    long v1 = cast(long)(-23);
    {
        if ((opq(garr[57]) - p4) != opq(opq(p7)))
        {
            foreach (i79275; 0 .. 2)
            {
            }
            {
                p5 = cast(ulong)(((mkBig(p4).a >= (p7 * garr[47]) ? p3 : (p8 << (p1 & 31))) <= (opq(garr[5]) + p6) ? (mkBig(p4).a | opq(p8)) : ((p4 % ((p6 & 15) | 1)) >>> (mkBig(p4).d & 31))));
            }
        }
        else
        {
            v0 -= cast(int)(((v0 << (cast(long)cast(uint)p4 & 31)) * opq((garr[62] - garr[8]))));
            foreach (i68080; 0 .. 8)
            {
            }
        }
    }
    garr[(((p4 <= -17L ? p7 : 23L) >>> ((-95L << (v1 & 31)) & 31))) & 63] = ((garr[4] | p8) | (garr[27] % ((p6 & 15) | 1)));
    if (((p6 % ((v1 & 15) | 1)) & 7) == 3) return ((v0 & p8) + (96L / ((p6 & 7) | 1)));
    long h = 0;
    h = h * 31 + cast(long)(p8);
    return h;
}

/* Values live across the call in the callee saved registers, which hold neither
 * argument
 */
pragma(inline, false) long call(long x)
{
    long a = opq(x + 1), b = opq(x + 2), c = opq(x + 3), d = opq(x + 4), e = opq(x + 5);
    long f = opq(x + 6), g = opq(x + 7), h = opq(x + 8), i = opq(x + 9), j = opq(x + 10);
    long r = shared2(cast(short)(x * 2 - 3), cast(uint)(x * 3 - 3), x * 4 - 3, cast(uint)(x * 5 - 3),
        cast(short)(x * 6 - 3), cast(ulong)(x * 7 - 3), x * 8 - 3, cast(ulong)(x * 9 - 3), cast(uint)(x * 10 - 3));
    return r + (a ^ b ^ c ^ d ^ e ^ f ^ g ^ h ^ i ^ j);
}

void main()
{
    __gshared immutable long[4] want = [5714113898533392041L, -3536420541660838294L, 2830576557705945725L, -2225037318847951215L];
    foreach (x; 0 .. 4)
    {
        foreach (k, ref g; garr)
            g = cast(long)(k * 7 - 100);
        long sum = call(x);
        foreach (g; garr)
            sum = sum * 31 + g;
        assert(sum == want[x]);
    }
}
