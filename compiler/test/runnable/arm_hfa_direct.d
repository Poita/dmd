// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Homogeneous floating point aggregates passed from memory, returned into
 * memory, and copied between memory operands.
 */

struct F1 { float a; }
struct F2 { float x, y; }
struct F3 { float v, dx, dy; }
struct F4 { float a, b, c, d; }
struct D2 { double x, y; }
struct D3 { double x, y, z; }
struct D4 { double a, b, c, d; }

float sum(F1 p) { return p.a; }
float sum(F2 p) { return p.x + 2 * p.y; }
float sum(F3 p) { return p.v + 2 * p.dx + 3 * p.dy; }
float sum(F4 p) { return p.a + 2 * p.b + 3 * p.c + 4 * p.d; }
double sum(D2 p) { return p.x + 2 * p.y; }
double sum(D3 p) { return p.x + 2 * p.y + 3 * p.z; }
double sum(D4 p) { return p.a + 2 * p.b + 3 * p.c + 4 * p.d; }

F3 make3(F2 p, ulong s) { F3 r; r.v = p.x; r.dx = p.y; r.dy = s; return r; }
F4 make4(float k) { F4 r = F4(k, k + 1, k + 2, k + 3); return r; }
D3 makeD3(double k) { D3 r; r.x = k; r.y = -k; r.z = k * 2; return r; }
F2 viaPtr(const(F2)* p) { return p[1]; }
D2 viaRef(ref D2 d) { return d; }

void store3(F3* dst, F2 p) { *dst = make3(p, 7); }

int main()
{
    F1 f1 = F1(1.5f);
    assert(sum(f1) == 1.5f);
    F2[2] f2 = [F2(1, 2), F2(3, 4)];
    assert(sum(f2[1]) == 11);
    assert(sum(*&f2[0]) == 5);
    assert(sum(viaPtr(f2.ptr)) == 11);
    assert(sum(F2(f1.a * 2, 0.5f)) == 4);

    F3 n = make3(F2(1, 2), 3);
    assert(n.v == 1 && n.dx == 2 && n.dy == 3);
    assert(sum(n) == 14);
    F3 m = n;
    m.dy = 1;
    assert(sum(m) == 8 && n.dy == 3);
    F3 o;
    store3(&o, F2(5, 6));
    assert(o.v == 5 && o.dx == 6 && o.dy == 7);

    F4 q = make4(1);
    assert(sum(q) == 1 + 4 + 9 + 16);
    assert(sum(make4(0)) == 0 + 2 + 6 + 12);

    D2 d2 = D2(0.25, 0.5);
    assert(sum(viaRef(d2)) == 1.25);
    D3 d3 = makeD3(2);
    assert(sum(d3) == 2 - 4 + 12);
    D4 d4 = D4(1, 2, 3, 4);
    assert(sum(d4) == 30);
    return 0;
}
