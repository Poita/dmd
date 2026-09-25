// Stack passed parameters kept in registers by the optimizer are loaded in the prologue.
struct Raster { int w, h; }

bool shelfPack(T)(T[] rasters, size_t[] packed, int size, int gap, int[] xs, int[] ys)
{
    int shelfX = 0, shelfY = 0, shelfH = 0;
    foreach (n, i; packed)
    {
        const w = rasters[i].w + gap, h = rasters[i].h + gap;
        if (w > size || h > size)
            return false;
        if (shelfX + w > size)
        {
            shelfX = 0;
            shelfY += shelfH;
            shelfH = 0;
        }
        if (shelfY + h > size)
            return false;
        xs[n] = shelfX;
        ys[n] = shelfY;
        shelfX += w;
        if (h > shelfH)
            shelfH = h;
    }
    return true;
}

void main()
{
    auto r = [Raster(3, 4), Raster(5, 2), Raster(6, 6)];
    size_t[] order = [2, 0, 1];
    auto xs = new int[3], ys = new int[3];
    assert(shelfPack(r, order, 16, 1, xs, ys));
    assert(xs == [0, 7, 0] && ys == [0, 0, 7]);
    assert(!shelfPack(r, order, 8, 1, xs, ys));
    checkMixed();
}

double mixed(double a, double b, double c, double d, double e, double f, double g, double h,
        double i, float j, long k, long l, long m, long n, long o, long p, long q, long r,
        short s, ubyte t, long u)
{
    double acc = 0;
    foreach (x; 0 .. 3)
        acc += i * x + j + s * x + t + u;
    return acc + a + b + c + d + e + f + g + h + k + l + m + n + o + p + q + r;
}

void checkMixed()
{
    const v = mixed(1, 2, 3, 4, 5, 6, 7, 8, 9.5, 0.25f, 1, 1, 1, 1, 1, 1, 1, 1, -3, 200, 1000);
    assert(v == (9.5 * 3 + 0.25 * 3 + -3 * 3 + 200 * 3 + 1000 * 3) + 36 + 8);
}
