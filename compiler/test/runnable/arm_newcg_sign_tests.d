/* REQUIRED_ARGS: -O
 */
// Branches on the sign of an integer

pragma(inline, false) int classify(int x) { if (x < 0) return -1; return x >= 0 ? 1 : 0; }
pragma(inline, false) int classifyLong(long x) { if (x < 0) return -1; return 1; }
pragma(inline, false) int classifyShort(short x) { if (x < 0) return -1; return 1; }
pragma(inline, false) int classifyByte(byte x) { if (x >= 0) return 1; return -1; }

// neighbors outside the grid skipped, as by grid code
pragma(inline, false) int sumNeighbors(const int[] g, int n, int x, int y)
{
    int s;
    foreach (d; [[-1, 0], [1, 0], [0, -1], [0, 1]])
    {
        const nx = x + d[0], ny = y + d[1];
        if (nx < 0 || ny < 0 || nx >= n || ny >= n)
            continue;
        s += g[ny * n + nx];
    }
    return s;
}

// branches on one bit
pragma(inline, false) int bits(uint x, ulong y)
{
    int r;
    if (x & 4)
        r += 1;
    if (!(x & 0x8000_0000))
        r += 2;
    if (y & (1UL << 40))
        r += 4;
    if (!(y & 1))
        r += 8;
    return r;
}

// the flags of the comparison with 0 used again after the branch
pragma(inline, false) int reuse(int x, int y)
{
    int r;
    if (x < 0)
        r = 1;
    r += x < 0 ? 10 : 20;
    return r + y;
}

// a function long enough for its branches to reach further than a test of a bit can
string longBody()
{
    string s;
    foreach (i; 0 .. 3000)
    {
        import std.conv : to;
        s ~= "if (a < 0) t += " ~ i.to!string ~ "; else t ^= b; b = b * 3 + 1;\n";
    }
    return s;
}
pragma(inline, false) long longFunction(long a, long b)
{
    long t;
    foreach (k; 0 .. 2)
    {
        if (k < 0)
            break;
        mixin(longBody());
        a = -a;
    }
    return t;
}

void main()
{
    static immutable int[] xs = [int.min, -100, -1, 0, 1, 100, int.max];
    foreach (x; xs)
    {
        if (classify(x) != (x < 0 ? -1 : 1)) assert(0);
        if (classifyLong(x) != (x < 0 ? -1 : 1)) assert(0);
        if (classifyLong(cast(long)x << 31) != (x < 0 ? -1 : 1)) assert(0);
        if (classifyShort(cast(short)x) != (cast(short)x < 0 ? -1 : 1)) assert(0);
        if (classifyByte(cast(byte)x) != (cast(byte)x < 0 ? -1 : 1)) assert(0);
        if (reuse(x, 3) != (x < 0 ? 1 + 10 + 3 : 20 + 3)) assert(0);
    }
    if (classifyLong(long.min) != -1 || classifyLong(long.max) != 1) assert(0);
    if (bits(4, 1UL << 40) != 1 + 2 + 4 + 8) assert(0);
    if (bits(0x8000_0000, 1) != 0) assert(0);
    if (bits(3, (1UL << 40) | 1) != 2 + 4) assert(0);

    int[9] g = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    if (sumNeighbors(g, 3, 0, 0) != 2 + 4) assert(0);
    if (sumNeighbors(g, 3, 1, 1) != 4 + 6 + 2 + 8) assert(0);
    if (sumNeighbors(g, 3, 2, 2) != 8 + 6) assert(0);

    long expect(long a, long b)
    {
        long t;
        foreach (k; 0 .. 2)
        {
            foreach (i; 0 .. 3000)
            {
                if (a < 0) t += i; else t ^= b;
                b = b * 3 + 1;
            }
            a = -a;
        }
        return t;
    }
    if (longFunction(5, 7) != expect(5, 7)) assert(0);
    if (longFunction(-5, 7) != expect(-5, 7)) assert(0);
}
