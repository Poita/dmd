/* REQUIRED_ARGS: -O -inline
 */
// Loops over immutable tables, which may be unrolled and their elements folded

immutable int[2][8] dirs = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]];
immutable uint[8] costs = [10, 10, 10, 10, 14, 14, 14, 14];
immutable byte[4] signedBytes = [-1, 127, -128, 5];
immutable short[4] shorts = [-300, 300, -32768, 32767];
immutable float[4] weights = [0.25f, -1.5f, 3.0f, -0.0f];
immutable double[3] doubles = [1e300, -2.5, 0.125];
immutable long[3] longs = [-1L << 40, 7, long.max];

pragma(inline, false) int neighbours(const(uint)[] g, int x, int y)
{
    int s;
    foreach (k; 0 .. 8)
    {
        const nx = x + dirs[k][0];
        const ny = y + dirs[k][1];
        if (nx < 0 || ny < 0 || nx >= 4 || ny >= 4)
            continue;
        if (dirs[k][0] != 0 && dirs[k][1] != 0)
            s += 1000;
        s += g[ny * 4 + nx] + costs[k];
    }
    return s;
}

pragma(inline, false) int sumBytes(int bias) { int s; foreach (k; 0 .. 4) s += signedBytes[k] * (k + bias); return s; }
pragma(inline, false) int sumShorts() { int s; foreach (k; 0 .. 4) s += shorts[k]; return s; }
pragma(inline, false) float dotWeights(float a) { float s = 0; foreach (k; 0 .. 4) s += weights[k] * (a + k); return s; }
pragma(inline, false) double sumDoubles() { double s = 0; foreach (k; 0 .. 3) s += doubles[k] * 2; return s; }
pragma(inline, false) long sumLongs() { long s; foreach (k; 0 .. 3) s ^= longs[k]; return s; }

void main()
{
    uint[16] g;
    foreach (i, ref v; g)
        v = cast(uint)(i * 3);
    // (1, 1): all eight neighbours inside
    int expect;
    foreach (k; 0 .. 8)
        expect += (dirs[k][0] && dirs[k][1] ? 1000 : 0) + (1 + dirs[k][1]) * 12 + (1 + dirs[k][0]) * 3 + costs[k];
    if (neighbours(g[], 1, 1) != expect) assert(0);
    // (0, 0): only right, down and down-right
    if (neighbours(g[], 0, 0) != (g[1] + 10) + (g[4] + 10) + (1000 + g[5] + 14)) assert(0);
    if (sumBytes(1) != -1 * 1 + 127 * 2 - 128 * 3 + 5 * 4) assert(0);
    if (sumShorts() != -300 + 300 - 32768 + 32767) assert(0);
    if (dotWeights(1) != 0.25f * 1 - 1.5f * 2 + 3.0f * 3 + -0.0f * 4) assert(0);
    if (sumDoubles() != 2e300 - 5 + 0.25) assert(0);
    if (sumLongs() != ((-1L << 40) ^ 7 ^ long.max)) assert(0);
}
