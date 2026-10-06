/* REQUIRED_ARGS: -O
 */
// Copies and fills of arrays, short and long, whole and in part

pragma(inline, false) void copyFloats(float[] dst, const float[] src) { dst[] = src[]; }
pragma(inline, false) void fillFloats(float[] dst, float v) { dst[] = v; }
pragma(inline, false) void fillBytes(ubyte[] dst, ubyte v) { dst[] = v; }
pragma(inline, false) void copyBytes(ubyte[] dst, const ubyte[] src) { dst[] = src[]; }

void main()
{
    foreach (n; [0, 1, 3, 7, 8, 9, 31, 63, 64, 65, 100, 255, 256, 257, 1000, 4099])
    {
        auto a = new float[](n + 2), b = new float[](n + 2);
        foreach (i, ref x; a)
            x = i * 0.5f + 1;
        b[] = -1;
        copyFloats(b[1 .. n + 1], a[1 .. n + 1]);
        if (b[0] != -1 || b[n + 1] != -1) assert(0);
        foreach (i; 1 .. n + 1)
            if (b[i] != a[i]) assert(0);
        fillFloats(b[1 .. n + 1], 0);
        foreach (i; 1 .. n + 1)
            if (b[i] != 0) assert(0);
        fillFloats(b[1 .. n + 1], 2.5f);
        foreach (i; 1 .. n + 1)
            if (b[i] != 2.5f) assert(0);
        if (b[0] != -1 || b[n + 1] != -1) assert(0);

        auto c = new ubyte[](n + 2), d = new ubyte[](n + 2);
        foreach (i, ref x; c)
            x = cast(ubyte)(i * 7 + 3);
        d[] = 0xEE;
        copyBytes(d[1 .. n + 1], c[1 .. n + 1]);
        foreach (i; 1 .. n + 1)
            if (d[i] != c[i]) assert(0);
        fillBytes(d[1 .. n + 1], 0x5A);
        foreach (i; 1 .. n + 1)
            if (d[i] != 0x5A) assert(0);
        if (d[0] != 0xEE || d[n + 1] != 0xEE) assert(0);
    }
}
