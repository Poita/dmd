// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Functions that call nothing, without a frame record, called from functions
 * that throw and catch around them
 */

pragma(inline, false) int leafAdd(int a, int b) { return a + b * 3; }
pragma(inline, false) float leafMix(float a, float b, float c) { return (a + c) / b + (b - c) * a; }
pragma(inline, false) long leafLoop(const(long)[] xs)
{
    long s;
    foreach (x; xs)
        s = s * 31 + x;
    return s;
}

pragma(inline, false) int thrower(int n)
{
    const v = leafAdd(n, 2);
    if (v > 10)
        throw new Exception("big");
    return v;
}

pragma(inline, false) int catcher(int n)
{
    try
        return thrower(n) + leafAdd(1, 1);
    catch (Exception e)
        return -leafAdd(n, 0);
}

int recurse(int n) { return n <= 0 ? leafAdd(0, 1) : recurse(n - 1) + leafAdd(n, n); }

void main()
{
    assert(leafAdd(1, 2) == 7);
    assert(leafMix(1, 2, 3) == 2 - 1);
    assert(leafLoop([1, 2, 3]) == (1 * 31 + 2) * 31 + 3);
    assert(catcher(1) == 7 + 4);
    assert(catcher(9) == -9);
    assert(recurse(3) == 3 + 4 * 3 + 4 * 2 + 4 * 1);
}
