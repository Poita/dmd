// REQUIRED_ARGS: -O -inline -release
// Small structs as values: HFAs and integer sized structs in registers,
// passed, returned, assigned and copied.

struct Vec2 { float x, y; }
struct NoiseD { float v = 0, dx = 0, dy = 0; }
struct Id { uint value; }
struct Mixed { long a; int b; }
struct Big { long[8] a; }

pragma(inline, false) Vec2 add(Vec2 a, Vec2 b) { return Vec2(a.x + b.x, a.y + b.y); }

pragma(inline, false) NoiseD sample(Vec2 p, float k)
{
    NoiseD r;
    r.v = p.x * k;
    r.dx = p.y + k;
    r.dy = p.x - p.y;
    return r;
}

pragma(inline, false) float sum(Vec2 p, int n)
{
    float s = 0;
    foreach (i; 0 .. n)
    {
        const d = sample(Vec2(p.x * i, p.y + i), 0.5f);
        s += d.v + d.dx * d.dy;
    }
    return s;
}

pragma(inline, false) Id next(Id a) { return Id(a.value + 1); }

pragma(inline, false) Mixed mix(long a, int b) { return Mixed(a * 2, b + 1); }

pragma(inline, false) void copyBig(ref Big d, ref const Big s) { d = s; }

pragma(inline, false) Vec2 pick(const(Vec2)* p, size_t i) { return p[i]; }

void main()
{
    const v = add(Vec2(1, 2), Vec2(3.5f, -1));
    if (!(v.x == 4.5f && v.y == 1)) assert(0);
    const n = sample(Vec2(2, 3), 4);
    if (!(n.v == 8 && n.dx == 7 && n.dy == -1)) assert(0);
    if (!(sum(Vec2(1, 2), 3) == -19.5f)) assert(0);
    if (!(next(Id(41)).value == 42)) assert(0);
    const m = mix(5, 6);
    if (!(m.a == 10 && m.b == 7)) assert(0);
    Big a, b;
    foreach (i; 0 .. 8) a.a[i] = i * 3;
    copyBig(b, a);
    if (!(b.a[7] == 21 && b.a[0] == 0 && b.a[3] == 9)) assert(0);
    Vec2[3] arr = [Vec2(1, 1), Vec2(2, 4), Vec2(3, 9)];
    if (!(pick(arr.ptr, 2).y == 9)) assert(0);
}
