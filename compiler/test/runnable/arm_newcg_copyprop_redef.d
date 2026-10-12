/* REQUIRED_ARGS: -O
 */
// A copy whose last use is by the instruction redefining what it copies, as of
// the length of a slice sliced again by a stable remove

import std.algorithm.mutation, std.typecons;

__gshared ulong g = 3;

void main()
{
    int[] arr = [0, 1, 2, 3, 4, 5, 6];
    ulong i = g;
    assert(arr.remove!(SwapStrategy.stable)(tuple(i, i)).length == 7);
    foreach (k; 0 .. arr.length)
        assert(arr.remove!(SwapStrategy.stable)(tuple(k, k)) == [0, 1, 2, 3, 4, 5, 6]);
}
