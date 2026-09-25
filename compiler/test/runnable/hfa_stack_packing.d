// Homogeneous float aggregates that no longer fit the floating point registers go on the stack.
struct Vec3
{
    float x = 0, y = 0, z = 0;
    float dot(const Vec3 r) const => x * r.x + y * r.y + z * r.z;
    Vec3 cross(const Vec3 r) const => Vec3(y * r.z - z * r.y, z * r.x - x * r.z, x * r.y - y * r.x);
}

struct Builder
{
    Vec3[5] got;
    uint colour;
    void box(Vec3 c, Vec3 ax, Vec3 ay, Vec3 az, Vec3 half, uint abgr)
    {
        got = [c, ax, ay, az, half];
        colour = abgr;
        assert(ax.cross(ay).dot(az) > 0);
    }
}

void box2(Vec3 c, Vec3 ax, Vec3 ay, Vec3 az, Vec3 half, uint abgr, ref Vec3[5] got)
{
    got = [c, ax, ay, az, half];
    assert(abgr == 7);
}

void main()
{
    Builder b;
    b.box(Vec3(1, 2, 3), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1), Vec3(4, 5, 6), 0xff00ff00);
    assert(b.got == [Vec3(1, 2, 3), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1), Vec3(4, 5, 6)]);
    assert(b.colour == 0xff00ff00);
    Vec3[5] g;
    box2(Vec3(1, 2, 3), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1), Vec3(4, 5, 6), 7, g);
    assert(g == [Vec3(1, 2, 3), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1), Vec3(4, 5, 6)]);
}
