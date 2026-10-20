// A static array of floating point aggregates filled with one value, then
// written element by element.
module hfa_fill;

struct Vec4 { float x, y, z, w; }
struct Vec2d { double x, y; }

struct Post
{
    int pad;
    Vec4[4] shock;
    Vec2d[3] centers;

    void shockwaves(const(Vec4)[] waves)
    {
        shock[] = Vec4(0, 0, 0, 0);
        foreach (i, w; waves)
            if (i < 4)
                shock[i] = w;
    }

    void reset(double v)
    {
        centers[] = Vec2d(v, -v);
    }
}

int main()
{
    Post p;
    foreach (ref s; p.shock)
        s = Vec4(9, 9, 9, 9);
    Vec4[2] w = [Vec4(1, 2, 3, 4), Vec4(5, 6, 7, 8)];
    p.shockwaves(w[]);
    if (p.shock[0] != Vec4(1, 2, 3, 4) || p.shock[1] != Vec4(5, 6, 7, 8) ||
        p.shock[2] != Vec4(0, 0, 0, 0) || p.shock[3] != Vec4(0, 0, 0, 0))
        assert(0);
    p.reset(1.5);
    foreach (c; p.centers)
        if (c.x != 1.5 || c.y != -1.5)
            assert(0);
    return 0;
}
