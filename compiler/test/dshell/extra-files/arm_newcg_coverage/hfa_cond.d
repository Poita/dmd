// Floating point aggregates chosen by ?:, inlined into their callers.
module hfa_cond;

import core.math : sqrt;

struct Vec2
{
    float x, y;
    Vec2 opBinary(string op : "+")(Vec2 r) const { return Vec2(x + r.x, y + r.y); }
}
struct Vec3 { float x, y, z; }

Vec3 normalized(Vec3 v)
{
    const len = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    return len > 0 ? Vec3(v.x / len, v.y / len, v.z / len) : Vec3(0, 0, 0);
}

Vec2 halfOrZero(Vec2 v, bool b) { return b ? Vec2(v.x / 2, v.y / 2) : Vec2(0, 0); }

Vec3 axis(int k)
{
    Vec3 r = normalized(Vec3(k, 0.5f, 0));
    return r;
}

Vec2 half(Vec2 v, bool b)
{
    Vec2 r = halfOrZero(v, b);
    return r;
}

pragma(inline, false)
float sum(Vec3 a, Vec3 b, Vec2 c) { return a.x + a.y + a.z + 10 * (b.x + b.y + b.z) + 100 * (c.x + c.y); }

float passed(int k, bool b)
{
    return sum(normalized(Vec3(k, 0.5f, 0)), normalized(Vec3(0, 0, k)), halfOrZero(Vec2(3, 5), b));
}

struct Unit { Vec2 pos; Vec2 vel; }

pragma(inline, false)
float len2(Vec2 v) { return v.x * v.x + v.y * v.y; }

Vec2 lead(ref const Unit u, ref const Vec2 at, float k)
{
    return k > 0 ? at + u.vel : at;
}

float aim(ref const Unit u, ref const Vec2 at, float k)
{
    const p = lead(u, at, k);
    return len2(p);
}

int main()
{
    auto u = Unit(Vec2(0, 0), Vec2(1, 2));
    auto at = Vec2(2, 1);
    if (aim(u, at, 1) != 18 || aim(u, at, -1) != 5)
        assert(0);
    if (passed(0, true) != 1 + 0 + 400)
        assert(0);
    if (passed(0, false) != 1)
        assert(0);
    const d = passed(2, false) - (2.5f / sqrt(4.25f) + 10);
    if (d > 1e-5f || d < -1e-5f)
        assert(0);
    const a = axis(0);
    if (a.x != 0 || a.y != 1 || a.z != 0)
        assert(0);
    const z = normalized(Vec3(0, 0, 0));
    if (z.x != 0 || z.y != 0 || z.z != 0)
        assert(0);
    const h = half(Vec2(3, 5), true);
    if (h.x != 1.5f || h.y != 2.5f)
        assert(0);
    const n = half(Vec2(3, 5), false);
    if (n.x != 0 || n.y != 0)
        assert(0);
    return 0;
}
