/* REQUIRED_ARGS: -O
 */
// Selects whose arms are selects

pragma(inline, false) float clamp01(float c) { return c < 0 ? 0 : c > 1 ? 1 : c; }
pragma(inline, false) int clampI(int x, int lo, int hi) { return x < lo ? lo : (x > hi ? hi : x); }

pragma(inline, false) int ifNested(int a, int b, int c)
{
    int v = 0;
    if (a > b)
        v = c < 0 ? -c : c;
    return v;
}

__gshared int counter;
pragma(inline, false) int bump() { return ++counter; }

pragma(inline, false) int sideEffectCond(int x)
{
    // the condition calls a function, so the arms cannot go first
    return bump() > 1 ? (x > 5 ? 5 : x) : -1;
}

void main()
{
    if (clamp01(-0.5f) != 0 || clamp01(1.5f) != 1 || clamp01(0.25f) != 0.25f)
        assert(0);
    if (clampI(-3, 0, 10) != 0 || clampI(13, 0, 10) != 10 || clampI(7, 0, 10) != 7)
        assert(0);
    if (ifNested(2, 1, -4) != 4 || ifNested(2, 1, 3) != 3 || ifNested(1, 2, 3) != 0)
        assert(0);
    if (sideEffectCond(9) != -1 || sideEffectCond(9) != 5 || sideEffectCond(2) != 2 || counter != 3)
        assert(0);
}
