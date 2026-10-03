// REQUIRED_ARGS: -O -release
// Parameters passed in two registers: slices (x regs) and two-float HFAs (v regs).

struct Vec2 { float x, y; }

pragma(inline, false) ulong sum(const(ulong)[] a, ulong k)
{
    ulong s = k;
    foreach (i; 0 .. a.length)
        s += a[i] * (i + 1);
    return s;
}

pragma(inline, false) float dot(Vec2 a, int n, Vec2 b)
{
    return a.x * b.x + a.y * b.y + n;
}

void main()
{
    ulong[4] v = [1, 2, 3, 4];
    if (!(sum(v[], 5) == 35)) assert(0);
    if (!(sum(v[1 .. 3], 0) == 8)) assert(0);
    if (!(dot(Vec2(1, 2), 3, Vec2(4, 5)) == 17)) assert(0);
}
