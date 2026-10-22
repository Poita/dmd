/* REQUIRED_ARGS: -release
 * PERMUTE_ARGS: -O -inline
 */
// Under -release the array bounds of @safe code are checked, also where the
// code is inlined into a function that does not check them.

import core.exception : RangeError;

int acc;

void sumThrough(int[] a) @safe
{
    for (size_t i = 0; i <= a.length; i++)
        acc += a[i];
}

int[] sliceTo(int[] a, size_t n) @safe
{
    return a[0 .. n];
}

void copyInto(int[] a, int[] b) @safe
{
    a[] = b[];
}

void fillTo(int[] a, size_t n) @safe
{
    a[0 .. n] = 7;
}

int unchecked(int[] a, size_t i) @system
{
    return a[i];
}

int readUnchecked(int[] a, size_t i) @safe
{
    return (() @trusted => unchecked(a, i))();
}

void main() @system
{
    int caught;
    foreach (n; 0 .. 3)
    {
        auto a = new int[n];
        try
            sumThrough(a);
        catch (RangeError e)
            caught++;
        try
            sliceTo(a, n + 1);
        catch (RangeError e)
            caught++;
        try
            copyInto(a, new int[n + 1]);
        catch (RangeError e)
            caught++;
        try
            fillTo(a, n + 2);
        catch (RangeError e)
            caught++;
        try
            sliceTo(a, n);
        catch (RangeError e)
            caught += 100;
    }
    assert(caught == 12);

    // a @system function inlined into a function that checks is still not checked
    int[] b = new int[8];
    assert(readUnchecked(b[0 .. 4], 5) == 0);
}
