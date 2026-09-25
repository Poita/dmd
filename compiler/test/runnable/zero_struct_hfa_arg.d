// Floating point aggregates held in zero initialized locals passed as arguments.
struct Vec2 { float x = 0, y = 0; }
struct Vec3 { double x = 0, y = 0, z = 0; }

Vec2 sub(Vec2 a, Vec2 b, float t) { return Vec2(b.x - a.x + t, b.y - a.y + t); }
double sum3(Vec3 a, Vec3 b) { return a.x + a.y + a.z + b.x + b.y + b.z; }

void main()
{
    const a = Vec2(0, 0), b = Vec2(3, 4);
    const r = sub(a, b, 2);
    assert(r.x == 5 && r.y == 6);

    const c = Vec2(1, 2);
    const s = sub(c, b, 0);
    assert(s.x == 2 && s.y == 2);

    const z = Vec3(0, 0, 0), w = Vec3(1, 2, 3);
    assert(sum3(z, w) == 6);
    assert(sum3(w, z) == 6);
}
