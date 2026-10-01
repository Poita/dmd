// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Conditional expressions selecting between cheap values with CSEL and FCSEL.
 */

pragma(inline, false) int ifloor(float x) { const i = cast(int) x; return i > x ? i - 1 : i; }
pragma(inline, false) int imax(int a, int b) { return a > b ? a : b; }
pragma(inline, false) uint umin(uint a, uint b) { return a < b ? a : b; }
pragma(inline, false) long clamp(long v, long lo, long hi) { v = v < lo ? lo : v; return v > hi ? hi : v; }
pragma(inline, false) ulong pick(ulong a, ulong b, uint k) { return k >= 3 ? a << 2 : b ^ a; }
pragma(inline, false) float fmin(float a, float b) { return a < b ? a : b; }
pragma(inline, false) double dsel(double a, double b) { return a >= b ? a * 2 : b - 1; }
pragma(inline, false) int byNaN(float a) { return a == a ? 1 : 2; }
pragma(inline, false) float fnan(float a, float b) { return a > b ? a : b; }

int main()
{
    assert(ifloor(2.5f) == 2);
    assert(ifloor(-2.5f) == -3);
    assert(ifloor(-3.0f) == -3);
    assert(imax(-5, 3) == 3 && imax(7, -1) == 7);
    assert(umin(0xFFFF_FFFF, 2) == 2 && umin(1, 0x8000_0000) == 1);
    assert(clamp(-10, -3, 4) == -3 && clamp(10, -3, 4) == 4 && clamp(2, -3, 4) == 2);
    assert(pick(5, 3, 3) == 20 && pick(5, 3, 2) == 6);
    assert(fmin(1.5f, -2.5f) == -2.5f && fmin(-0.5f, 0.5f) == -0.5f);
    assert(dsel(3, 2) == 6 && dsel(1, 2) == 1);
    assert(byNaN(1) == 1 && byNaN(float.nan) == 2);
    assert(fnan(float.nan, 1) == 1);
    assert(fnan(2, 1) == 2);
    return 0;
}
