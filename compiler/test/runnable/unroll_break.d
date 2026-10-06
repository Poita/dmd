/* REQUIRED_ARGS: -O -inline
 */
// Short loops of a few iterations left early, their variables read after

pragma(inline, false) int firstOver(const int[] a, int t)
{
    int k;
    for (k = 0; k < 4; ++k)
        if (a[k] > t)
            break;
    return k;           // where the loop was left
}

pragma(inline, false) float smooth(const float[] src, size_t idx, float step)
{
    const c = src[idx];
    float sum = c, prev = c;
    foreach (k; 1 .. 4)
    {
        const v = src[idx + k];
        const d = v - prev;
        if (d > step || -d > step)
            break;
        prev = v;
        sum += v * k;
    }
    return sum;
}

pragma(inline, false) int nested(const int[] a)
{
    int s;
    foreach (i; 0 .. 3)
    {
        foreach (k; 0 .. 4)
        {
            if (a[i * 4 + k] < 0)
                break;
            if (a[i * 4 + k] == 0)
                continue;
            s += a[i * 4 + k] * (k + 1);
        }
    }
    return s;
}

// |d| > s written as d > s || -d > s, for numbers and NaN
pragma(inline, false) int beyond(float d, float s)
{
    if (d > s || -d > s)
        return 1;
    if (-d >= s || d >= s)
        return 2;
    return 3;
}

void main()
{
    if (beyond(2, 1) != 1 || beyond(-2, 1) != 1 || beyond(1, 1) != 2 || beyond(-1, 1) != 2 ||
        beyond(0.5f, 1) != 3 || beyond(float.nan, 1) != 3 || beyond(1, float.nan) != 3 ||
        beyond(-0.0f, 0) != 2 || beyond(float.infinity, 1e30f) != 1)
        assert(0);
    if (firstOver([1, 5, 9, 2], 4) != 1 || firstOver([1, 2, 3, 4], 9) != 4 || firstOver([7, 0, 0, 0], 0) != 0)
        assert(0);
    float[8] f = [1, 1.5f, 2, 9, 3, 3, 3, 3];
    if (smooth(f[], 0, 1) != 1 + 1.5f * 1 + 2 * 2) assert(0);
    if (smooth(f[], 4, 1) != 3 + 3 * 1 + 3 * 2 + 3 * 3 - 3 + 3) assert(0);
    int[12] a = [1, 2, -1, 4,   0, 3, 0, 5,   6, -2, 7, 8];
    if (nested(a[]) != (1 * 1 + 2 * 2) + (3 * 2 + 5 * 4) + 6 * 1) assert(0);
}
