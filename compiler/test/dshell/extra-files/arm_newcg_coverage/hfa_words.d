// Homogeneous float aggregates made as integers: from a call that returns one in
// V registers, and from two 8 byte halves the optimizer split one into.
module hfa_words;

struct V2 { float x, y; }
struct V3 { float x, y, z; }
struct C4 { float r, g, b, a; }
struct D2 { double a, b; }

pragma(inline, false) V2 calleeV2(float k) { return V2(k, k + 1); }
pragma(inline, false) V3 calleeV3(float k) { return V3(k, k * 2, k * 3); }
pragma(inline, false) C4 calleeC4(float k) { return C4(k, -k, 0.5f, 1); }
pragma(inline, false) D2 calleeD2(double k) { return D2(k, k / 4); }
pragma(inline, false) double calleeUse(V2 a, V3 b, C4 c, D2 d)
{
    return a.x + 2 * a.y + 3 * b.x + 4 * b.y + 5 * b.z + 6 * c.r + 7 * c.g + 8 * c.b + 9 * c.a + 10 * d.a + 11 * d.b;
}

struct Holder
{
    float k;
    V3 eye() const { return calleeV3(k); }
}

double direct(float k)
{
    return calleeUse(calleeV2(k), calleeV3(k), calleeC4(k), calleeD2(k));
}

double viaMethod(const ref Holder h, bool twice)
{
    double t = calleeUse(calleeV2(1), h.eye, calleeC4(2), calleeD2(3));
    if (twice)
        t += calleeUse(calleeV2(1), h.eye, calleeC4(2), calleeD2(3));
    return t;
}

// halves of a color, as when one is copied a word at a time
C4 halves(ulong lo, ulong hi)
{
    union U { ulong[2] w; C4 c; }
    U u;
    u.w[0] = lo;
    u.w[1] = hi;
    return u.c;
}

double want(float k)
{
    return k + 2 * (k + 1) + 3 * k + 4 * (2 * k) + 5 * (3 * k) + 6 * k + 7 * -k + 8 * 0.5 + 9 * 1 + 10 * k +
        11 * (k / 4.0);
}

int main()
{
    assert(direct(2) == want(2));
    assert(direct(-1.5f) == want(-1.5f));
    const h = Holder(4);
    const one = 1 + 2 * 2 + 3 * 4 + 4 * 8 + 5 * 12 + 6 * 2 + 7 * -2 + 8 * 0.5 + 9 + 10 * 3 + 11 * 0.75;
    assert(viaMethod(h, false) == one);
    assert(viaMethod(h, true) == 2 * one);
    union U { ulong[2] w; C4 c; }
    U u;
    u.c = C4(1, 2, 3, 4);
    assert(halves(u.w[0], u.w[1]) == C4(1, 2, 3, 4));
    return 0;
}
