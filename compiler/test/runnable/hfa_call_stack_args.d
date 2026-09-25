// Homogeneous float aggregates returned by calls and passed on the stack.
struct Vec3 { float x = 0, y = 0, z = 0; }

Vec3 pt(float k) { return Vec3(k, k + 0.5f, k + 0.25f); }

struct Builder
{
    Vec3[8] got;
    uint colour;
    void quadN(Vec3 p0, Vec3 p1, Vec3 p2, Vec3 p3, Vec3 n0, Vec3 n1, Vec3 n2, Vec3 n3, uint abgr)
    {
        got = [p0, p1, p2, p3, n0, n1, n2, n3];
        colour = abgr;
    }
}

void main()
{
    Builder b;
    b.quadN(pt(1), pt(2), pt(3), pt(4), pt(5), pt(6), pt(7), pt(8), 0xff808080);
    foreach (i, v; b.got)
        assert(v == pt(i + 1));
    assert(b.colour == 0xff808080);
}
