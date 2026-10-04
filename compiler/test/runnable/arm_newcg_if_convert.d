/* REQUIRED_ARGS: -O
 */
// Ifs that assign register variables cheap values done as selects

pragma(inline, false) size_t lowerBound(const(ulong)[] a, ulong key)
{
    size_t lo = 0, hi = a.length;
    while (lo < hi)
    {
        const mid = (lo + hi) / 2;
        if (a[mid] < key)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
}

pragma(inline, false) int both(int x, int y)
{
    int v = y;
    if (x > y)
        v = x * 2;
    else
        v = y - x;
    return v;
}

pragma(inline, false) int thenOnly(int x, int y)
{
    int v = 7;
    if (x < y)
        v = x + y;
    return v * 3;
}

pragma(inline, false) float elseOnly(float x, float y)
{
    float m = x;
    if (x >= y)
    {
    }
    else
        m = y;
    return m;
}

pragma(inline, false) int swapRead(int a, int b, bool c)
{
    // each arm reads what the other assigns
    if (c ? a < b : a > b)
        a = b + 1;
    else
        b = a + 1;
    return a * 100 + b;
}

pragma(inline, false) byte narrow(byte x, byte y)
{
    byte r = 1;
    if (x != y)
        r = cast(byte)(x - y);
    return r;
}

// an arm that is not an assignment, next to one that leaves the function
pragma(inline, false) bool eqArrays(const(string)[] lhs, const(string)[] rhs) @safe
{
    foreach (i; 0 .. lhs.length)
        if (lhs[i] != rhs[i])
            return false;
    return true;
}

void main()
{
    string[2] sa = ["ab", "c"];
    string[2] sb = ["ab", "d"];
    if (!eqArrays(sa[], sa[]) || eqArrays(sa[], sb[]))
        assert(0);
    const(ulong)[] a = [1, 3, 3, 5, 9];
    if (lowerBound(a, 0) != 0 || lowerBound(a, 3) != 1 || lowerBound(a, 4) != 3 || lowerBound(a, 10) != 5)
        assert(0);
    if (both(5, 2) != 10 || both(2, 5) != 3)
        assert(0);
    if (thenOnly(1, 2) != 9 || thenOnly(2, 1) != 21)
        assert(0);
    if (elseOnly(3, 2) != 3 || elseOnly(2, 3) != 3)
        assert(0);
    if (swapRead(1, 5, true) != 605 || swapRead(1, 5, false) != 102)
        assert(0);
    if (narrow(5, 5) != 1 || narrow(-100, 100) != cast(byte)-200)
        assert(0);
}
