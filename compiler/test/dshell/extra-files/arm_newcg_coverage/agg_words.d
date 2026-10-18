// Aggregates made from constants and from pairs of 8 byte halves, returned,
// assigned, and passed in registers and on the stack.
module agg_words;

struct P { long a, b; }
struct Q { int a; float b; }
struct C { ubyte r, g, b, a; }
struct D2 { double x, y; }
struct V4 { float x, y, z, w; }
struct V2 { float x, y; }

P makeP(long s) { return P(s, s * 3); }
P zeroP() { return P.init; }
P constP() { return P(5, -6); }
Q constQ() { return Q(7, 1.5f); }
C constC() { return C(1, 2, 3, 4); }
D2 constD2() { return D2(0.25, -8); }
D2 zeroD2() { return D2.init; }
V4 constV4() { return V4(1, 2, 3, 4); }
V2 constV2() { return V2(-1, 0.5f); }
D2 pairD2(double a, double b) { return D2(a + 1, b * 2); }

pragma(inline, false) long calleeP(P a, P b, P c, P d, Q e, C f) { return a.a + 2 * b.b + 3 * c.a + 4 * d.b + 5 * e.a + 6 * f.g; }
pragma(inline, false) double calleeF(D2 a, V4 b, V2 c, D2 d) { return a.x + 2 * a.y + 3 * b.z + 4 * b.w + 5 * c.x + 6 * c.y + 7 * d.y; }

long passConsts(long s) { return calleeP(P(1, 2), makeP(s), P.init, P(3, 4), Q(5, 6), C(7, 8, 9, 10)); }
double passFloats() { return calleeF(D2(1, 2), V4(3, 4, 5, 6), V2(7, 8), D2.init); }

__gshared P gp;
__gshared D2 gd;
__gshared V4 gv;
void assignConsts() { gp = P(11, 12); gd = D2(13, 14); gv = V4(15, 16, 17, 18); }

int main()
{
    assert(makeP(5) == P(5, 15));
    assert(zeroP() == P(0, 0));
    assert(constP() == P(5, -6));
    assert(constQ() == Q(7, 1.5f));
    assert(constC() == C(1, 2, 3, 4));
    assert(constD2() == D2(0.25, -8));
    assert(zeroD2() == D2(0, 0));
    assert(constV4() == V4(1, 2, 3, 4));
    assert(constV2() == V2(-1, 0.5f));
    assert(pairD2(2, 3) == D2(3, 6));
    assert(passConsts(10) == 1 + 2 * 30 + 0 + 4 * 4 + 5 * 5 + 6 * 8);
    assert(passFloats() == 1 + 2 * 2 + 3 * 5 + 4 * 6 + 5 * 7 + 6 * 8 + 0);
    assignConsts();
    assert(gp == P(11, 12) && gd == D2(13, 14) && gv == V4(15, 16, 17, 18));
    return 0;
}
