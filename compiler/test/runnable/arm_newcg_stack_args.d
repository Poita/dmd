// REQUIRED_ARGS: -O -release
// Arguments beyond the argument registers are passed on the stack.

pragma(inline, false)
long ints(long a, int b, short c, byte d, long e, int f, uint g, ulong h, int i, short j, long k, byte l)
{
    return a + b * 2 + c * 3 + d * 4 + e * 5 + f * 6 + g * 7 + h * 8 + i * 9 + j * 10 + k * 11 + l * 12;
}

pragma(inline, false)
double floats(double a, float b, double c, float d, double e, float f, double g, float h,
              double i, float j, int k, double l)
{
    return a + b * 2 + c * 3 + d * 4 + e * 5 + f * 6 + g * 7 + h * 8 + i * 9 + j * 10 + k * 11 + l * 12;
}

pragma(inline, false)
size_t slices(int[] a, int[] b, int[] c, int[] d, int[] e)
{
    return a.length + b.length * 2 + c.length * 3 + d.length * 4 + e.length * 5 + e[0];
}

pragma(inline, false) long callInts(long x)
{
    return ints(x, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
}

pragma(inline, false) double callFloats(double x)
{
    return floats(x, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
}

pragma(inline, false) size_t callSlices(int[] s)
{
    return slices(s, s[0 .. 1], s[0 .. 2], s[0 .. 3], s[1 .. 4]);
}

void main()
{
    // 1 + 4 + 9 + 16 + 25 + 36 + 49 + 64 + 81 + 100 + 121 + 144
    if (!(callInts(1) == 650)) assert(0);
    if (!(callFloats(1) == 650)) assert(0);
    int[5] v = [7, 8, 9, 10, 11];
    // 5 + 2 + 6 + 12 + 15 + 8
    if (!(callSlices(v[]) == 48)) assert(0);
}
