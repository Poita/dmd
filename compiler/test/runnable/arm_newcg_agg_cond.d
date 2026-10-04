/* REQUIRED_ARGS: -O
 */
// ?: of aggregates passed in registers

struct V2 { float x, y; }
struct V3 { float x, y, z; }
struct P { int a, b; }

pragma(inline, false) V2 pick2(bool c, V2 a, V2 b) { const r = c ? a : b; return V2(r.x + 1, r.y); }
pragma(inline, false) V3 pick3(int c, V3 a) { V3 z = V3(0, 0, 0); return c > 0 ? a : z; }
pragma(inline, false) P pickP(int c, P a, P b) { P r = c < 0 ? a : b; r.b += 1; return r; }

void main()
{
    if (pick2(true, V2(1, 2), V2(3, 4)) != V2(2, 2) || pick2(false, V2(1, 2), V2(3, 4)) != V2(4, 4))
        assert(0);
    if (pick3(1, V3(1, 2, 3)) != V3(1, 2, 3) || pick3(0, V3(1, 2, 3)) != V3(0, 0, 0))
        assert(0);
    if (pickP(-1, P(1, 2), P(3, 4)) != P(1, 3) || pickP(1, P(1, 2), P(3, 4)) != P(3, 5))
        assert(0);
}
