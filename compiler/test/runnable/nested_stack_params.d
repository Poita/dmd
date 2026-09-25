// Stack passed floating point aggregates read by nested functions.
struct Vec3 { float x = 0, y = 0, z = 0; }

Vec3 seg(Vec3 center, Vec3 axis, float r, float t, float a0, float a1, uint segs, uint sides, uint abgr)
{
    Vec3 at(float k)
    {
        return Vec3(center.x + axis.x * k, center.y + r, center.z + t + a0 + a1 + segs + sides + abgr);
    }
    return at(2);
}

void main()
{
    auto v = seg(Vec3(1, 2, 3), Vec3(4, 5, 6), 7, 8, 9, 10, 1, 2, 3);
    assert(v == Vec3(9, 9, 3 + 8 + 9 + 10 + 1 + 2 + 3));
}
