/* REQUIRED_ARGS: -O
 */
// Aggregates passed in integer registers given as integer values

struct Id { uint v; }
struct P { int a, b; }
struct Q { long a, b; }

pragma(inline, false) uint idOf(Id i) { return i.v * 3; }
pragma(inline, false) int sumP(P p) { return p.a - p.b; }
pragma(inline, false) long sumQ(Q q) { return q.a - q.b; }

pragma(inline, false) int calls(uint x, int y, long z)
{
    const r = idOf(Id(x + 1));
    const s = sumP(P(y, y * 2));
    const t = sumQ(Q(z, z * 3));
    return cast(int)(r + s + t);
}

void main()
{
    if (calls(4, 5, 7) != 15 - 5 - 14)
        assert(0);
}
