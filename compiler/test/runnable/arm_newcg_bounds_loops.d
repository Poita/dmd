/* REQUIRED_ARGS: -O
 */
// The bounds checks of the index of a loop over an array, and those that must stay

import core.exception : ArrayIndexError;

pragma(inline, false) int sum(const(int)[] a) @safe
{
    int t = 0;
    for (size_t i = 0; i < a.length; i++)
        t += a[i];
    return t;
}

pragma(inline, false) int sumOther(const(int)[] a, const(int)[] b) @safe
{
    // b's length is not the loop's
    int t = 0;
    for (size_t i = 0; i < a.length; i++)
        t += b[i];
    return t;
}

pragma(inline, false) int sumAhead(const(int)[] a) @safe
{
    // the index is changed before it is used
    int t = 0;
    for (size_t i = 0; i < a.length; )
    {
        i++;
        t += a[i];
    }
    return t;
}

void main()
{
    int[4] a = [1, 2, 3, 4];
    if (sum(a[]) != 10 || sum(a[0 .. 0]) != 0)
        assert(0);
    bool caught;
    try
        sumOther(a[], a[0 .. 2]);
    catch (ArrayIndexError e)
        caught = true;
    if (!caught)
        assert(0);
    caught = false;
    try
        sumAhead(a[]);
    catch (ArrayIndexError e)
        caught = true;
    if (!caught)
        assert(0);
}
