// The values chosen where the ways of a ?: or an if meet share a register with what
// each way chooses, so no copy is left between them.
import core.math : sqrt;
import std.math : floor;

// the floor of a quotient clamped to a range of cells
int copies2_cellOf(float v, float o, float size, int n)
{
    int i = cast(int) floor((v + o) / size);
    return i < 0 ? 0 : (i >= n ? n - 1 : i);
}

struct Grid
{
    int w;
    float size;
    float ox, oy;
    ubyte[] cells;
}

// a walk along a line, stepping in x or in y as their next crossing comes first
bool copies3_clearLine(ref const Grid g, float ax, float ay, float bx, float by)
{
    float tx = (ax + g.ox) / g.size;
    float ty = (ay + g.oy) / g.size;
    const float dx = bx - ax, dy = by - ay;
    const float sx = dx != 0 ? 1 / dx : float.infinity;
    const float sy = dy != 0 ? 1 / dy : float.infinity;
    int steps = cast(int)(sqrt(dx * dx + dy * dy) / g.size) + 1;
    int x = cast(int) tx, y = cast(int) ty;
    while (steps-- > 0)
    {
        if (tx < ty)
        {
            tx += sx;
            ++x;
        }
        else
        {
            ty += sy;
            ++y;
        }
        if (g.cells[copies2_cellOf(x, 0, 1, g.w) + copies2_cellOf(y, 0, 1, g.w) * g.w])
            return false;
    }
    return true;
}

void main()
{
    assert(copies2_cellOf(2.5, 0, 1, 4) == 2);
    assert(copies2_cellOf(-2.5, 0, 1, 4) == 0);
    assert(copies2_cellOf(9.5, 0, 1, 4) == 3);
    assert(copies2_cellOf(1, 0.5, 0.5, 8) == 3);

    ubyte[16] cells;
    auto g = Grid(4, 1, 0, 0, cells[]);
    assert(copies3_clearLine(g, 0.5, 0.5, 3.5, 3.5));
    cells[5] = 1;
    assert(!copies3_clearLine(g, 0.5, 0.5, 3.5, 3.5));
}
