/* REQUIRED_ARGS: -O
 */
// The same float operations on the two halves of a pair, as may be done on both at once

import core.stdc.stdio;

struct Vec2 { float x, y; }
struct Vec4 { float r, g, b, a; }

pragma(inline, false) void integrate(Vec2[] pos, const Vec2[] vel, float dt)
{
    foreach (i, ref p; pos)
    {
        p.x += vel[i].x * dt;
        p.y += vel[i].y * dt;
    }
}

pragma(inline, false) Vec2 lerp2(Vec2 a, Vec2 b, float t)
{
    return Vec2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
}

pragma(inline, false) void blend(Vec4[] dst, const Vec4[] src, float k)
{
    foreach (i, ref d; dst)
    {
        d.r = d.r * (1 - k) + src[i].r * k;
        d.g = d.g * (1 - k) + src[i].g * k;
        d.b = d.b * (1 - k) + src[i].b * k;
        d.a = d.a * (1 - k) + src[i].a * k;
    }
}

// one half used on its own as well
pragma(inline, false) float scaleAndSum(ref Vec2 v, float s)
{
    v.x = v.x * s - 1;
    v.y = v.y * s - 2;
    return v.x + v.y;
}

// the halves alias what is stored between them
pragma(inline, false) void overlap(float[] a)
{
    foreach (i; 0 .. a.length - 2)
    {
        a[i + 1] = a[i] * 2 + 1;
        a[i + 2] = a[i + 1] * 3 - 1;
    }
}

// different operations on the halves
pragma(inline, false) void mixed(Vec2[] v)
{
    foreach (ref e; v)
    {
        e.x = e.x * 3 + 1;
        e.y = e.y / 3 - 1;
    }
}

// negation and absolute values
pragma(inline, false) void negAbs(Vec2[] v)
{
    foreach (ref e; v)
    {
        e.x = -(e.x * e.x) + (e.x < 0 ? -e.x : e.x);
        e.y = -(e.y * e.y) + (e.y < 0 ? -e.y : e.y);
    }
}

// sums of squares of the halves, loaded through an index
pragma(inline, false) size_t nearest(const Vec2[] pts, Vec2 c)
{
    size_t best;
    float bestD = float.max;
    foreach (i; 0 .. pts.length)
    {
        const dx = c.x - pts[i].x;
        const dy = c.y - pts[i].y;
        const d = dx * dx + dy * dy;
        if (d < bestD)
        {
            bestD = d;
            best = i;
        }
    }
    return best;
}

// a pair of variables set together on one path, and to constants on the other
pragma(inline, false) float setTwice(const float[] a, float s, bool again)
{
    float dx, dy;
    if (again)
    {
        dx = 7;
        dy = 9;
    }
    else
    {
        dx = a[0] * s;
        dy = a[1] * s;
    }
    return dx * a[2] + dy * a[3];
}

// a pair of variables carried around a loop, set apart but read together as a sum of squares
pragma(inline, false) float accumulate(const Vec2[] v, float k)
{
    float sx = 0, sy = 0, r = 0;
    foreach (e; v)
    {
        sx += e.x * k;
        sy -= e.y / k;
        r += 1 / (1 + (sx * sx + sy * sy));
    }
    return r + sx - sy;
}

// absolute values by negating what is negative, the larger of two, and their squares
pragma(inline, false) float worstSlope(const float[] h, size_t n)
{
    float worst = 0;
    foreach (y; 0 .. n - 1)
        foreach (x; 0 .. n - 1)
        {
            const h00 = h[y * n + x], h10 = h[y * n + x + 1];
            const h01 = h[(y + 1) * n + x], h11 = h[(y + 1) * n + x + 1];
            float gx = h10 - h00;
            if (gx < 0)
                gx = -gx;
            float gx2 = h11 - h01;
            if (gx2 < 0)
                gx2 = -gx2;
            if (gx2 > gx)
                gx = gx2;
            float gy = h01 - h00;
            if (gy < 0)
                gy = -gy;
            float gy2 = h11 - h10;
            if (gy2 < 0)
                gy2 = -gy2;
            if (gy2 > gy)
                gy = gy2;
            gx *= 1.5f;
            gy *= 1.5f;
            const s = gx * gx + gy * gy;
            if (s > worst)
                worst = s;
        }
    return worst;
}

uint bits(float f) { return *cast(uint*)&f; }

ulong digest(T)(const T[] a)
{
    ulong h = 1469598103934665603;
    foreach (ref e; a)
        foreach (f; (cast(const float*)&e)[0 .. T.sizeof / 4])
            h = (h ^ bits(f)) * 1099511628211;
    return h;
}

void main()
{
    Vec2[7] pos, vel;
    foreach (i; 0 .. 7)
    {
        pos[i] = Vec2(i * 0.1f, -i * 0.3f);
        vel[i] = Vec2(1.0f / (i + 1), i * 1.7f - 3);
    }
    foreach (_; 0 .. 5)
        integrate(pos[], vel[], 0.016f);
    const p = digest(pos[]);

    const l = lerp2(Vec2(1.5f, -2), Vec2(-3.25f, 8.5f), 0.3f);

    Vec4[5] d, s;
    foreach (i; 0 .. 5)
    {
        d[i] = Vec4(i * 0.25f, 1 - i * 0.125f, i * i * 0.01f, 0.5f);
        s[i] = Vec4(0.9f, i * 0.2f, 0.3f, i * 0.05f);
    }
    blend(d[], s[], 0.375f);
    const b = digest(d[]);

    Vec2 v = Vec2(1.25f, -0.75f);
    const sum = scaleAndSum(v, 3.5f);

    float[9] a = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    overlap(a[]);
    const o = digest(a[]);

    Vec2[4] m = [Vec2(1, 2), Vec2(-3, 4.5f), Vec2(0.1f, 0.2f), Vec2(7, -7)];
    mixed(m[]);
    const mx = digest(m[]);

    Vec2[4] n = [Vec2(-1.5f, 2), Vec2(0, -0.0f), Vec2(3, -4), Vec2(5.5f, 0.25f)];
    negAbs(n[]);
    const nx = digest(n[]);

    if (bits(accumulate(pos[], 0.75f)) != 0xc047d3a2)
        assert(0);
    float[16] hs = [0.5f, 1, -2, 0.25f, 3, -0.0f, 0, 7, 1.5f, -1, 2, 2, 0.125f, 4, -3, 1];
    if (bits(worstSlope(hs[], 4)) != 0x4354c400)
        assert(0);
    const float[4] st = [1, 2, 3, 4];
    if (setTwice(st[], 0.5f, false) != 0.5f * 3 + 1 * 4 || setTwice(st[], 0.5f, true) != 7 * 3 + 9 * 4)
        assert(0);
    if (nearest(pos[], Vec2(0.25f, -0.5f)) != 2 || nearest(vel[], Vec2(0.2f, 7)) != 6)
        assert(0);

    printf("%016llx %08x %08x %016llx %08x %08x %08x %016llx %016llx %016llx\n", p, bits(l.x), bits(l.y), b,
        bits(v.x), bits(v.y), bits(sum), o, mx, nx);
    if (p != 0x39e7e2840b363145 || bits(l.x) != 0x3d999990 || bits(l.y) != 0x3f933334 || b != 0x417069d5058e1988 ||
        bits(v.x) != 0x40580000 || bits(v.y) != 0xc0940000 || bits(sum) != 0xbfa00000 || o != 0x8bbc86517ee524b9 ||
        mx != 0x3e0c619866e83a8d || nx != 0x63661de4d74451e3)
        assert(0);
}
