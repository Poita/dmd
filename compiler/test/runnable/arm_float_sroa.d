// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Local structs of floats or doubles split into a variable per element:
 * element accesses, whole copies, constants, loads and stores, and whole
 * uses that go through memory.
 */

struct V2 { float x = 0, y = 0;
    V2 opBinary(string op)(const V2 r) const => mixin("V2(x " ~ op ~ " r.x, y " ~ op ~ " r.y)");
    V2 opBinary(string op)(float s) const => mixin("V2(x " ~ op ~ " s, y " ~ op ~ " s)");
}
struct V3 { float x = 0, y = 0, z = 0; }
struct V4 { float a = 0, b = 0, c = 0, d = 0; }
struct D2 { double x = 0, y = 0; }
struct D3 { double x = 0, y = 0, z = 0; }

pragma(inline, false) float use(V2 v) { return v.x * 10 + v.y; }
pragma(inline, false) V2 make(float a) { return V2(a, a + 1); }
pragma(inline, false) double useD(D2 d) { return d.x - d.y; }

float steer(const(V2)[] ps, V2 target, float k)
{
    float r = 0;
    foreach (p; ps)                 // load from memory
    {
        const d = target - p;       // element accesses
        const v = d * k + V2(1, 2);
        V2 w = v;                   // whole copy
        r += w.x * w.x + w.y * w.y;
    }
    return r;
}

float wholeUses(float a)
{
    V2 t = make(a);                 // whole write from a call
    t.x += 1;
    t.y *= 2;
    t.x -= t.y;
    float r = use(t);               // whole read as an argument
    t = V2(3, 4);                   // constant
    return r + t.x + t.y;
}

void store(V2* dst, float a)
{
    V2 t;
    t.x = a;
    t.y = a * 2;
    t.x += t.y;
    *dst = t;                       // store to memory
}

float sum3(const(V3)[] a)
{
    V3 s;
    foreach (v; a)
    {
        V3 t = v;
        s.x += t.x; s.y += t.y; s.z += t.z;
    }
    return s.x + 2 * s.y + 3 * s.z;
}

float sum4(V4 q)
{
    V4 t = q;
    t.a += t.d;
    t.b += t.c;
    return t.a * t.b;
}

double dbl(double a)
{
    D2 d;
    d.x = a;
    d.y = a / 2;
    d.x += d.y;
    D3 e = D3(1, 2, 3);
    e.z += d.x;
    return useD(d) + e.x + e.y + e.z;
}

float addressTaken(float a)
{
    V2 t = V2(a, a);
    V2* p = &t;
    p.y = 5;
    return t.x + t.y;
}

int main()
{
    V2[3] ps = [V2(1, 1), V2(2, 0), V2(0, 3)];
    assert(steer(ps[], V2(1, 1), 2) == 35);

    // t = (2, 3) -> (3, 6) -> (-3, 6); use: -30 + 6; then t = (3, 4)
    assert(wholeUses(2) == -24 + 7);

    V2 o;
    store(&o, 3);
    assert(o.x == 9 && o.y == 6);

    V3[2] a3 = [V3(1, 2, 3), V3(4, 5, 6)];
    assert(sum3(a3[]) == 5 + 14 + 27);

    assert(sum4(V4(1, 2, 3, 4)) == 5 * 5);

    // d = (3, 1) -> (4, 1)? d.x = 2 + 1 = 3; useD = 3 - 1 = 2; e = (1, 2, 6)
    assert(dbl(2) == 2 + 1 + 2 + 6);

    assert(addressTaken(2) == 7);
    return 0;
}
