// Aggregates passed on the stack once the registers for them are used up:
// homogeneous float aggregates, small aggregates of integers, and the scalars
// after them, at the offsets the old code generator gives them.
module call_agg_stack;

struct V2 { float x, y; }
struct V3 { float x, y, z; }
struct V4 { float x, y, z, w; }
struct D2 { double a, b; }
struct P { long a, b; }
struct B2 { ubyte a, b; }
struct I1 { int a; }

__gshared double sink;

pragma(inline, false) double calleeHfa(V4 a, V4 b, V3 c, V2 d, V4 e, V2 f, int g, V3 h, float k)
{
    return a.x + 2 * a.w + 3 * b.y + 5 * c.z + 7 * d.y + 11 * e.x + 13 * e.w + 17 * f.x + 19 * f.y +
        23 * g + 29 * h.x + 31 * h.z + 37 * k;
}

pragma(inline, false) double calleeD2(D2 a, D2 b, D2 c, D2 d, D2 e, int f, D2 g)
{
    return a.a + 2 * b.b + 3 * c.a + 4 * d.b + 5 * e.a + 6 * e.b + 7 * f + 8 * g.a + 9 * g.b;
}

pragma(inline, false) long calleeGpr(P a, P b, P c, long d, P e, B2 f, int g, P h, I1 k, B2 m)
{
    return a.a + 2 * b.b + 3 * c.a + 4 * d + 5 * e.a + 6 * e.b + 7 * f.a + 8 * f.b + 9 * g +
        10 * h.a + 11 * h.b + 12 * k.a + 13 * m.a + 14 * m.b;
}

// from variables, from memory and from the results of calls
V4 make4(float s) { return V4(s, s + 1, s + 2, s + 3); }
V2 make2(float s) { return V2(s, -s); }
P makeP(long s) { return P(s, s * 3); }

double viaVars(float s)
{
    V4 a = make4(s), b = make4(s + 4);
    V3 c = V3(s, s * 2, s * 3);
    V2 d = make2(s);
    return calleeHfa(a, b, c, d, make4(s * 2), make2(s + 1), 3, V3(1, 2, 3), s);
}

double viaMemory(const(V4)[] v4, const(V3)[] v3, const(V2)[] v2)
{
    return calleeHfa(v4[0], v4[1], v3[0], v2[0], v4[2], v2[1], 4, v3[1], 0.5f);
}

long gprVars(long s)
{
    P a = makeP(s), b = makeP(s + 1);
    B2 f = B2(3, 4);
    return calleeGpr(a, b, makeP(s + 2), s, makeP(s + 3), f, -1, makeP(s + 4), I1(5), B2(6, 7));
}

long gprMemory(const(P)[] p, const(B2)[] b, const(I1)* k)
{
    return calleeGpr(p[0], p[1], p[2], 9, p[3], b[0], 2, p[4], *k, b[1]);
}

double d2Vars(double s)
{
    D2 a = D2(s, s + 1);
    return calleeD2(a, D2(2, 3), D2(4, 5), a, D2(6, 7), 8, D2(s, -s));
}

double hfaWant(V4 a, V4 b, V3 c, V2 d, V4 e, V2 f, int g, V3 h, float k)
{
    return a.x + 2 * a.w + 3 * b.y + 5 * c.z + 7 * d.y + 11 * e.x + 13 * e.w + 17 * f.x + 19 * f.y +
        23 * g + 29 * h.x + 31 * h.z + 37 * k;
}

int main()
{
    foreach (s; [1.0f, 2.5f, -3.0f])
        assert(viaVars(s) == hfaWant(make4(s), make4(s + 4), V3(s, s * 2, s * 3), make2(s), make4(s * 2),
            make2(s + 1), 3, V3(1, 2, 3), s));
    V4[3] v4 = [V4(1, 2, 3, 4), V4(5, 6, 7, 8), V4(9, 10, 11, 12)];
    V3[2] v3 = [V3(13, 14, 15), V3(16, 17, 18)];
    V2[2] v2 = [V2(19, 20), V2(21, 22)];
    assert(viaMemory(v4[], v3[], v2[]) == hfaWant(v4[0], v4[1], v3[0], v2[0], v4[2], v2[1], 4, v3[1], 0.5f));

    long want(long s)
    {
        return s + 2 * ((s + 1) * 3) + 3 * (s + 2) + 4 * s + 5 * (s + 3) + 6 * ((s + 3) * 3) + 7 * 3 + 8 * 4 +
            9 * -1 + 10 * (s + 4) + 11 * ((s + 4) * 3) + 12 * 5 + 13 * 6 + 14 * 7;
    }
    foreach (s; [1L, 100L, -7L])
        assert(gprVars(s) == want(s));
    P[5] ps = [P(1, 2), P(3, 4), P(5, 6), P(7, 8), P(9, 10)];
    B2[2] bs = [B2(11, 12), B2(13, 14)];
    I1 k = I1(15);
    assert(gprMemory(ps[], bs[], &k) == 1 + 2 * 4 + 3 * 5 + 4 * 9 + 5 * 7 + 6 * 8 + 7 * 11 + 8 * 12 + 9 * 2 +
        10 * 9 + 11 * 10 + 12 * 15 + 13 * 13 + 14 * 14);

    assert(d2Vars(1) == 1 + 2 * 3 + 3 * 4 + 4 * 2 + 5 * 6 + 6 * 7 + 7 * 8 + 8 * 1 + 9 * -1);
    return 0;
}
