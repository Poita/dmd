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

void main()
{
    if (ifloor(2.5f) != 2 || ifloor(-2.5f) != -3 || ifloor(-3.0f) != -3 || ifloor(0.0f) != 0)
        assert(0);
    if (countUp(5) != 101 + 102 + 6 + 8 + 10)
        assert(0);
}
