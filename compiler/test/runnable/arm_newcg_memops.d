// REQUIRED_ARGS: -O -inline -release
// Block copies and fills, and a quotient with its remainder.

struct S { int[5] a; ubyte[3] b; }

pragma(inline, false) void fill(ubyte[] a, ubyte v) { a[] = v; }
pragma(inline, false) void copy(int[] d, const(int)[] s) { d[] = s[]; }
pragma(inline, false) void clear(ref S s) { s = S.init; }
pragma(inline, false) void small(ref int[4] d, ref const int[4] s) { d = s; }

pragma(inline, false) long divmod(long a, long b, ref long r)
{
    r = a % b;
    return a / b;
}

pragma(inline, false) int divmod32(int a, int b, ref int r)
{
    r = a % b;
    return a / b;
}

pragma(inline, false) uint udivmod32(uint a, uint b, ref uint r)
{
    r = a % b;
    return a / b;
}

void main()
{
    ubyte[37] u;
    fill(u[], 7);
    foreach (x; u) if (x != 7) assert(0);
    fill(u[3 .. 5], 9);
    if (!(u[2] == 7 && u[3] == 9 && u[4] == 9 && u[5] == 7)) assert(0);
    int[50] a, b;
    foreach (i, ref x; a) x = cast(int)i * 3;
    copy(b[], a[]);
    if (!(b[49] == 147 && b[0] == 0 && b[17] == 51)) assert(0);
    S s;
    s.a[] = 4;
    s.b[] = 5;
    clear(s);
    if (!(s.a[4] == 0 && s.b[2] == 0)) assert(0);
    int[4] c = [1, 2, 3, 4], d;
    small(d, c);
    if (!(d[3] == 4 && d[0] == 1)) assert(0);
    long r;
    if (!(divmod(-17, 5, r) == -3 && r == -2)) assert(0);
    int ri;
    if (!(divmod32(-17, 5, ri) == -3 && ri == -2)) assert(0);
    uint ru;
    if (!(udivmod32(4000000000u, 7, ru) == 571428571 && ru == 3)) assert(0);
}
