/* REQUIRED_ARGS: -O
 */
// The same index checked again, read and written, and one out of bounds caught

import core.exception : RangeError;

pragma(inline, false) @safe void relax(uint[] costs, size_t i, uint c)
{
    if (c < costs[i])
        costs[i] = c;
}

pragma(inline, false) @safe void swapUp(ulong[] items, size_t i)
{
    while (i > 0)
    {
        const p = (i - 1) / 2;
        if (items[p] <= items[i])
            break;
        const t = items[p];
        items[p] = items[i];
        items[i] = t;
        i = p;
    }
}

pragma(inline, false) @safe int twice(const int[] a, size_t i, size_t j)
{
    return a[i] + a[j] + a[i] * a[j];
}

void main()
{
    uint[4] costs = [9, 9, 9, 9];
    relax(costs[], 2, 5);
    relax(costs[], 2, 7);
    if (costs != [9, 9, 5, 9]) assert(0);
    ulong[6] h = [1, 4, 3, 7, 8, 0];
    swapUp(h[], 5);
    if (h[0] != 0 || h[2] != 1 || h[5] != 3) assert(0);
    int[3] a = [2, 3, 4];
    if (twice(a[], 0, 2) != 2 + 4 + 8) assert(0);
    bool caught;
    try
        twice(a[], 1, 3);
    catch (RangeError)
        caught = true;
    if (!caught) assert(0);
    caught = false;
    try
        relax(costs[], 4, 1);
    catch (RangeError)
        caught = true;
    if (!caught) assert(0);
}
