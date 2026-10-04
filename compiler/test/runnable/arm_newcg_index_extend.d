/* REQUIRED_ARGS: -O
 */
// A 32-bit index shared by several loads, extended by their addresses

pragma(inline, false) float twoArrays(const float[] a, const float[] b, int k0, int n)
{
    float s = 0;
    foreach (k; k0 .. n)
    {
        const i = k + 9;
        s += a[i] * b[i];
    }
    return s;
}

pragma(inline, false) long changed(const long[] a, int i)
{
    const long x = a[i];
    ++i;                // the index is a variable assigned after the shared extension
    return x + a[i - 1] * 10 + a[i];
}

pragma(inline, false) uint unsignedIndex(const uint[] a, uint i)
{
    return a[i + 1] + a[i + 1] * a[i + 2];
}

void main()
{
    float[20] a, b;
    foreach (j; 0 .. 20)
    {
        a[j] = j;
        b[j] = 2 * j;
    }
    if (twoArrays(a[], b[], 0, 3) != 9 * 18 + 10 * 20 + 11 * 22)
        assert(0);
    long[4] l = [1, 2, 3, 4];
    if (changed(l[], 1) != 2 + 20 + 3)
        assert(0);
    uint[4] u = [1, 2, 3, 4];
    if (unsignedIndex(u[], 1) != 3 + 3 * 4)
        assert(0);
}
