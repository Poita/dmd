// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Parameters of 2 to 4 floats or doubles, passed in V registers, used an
 * element at a time from those registers.
 */

struct V2 { float x, y; }
struct V3 { float x, y, z; }
struct V4 { float a, b, c, d; }
struct D2 { double x, y; }
struct D4 { double a, b, c, d; }

pragma(inline, false) float sum2(V2 p) { return p.x * 10 + p.y; }
pragma(inline, false) float f2(V2 p, ulong s) { return p.x * p.y + s; }
pragma(inline, false) float f3(int a, V3 p) { return p.x + p.y * p.z + a; }
pragma(inline, false) float f4(V4 q, float k) { q.a += k; q.d *= k; return q.a + q.b + q.c + q.d; }
pragma(inline, false) double fd(D2 p, D4 q) { return p.x - p.y + q.a * q.d - q.b / q.c; }
pragma(inline, false) float passOn(V2 p) { p.y += 1; return sum2(p) + p.x; }
pragma(inline, false) float addressTaken(V2 p) { V2* r = &p; r.x = 3; return p.x + p.y; }
pragma(inline, false) V2 swap(V2 p) { return V2(p.y, p.x); }

int main()
{
    assert(f2(V2(2, 3), 4) == 10);
    assert(f3(5, V3(1, 2, 3)) == 12);
    assert(f4(V4(1, 2, 3, 4), 2) == 3 + 2 + 3 + 8);
    assert(fd(D2(5, 1), D4(2, 6, 3, 4)) == 4 + 8 - 2);
    assert(passOn(V2(2, 3)) == 24 + 2);
    assert(addressTaken(V2(1, 5)) == 8);
    const s = swap(V2(1, 2));
    assert(s.x == 2 && s.y == 1);
    return 0;
}
