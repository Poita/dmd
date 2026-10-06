/* REQUIRED_ARGS: -O
 */
// Adjacent elements loaded through an index, at 4 and 8 bytes

pragma(inline, false) float pairSum(const float[] h, size_t n, size_t x, size_t y)
{
    const a = h[y * n + x], b = h[y * n + x + 1];
    const c = h[(y + 1) * n + x], d = h[(y + 1) * n + x + 1];
    return (b - a) * 3 + (d - c);
}

pragma(inline, false) long pairDiff(const long[] v, size_t i)
{
    return v[i + 1] - v[i] * 2;
}

pragma(inline, false) int pairInts(const int[] v, uint i)
{
    return v[i] * 5 + v[i + 1];
}

void main()
{
    float[16] h;
    foreach (i, ref x; h)
        x = i * i * 0.5f;
    if (pairSum(h[], 4, 1, 2) != (h[10] - h[9]) * 3 + (h[14] - h[13])) assert(0);
    long[5] v = [1, -2, 1L << 40, 7, 9];
    if (pairDiff(v[], 1) != (1L << 40) + 4) assert(0);
    int[4] w = [3, -1, 8, 2];
    if (pairInts(w[], 2) != 42) assert(0);
}
