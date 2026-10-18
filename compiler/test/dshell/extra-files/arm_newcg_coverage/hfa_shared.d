// Homogeneous float aggregates in memory read as integers, their bytes, where
// the optimizer shares one read between uses, passed in V registers.
module hfa_shared;

struct V2 { float x, y; }
struct V3 { float x, y, z; }
struct C4 { float r, g, b, a; }
struct D2 { double a, b; }

__gshared double total;

pragma(inline, false) void calleeA(V3 p, float m, int k) { total += p.x + 2 * p.y + 3 * p.z + m * k; }
pragma(inline, false) void calleeB(V3 p, float m) { total += 5 * p.x + 7 * p.y + 11 * p.z + m; }
pragma(inline, false) void calleeC(V2 p, C4 c, D2 d) { total += p.x + 2 * p.y + 3 * c.r + 4 * c.a + 5 * d.a + 6 * d.b; }
pragma(inline, false) float calleeH(float a) { return a * 0.5f; }

void explode(V2 g, float mag, bool extra)
{
    const ground = calleeH(g.x + g.y);
    V3 pos = V3(g.x, ground, g.y);
    calleeA(pos, mag, 3);
    if (extra)
        calleeB(pos, mag * 2);
    calleeB(pos, mag);
}

void colors(const(V2)* pv, const(C4)* pc, const(D2)* pd, int n)
{
    foreach (i; 0 .. n)
    {
        calleeC(*pv, *pc, *pd);
        if (i & 1)
            calleeC(*pv, *pc, *pd);
    }
}

void mixed(V2 g, float m, bool extra)
{
    V2 p = V2(g.x * 2, calleeH(g.y));
    C4 c = C4(m, calleeH(m), 3, 4);
    D2 d = D2(calleeH(1), m);
    calleeC(p, c, d);
    if (extra)
    {
        calleeC(p, c, d);
        p.x += 1;
        d.b -= 1;
    }
    calleeC(p, c, d);
}

double want(V2 g, float mag, bool extra)
{
    const ground = (g.x + g.y) * 0.5f;
    double t = g.x + 2 * ground + 3 * g.y + mag * 3;
    if (extra)
        t += 5 * g.x + 7 * ground + 11 * g.y + mag * 2;
    t += 5 * g.x + 7 * ground + 11 * g.y + mag;
    return t;
}

int main()
{
    foreach (extra; [false, true])
    {
        total = 0;
        explode(V2(1, 2), 4, extra);
        assert(total == want(V2(1, 2), 4, extra));
    }
    total = 0;
    V2 v = V2(1, 2);
    C4 c = C4(3, 4, 5, 6);
    D2 d = D2(7, 8);
    colors(&v, &c, &d, 3);
    assert(total == 4 * (1 + 4 + 9 + 24 + 35 + 48));
    foreach (extra; [false, true])
    {
        total = 0;
        mixed(V2(1, 2), 3, extra);
        const once = 2 + 2 * 1 + 3 * 3 + 4 * 4 + 5 * 0.5 + 6 * 3;
        assert(total == (extra ? 2 * once + once + 1 - 6 : once));
    }
    return 0;
}
