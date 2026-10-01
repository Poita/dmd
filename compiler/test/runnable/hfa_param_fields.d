// The fields of floating point aggregates passed in registers, read from the
// parameters after other floating point computation.

struct V { float x = 0, y = 0, z = 0; }

V add(V a, V b) { return V(a.x + b.x, a.y + b.y, a.z + b.z); }

__gshared V o1, o2;

void f(V c, V s)
{
    const hx = s.x * 0.5f, hz = s.z * 0.5f;
    o1 = add(c, V(-hx, 0, -hz));
    o2 = add(c, V(hx, 0, hz));
}

struct D2 { double a = 0, b = 0; }

double g(D2 p, D2 q) { return p.a * 10 + p.b + q.a * 1000 + q.b * 100; }

void main()
{
    f(V(1, 2, 3), V(2, 4, 6));
    assert(o1 == V(0, 2, 0));
    assert(o2 == V(2, 2, 6));
    assert(g(D2(1, 2), D2(3, 4)) == 3412);
}
