// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Parameters whose registers are needed for other values before the
 * parameters are read
 */

struct Vec2 { float x, y; }

struct Field
{
    float half, step;

    pragma(inline, false) float at(Vec2 wp) const
    {
        return (wp.x + half) / step + wp.y;
    }

    pragma(inline, false) float at2(Vec2 wp, float k) const
    {
        const fx = (wp.x + half) / step;
        const fy = (wp.y + half) / step;
        return fx < 0 ? fy * k : fx * k;
    }
}

pragma(inline, false) long mix(long a, long b, long* p)
{
    const c = *p;           // loaded into the first parameter's register
    return c * 3 + a - b;
}

void main()
{
    const f = Field(1, 2);
    assert(f.at(Vec2(3, 5)) == 7);
    assert(f.at2(Vec2(3, 5), 2) == 4);
    assert(f.at2(Vec2(-3, 5), 2) == 6);
    long v = 4;
    assert(mix(10, 3, &v) == 19);
}
