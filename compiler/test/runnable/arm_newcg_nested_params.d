// REQUIRED_ARGS: -O -release
// Parameters a nested function refers to: a reference and a const value read by both.

struct Grid { int w; int[] cells; }

pragma(inline, false) int apply(scope int delegate(int) f, int x) { return f(x); }

pragma(inline, false) int sumRow(ref const Grid g, const int row, int k)
{
    int s;
    foreach (x; 0 .. g.w)
        s += g.cells[row * g.w + x];
    // the lambda reads g and row from the frame
    s += apply((int v) => g.cells[row * g.w + v] * k, 1);
    foreach (x; 0 .. g.w)
        s += g.cells[row * g.w + x] * 2;
    return s;
}

void main()
{
    Grid g;
    g.w = 4;
    g.cells = [1, 2, 3, 4, 5, 6, 7, 8];
    // row 1: 5+6+7+8 = 26, lambda 6*10 = 60, 2*26 = 52
    if (!(sumRow(g, 1, 10) == 138)) assert(0);
}
