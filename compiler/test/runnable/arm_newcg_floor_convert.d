/* REQUIRED_ARGS: -O
 */
// Conversions to an integer rounding toward minus infinity, written as truncation and a fix up

pragma(inline, true) int ifloor(float x)
{
    const i = cast(int) x;
    return x < i ? i - 1 : i;
}

pragma(inline, true) int ifloorSwapped(float x)
{
    const i = cast(int) x;
    return i > x ? i - 1 : i;
}

pragma(inline, true) long lfloor(double x)
{
    const i = cast(long) x;
    return x < i ? i - 1 : i;
}

pragma(inline, false) int cell(float x) { return ifloor(x); }
pragma(inline, false) int cellSwapped(float x) { return ifloorSwapped(x); }
pragma(inline, false) long cellLong(double x) { return lfloor(x); }

pragma(inline, false) float frac(float x)
{
    const i = ifloor(x);
    return x - i;               // the truncated value used as well
}

pragma(inline, false) int truncUsed(float x, out int t)
{
    t = cast(int) x;
    return x < t ? t - 1 : t;
}

pragma(inline, false) int notFloor(float x)
{
    const i = cast(int) x;
    return x < i ? i - 2 : i;   // not the fix up of a floor
}

void main()
{
    static immutable float[] xs = [0.0f, -0.0f, 0.5f, -0.5f, 1.0f, -1.0f, 1.5f, -1.5f, 2.999f, -2.999f,
        123456.75f, -123456.75f, 8388607.5f, -8388607.5f, 1e9f, -1e9f, 3e9f, float.nan, float.infinity];
    static immutable int[] floors = [0, 0, 0, -1, 1, -1, 1, -2, 2, -3,
        123456, -123457, 8388607, -8388608, 1000000000, -1000000000, int.max, 0, int.max];
    foreach (k, x; xs)
    {
        if (cell(x) != floors[k]) assert(0);
        if (cellSwapped(x) != floors[k]) assert(0);
        if (cellLong(x) != (x != x ? 0 : x == float.infinity ? long.max : x == 3e9f ? 3000000000L : floors[k]))
            assert(0);
    }
    if (frac(-1.25f) != 0.75f || frac(2.5f) != 0.5f) assert(0);
    int t;
    if (truncUsed(-1.5f, t) != -2 || t != -1) assert(0);
    if (notFloor(-1.5f) != -3 || notFloor(1.5f) != 1) assert(0);
}
