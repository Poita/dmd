// A constant local of a floating point aggregate passed as an argument.
struct Vec2 { float x = 0, y = 0; }
struct World { float r = 100; }

pragma(inline, false)
bool blanked(const ref World w, Vec2 p) => p.x * p.x + p.y * p.y < w.r * w.r;

void main()
{
    World w;
    const at = Vec2(0, 0);
    assert(blanked(w, at));
    assert(blanked(w, Vec2(90, 0)));
    assert(!blanked(w, Vec2(110, 0)));
    const far = Vec2(200, 0);
    assert(!blanked(w, far));
}
