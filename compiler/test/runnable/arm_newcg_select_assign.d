/* REQUIRED_ARGS: -O
 */
// A ?: done as a select whose condition assigns a variable the arms read

pragma(inline, false) int ifloor(float x)
{
    int i;
    return (i = cast(int) x) > x ? i - 1 : i;
}

pragma(inline, false) int next(ref int k) { return ++k; }

pragma(inline, false) int countUp(int n)
{
    int k = 0, j;
    int s = 0;
    foreach (_; 0 .. n)
        s += (j = next(k)) > 2 ? j * 2 : j + 100;
    return s;
}

// a clamp of a value assigned in its first comparison, the arms selects themselves
pragma(inline, true) float clamp01(float x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
pragma(inline, false) float clampScaled(float a, float b, float c) { return clamp01((a - b) * c) * 3; }

// selects by a bool, a short and a call, each compared with 0
pragma(inline, false) int byBool(bool b, int x, int y) { return b ? x + 1 : y * 2; }
pragma(inline, false) long byShort(short s, long x) { return s ? x : -x; }
pragma(inline, false) bool odd(ref int calls, int v) { ++calls; return (v & 1) != 0; }
pragma(inline, false) int byCall(int v, ref int calls) { return odd(calls, v) ? calls * 10 : calls; }

void main()
{
    if (byBool(true, 4, 9) != 5 || byBool(false, 4, 9) != 18) assert(0);
    if (byShort(0x100, 7) != 7 || byShort(0, 7) != -7) assert(0);
    int calls;
    if (byCall(3, calls) != 10 || byCall(4, calls) != 2 || calls != 2) assert(0);
    if (clampScaled(1, 2, 0.5f) != 0 || clampScaled(2, 1, 0.25f) != 0.75f || clampScaled(3, 1, 2) != 3 ||
        clampScaled(1, 1, float.nan) == clampScaled(1, 1, float.nan))  // NaN is kept
        assert(0);
    if (ifloor(2.5f) != 2 || ifloor(-2.5f) != -3 || ifloor(-3.0f) != -3 || ifloor(0.0f) != 0)
        assert(0);
    if (countUp(5) != 101 + 102 + 6 + 8 + 10)
        assert(0);
}
