// Constant floating point aggregates passed as arguments keep their register class.
struct Vec2 { float x = 0, y = 0; }
struct Grid { uint size = 64; float cell = 8; float half = 256; ubyte[] cells; }

pragma(inline, false)
ubyte at(const ref Grid g, ubyte team, Vec2 p)
{
    const col = cast(int)((p.x + g.half) / g.cell);
    const row = cast(int)((p.y + g.half) / g.cell);
    return cast(ubyte)(g.cells[row * g.size + col] + team);
}

bool seen(const ref Grid g, ubyte team, ubyte owner, Vec2 p) => owner == team || at(g, team, p) == 1;

void main()
{
    Grid g;
    g.cells = new ubyte[](64 * 64);
    g.cells[32 * 64 + 32] = 1;
    assert(seen(g, 0, 1, Vec2(0, 0)));
    assert(!seen(g, 0, 1, Vec2(8, 0)));
    assert(at(g, 0, Vec2(0, 0)) == 1);
}
