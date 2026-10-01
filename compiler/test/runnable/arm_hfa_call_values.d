// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Floating point structs passed to calls from their elements, and assigned
 * the values calls return
 */

struct V2 { float x, y; }
struct V3 { float v = 0, dx = 0, dy = 0; }
struct V4 { double a, b, c, d; }

pragma(inline, false) V3 noise(V2 q, ulong seed) { return V3(q.x + seed, q.y * 2, q.x - q.y); }
pragma(inline, false) V2 swap(V2 q) { return V2(q.y, q.x); }
pragma(inline, false) double sum4(V4 v) { return v.a + v.b * 2 + v.c * 3 + v.d * 4; }

pragma(inline, false) float use(V2 p, float m, ulong seed)
{
    float s = 0, t = 0;
    foreach (o; 0 .. 4)
    {
        const q = V2(p.x * m, p.y * m);
        const n = noise(q, seed + o);
        s += n.v * m;
        t += n.dx * n.dy;
        m *= 2;
    }
    return s + t;
}

int counter;
pragma(inline, false) float next() { return ++counter; }

pragma(inline, false) float effects()
{
    const q = V2(next(), next() * 10);      // in order: 1, then 2
    const r = swap(q);
    return r.x + r.y * 100;
}

pragma(inline, false) double four(double k)
{
    V4 v;
    v.a = k;
    v.b = k + 1;
    v.c = k * 2;
    v.d = -k;
    return sum4(v);
}

void main()
{
    float s = 0, t = 0, m = 1.5f;
    foreach (o; 0 .. 4)
    {
        const q = V2(2 * m, 3 * m);
        const n = V3(q.x + (5 + o), q.y * 2, q.x - q.y);
        s += n.v * m;
        t += n.dx * n.dy;
        m *= 2;
    }
    assert(use(V2(2, 3), 1.5f, 5) == s + t);
    assert(effects() == 20 + 100);
    assert(four(2) == 2 + 3 * 2 + 4 * 3 - 2 * 4);
}
