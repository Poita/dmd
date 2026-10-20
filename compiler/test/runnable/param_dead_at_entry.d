/* PERMUTE_ARGS: -O -inline
 */
// A parameter whose incoming value is dead shares its assigned register with
// a parameter that is live only before it is assigned, and the prolog does
// not load the dead one over the live one.

__gshared long[64] garr;
__gshared int[16] gi;

class FzEx : Exception { this() { super("fz"); } }

T tmin(T)(T a, T b) { return a < b ? a : b; }
T tmix(T)(T a, T b) { return cast(T)((a ^ (b << 5)) + (b >>> 2)); }

struct S1 { }

pragma(inline, false) S1 mkS1(long x) { return S1(); }

long f1(int p0, ushort p1, short p2, ubyte p3, ushort p4, ubyte p5)
{
    long v21 = -7129497315051291894L;
    long v22 = 4061143547657179708L;
    short v26 = -19001;
    uint v28 = 80;
    long[16] loc;
    p1 = cast(ushort)(tmin!uint(cast(uint)(0xFFFF_FFFF_FFFF_FF9FUL & p4), v28) >> 21);
    S1 s29 = mkS1((tmin!long(p5, v26) == p2 + p3) ? v21 : p1 - cast(byte)30);
    try
    {
    }
    catch (FzEx ex31)
    {
        auto dg32 = (long q) => q * -4 + p0;
    }
    long dg33(long q) { p4 += cast(ushort)q; return q ^ p4; }
    return dg33((v26 != 0) ? garr[15] / 16 : ~v22);
}

void main()
{
    foreach (long x; 0 .. 4)
    {
        const r = f1(cast(int)(garr[6] | x), cast(ushort)(x * x),
            cast(short)tmix!int(-66, gi[10]), cast(ubyte)cast(byte)-70,
            cast(ushort)(x / 15), cast(ubyte)(17 / ((garr[47] & 15) | 1)));
        if (r != 0)
            assert(0);
    }
}
