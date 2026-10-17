module a;
int first(int[] xs)
{
    import std.algorithm.sorting : sort;
    static immutable int[2] bias = [1, 2];
    xs.sort!((x, y) => x < y);
    return xs[0] + bias[0];
}
