// Aggregates chosen by ?:, passed in registers and assigned.
module agg_cond;

struct V3 { float x, y, z; }
struct P { long a; int b; }
struct C { ubyte r, g, b, a; }

pragma(inline, false) float calleeV(V3 v) { return v.x + 2 * v.y + 3 * v.z; }
pragma(inline, false) long calleeP(P p) { return p.a * 10 + p.b; }

float pickV(const ref V3 a, const ref V3 b, float t)
{
    return calleeV(t > 0.5f ? a : b);
}

long pickP(const(P)* a, P b, bool c)
{
    return calleeP(c ? *a : b);
}

V3 retV(V3 a, bool c)
{
    return c ? a : V3(0, 1, 0);
}

C assignC(C a, C b, int k)
{
    C r = k > 0 ? a : b;
    r.a = 255;
    return r;
}

struct V2
{
    float x, y;
    V2 opBinary(string op : "*")(float s) const { return V2(x * s, y * s); }
}

struct Board
{
    bool haveBase;
    V2 base;
    V2 sum;
    uint n;
    V2 fallback;

    V2 basePos() const
    {
        if (haveBase)
            return base;
        if (n > 0)
            return sum * (1.0f / n);
        return fallback;
    }
}

pragma(inline, false) float calleeLen(V2 v) { return v.x * v.x + v.y * v.y; }

float baseOf(const ref Board bb)
{
    const base = bb.basePos;
    return calleeLen(base) + base.x - base.x;
}

int main()
{
    Board bb = Board(true, V2(1, 2), V2(6, 8), 2, V2(5, 0));
    assert(baseOf(bb) == 5);
    bb.haveBase = false;
    assert(baseOf(bb) == 25);
    bb.n = 0;
    assert(baseOf(bb) == 25);
    bb.fallback = V2(0, 3);
    assert(baseOf(bb) == 9);

    const a = V3(1, 2, 3), b = V3(4, 5, 6);
    assert(pickV(a, b, 1) == 14 && pickV(a, b, 0) == 32);
    const P pa = P(7, 8);
    assert(pickP(&pa, P(1, 2), true) == 78 && pickP(&pa, P(1, 2), false) == 12);
    assert(retV(a, true) == a && retV(a, false) == V3(0, 1, 0));
    assert(assignC(C(1, 2, 3, 4), C(5, 6, 7, 8), 1) == C(1, 2, 3, 255));
    assert(assignC(C(1, 2, 3, 4), C(5, 6, 7, 8), 0) == C(5, 6, 7, 255));
    return 0;
}
