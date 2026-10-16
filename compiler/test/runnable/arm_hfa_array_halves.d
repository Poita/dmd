/* REQUIRED_ARGS: -O -release -inline
 */
// An array of four floats copied from memory a pair of floats at a time keeps each
// float in its own element: its second element is read as itself, and it is passed
// whole as the four floats in order

struct Table
{
    ushort handle;
    float[64] cpu = 0;
}

pragma(inline, false) float weigh(const float[4] d)
{
    return d[0] + d[1] * 10 + d[2] * 100 + d[3] * 1000;
}

pragma(inline, false) float compose(ref const Table t, uint i)
{
    const float[4] r = t.cpu[i * 4 .. i * 4 + 4];
    const n = cast(uint) r[1];
    float s = 0;
    foreach (k; 0 .. n)
        s += weigh(r);
    return s;
}

pragma(inline, false) float second(ref const Table t, uint i)
{
    float[4] r = t.cpu[i * 4 .. i * 4 + 4];
    return r[1] * 10 + r[2];
}

void main()
{
    Table t;
    t.cpu[4 .. 8] = [1, 2, 3, 4];
    // asserts are kept under -release when they cannot be compiled out
    if (second(t, 1) != 23)
        assert(0);
    if (compose(t, 1) != 2 * 4321)
        assert(0);
}
