/* REQUIRED_ARGS: -O
 */
// Floats of an HFA variable held in registers copied as integers

struct V { float x, y; }
struct S { int a; V p; V q; }

pragma(inline, false) void set(ref S s, float a, float b)
{
    V v = V(a * 2, b + 1);
    s.p = v;
    v.x += 1;
    s.q = v;
}

pragma(inline, false) V fromMemory(const(V)* p, const(V)* q, bool c)
{
    V v = *p;
    if (c)
        v = *q;
    v.x += 1;
    return v;
}

pragma(inline, false) bool same(V a, V b)
{
    return a == b;
}

void main()
{
    S s;
    set(s, 1.5f, -2);
    if (s.p.x != 3 || s.p.y != -1 || s.q.x != 4 || s.q.y != -1)
        assert(0);
    if (!same(V(1, 2), V(1, 2)) || same(V(1, 2), V(1, 3)))
        assert(0);
    V a = V(1, 2), b = V(5, 6);
    if (fromMemory(&a, &b, false) != V(2, 2) || fromMemory(&a, &b, true) != V(6, 6))
        assert(0);
}
