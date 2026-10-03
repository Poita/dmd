// REQUIRED_ARGS: -O -inline -release
// HFA arguments the optimizer turned into plain values are passed in V registers,
// and aggregates too large for registers are returned through x8.

struct Vec2 { float x, y; }
struct Vec3 { float x, y, z; }
struct Big { long a, b, c, d; }

pragma(inline, false) float dot(Vec2 a, Vec2 b) { return a.x * b.x + a.y * b.y; }
pragma(inline, false) float len3(Vec3 v, float k) { return v.x + v.y * k + v.z * k * k; }
pragma(inline, false) Big make(long x) { return Big(x, x + 1, x * 2, -x); }
pragma(inline, false) long useBig(long x)
{
    const b = make(x);
    return b.a + b.b + b.c + b.d;
}

pragma(inline, false) float constArgs()
{
    return dot(Vec2(1, 2), Vec2(3, 4)) + len3(Vec3(1, 2, 3), 2) * 100;
}

pragma(inline, false) float mixedArgs(float s)
{
    const v = Vec2(0.5f, -2);
    return dot(v, Vec2(2, s));
}

void main()
{
    if (!(constArgs() == 1711)) assert(0);
    if (!(mixedArgs(1) == -1)) assert(0);
    if (!(useBig(5) == 5 + 6 + 10 - 5)) assert(0);
    const b = make(7);
    if (!(b.c == 14 && b.d == -7)) assert(0);
}
