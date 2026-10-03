// REQUIRED_ARGS: -O -release
// Loads and stores at base + index, scaled by the element size and extended from 32 bits.

pragma(inline, false) long sums(const(long)* a, const(int)* b, const(short)* c, const(byte)* d,
                                const(ubyte)* e, size_t i, uint j, int k)
{
    return a[i] + b[j] + c[k] + d[i] + e[j] + a[j] + b[k];
}

pragma(inline, false) double fsums(const(float)* f, const(double)* g, size_t i, uint j, int k)
{
    return f[i] + g[j] + f[k] + g[k];
}

pragma(inline, false) void stores(long* a, int* b, short* c, ubyte* d, float* f, double* g,
                                  size_t i, uint j, int k)
{
    a[i] = -5;
    b[j] = -6;
    c[k] = -7;
    d[i] = 200;
    f[j] = 1.5f;
    g[k] = 2.25;
}

void main()
{
    long[4] a = [1, 2, 3, 4];
    int[4] b = [10, 20, 30, 40];
    short[4] c = [-100, -200, -300, -400];
    byte[4] d = [-1, -2, -3, -4];
    ubyte[4] e = [250, 251, 252, 253];
    float[4] f = [0.5f, 1.5f, 2.5f, 3.5f];
    double[4] g = [0.25, 1.25, 2.25, 3.25];
    if (!(sums(a.ptr, b.ptr, c.ptr, d.ptr, e.ptr, 1, 2, 3) == 2 + 30 - 400 - 2 + 252 + 3 + 40)) assert(0);
    if (!(fsums(f.ptr, g.ptr, 0, 1, 3) == 0.5 + 1.25 + 3.5 + 3.25)) assert(0);
    int* bm = b.ptr + 2;
    if (!(sums(a.ptr, bm, c.ptr + 3, d.ptr, e.ptr, 0, 1, -1) == 1 + 40 - 300 - 1 + 251 + 2 + 20)) assert(0);
    stores(a.ptr, b.ptr, c.ptr, cast(ubyte*)d.ptr, f.ptr, g.ptr, 3, 1, 2);
    if (!(a[3] == -5 && b[1] == -6 && c[2] == -7 && d[3] == cast(byte)200 && f[1] == 1.5f && g[2] == 2.25)) assert(0);
    if (!(a[2] == 3 && b[2] == 30 && c[3] == -400)) assert(0);
}
