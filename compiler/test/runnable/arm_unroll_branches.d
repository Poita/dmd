// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline

/* Loops of a few iterations whose bodies branch, completely unrolled, and
 * look-alikes that are not.
 */

pragma(inline, false) bool[] canMove(const(bool)[] gentle, uint S, uint N)
{
    auto r = new bool[](N * N);
    foreach (vy; 0 .. N)
        foreach (vx; 0 .. N)
        {
            bool ok = true;
            const cxHi = cast(int) vx / 4;
            const cyHi = cast(int) vy / 4;
            foreach (dcy; -1 .. 1)
                foreach (dcx; -1 .. 1)
                {
                    const cx = cxHi + dcx;
                    const cy = cyHi + dcy;
                    if (cx < 0 || cy < 0 || cx >= S || cy >= S)
                        continue;
                    if (cast(int) vx < cx * 4 || cast(int) vx > cx * 4 + 4
                            || cast(int) vy < cy * 4 || cast(int) vy > cy * 4 + 4)
                        continue;
                    ok &= gentle[size_t(cy) * S + cx];
                }
            r[size_t(vy) * N + vx] = ok;
        }
    return r;
}

pragma(inline, false) float blur(const(float)[] snap, int N, int vx, int vy)
{
    float sum = 0;
    uint cnt;
    foreach (dy; -2 .. 3)
        foreach (dx; -2 .. 3)
        {
            const sx = vx + dx;
            const sy = vy + dy;
            if (sx < 0 || sy < 0 || sx >= N || sy >= N)
                continue;
            sum += snap[size_t(sy) * N + sx];
            cnt++;
        }
    return sum / cnt;
}

pragma(inline, false) int firstOver(const(int)[] a, int limit)
{
    // the break leaves the loop other than through its test
    int r = -1;
    foreach (i; 0 .. 4)
    {
        if (a[i] > limit)
        {
            r = i;
            break;
        }
    }
    return r;
}

pragma(inline, false) uint oddSum(uint x)
{
    uint r;
    for (uint i = 0; i < 6; i += 2)
    {
        if ((x >> i) & 1)
            r += i;
        else
            r += 100;
    }
    return r;
}

pragma(inline, false) int nested(int x)
{
    int r;
    foreach (i; 0 .. 3)
    {
        if (i == x)
            continue;
        foreach (j; 0 .. x)
            r += i * j;
    }
    return r;
}

pragma(inline, false) int tooLong(int x)
{
    int r;
    foreach (i; -5 .. 20)
    {
        if (i & x)
            continue;
        r += i;
    }
    return r;
}

void main()
{
    bool[] g = new bool[](16);
    foreach (i, ref x; g)
        x = (i * 7 % 3) != 0;
    auto r = canMove(g, 4, 17);
    uint h;
    foreach (i, x; r)
        h = h * 31 + x + cast(uint)i;
    assert(h == 1564403342);

    float[] f = new float[](100);
    foreach (i, ref x; f)
        x = i * 0.25f;
    float t = 0;
    foreach (y; 0 .. 10)
        foreach (x; 0 .. 10)
            t += blur(f, 10, x, y);
    assert(t == 1237.5f);

    assert(firstOver([1, 5, 9, 2], 4) == 1);
    assert(firstOver([1, 2, 3, 4], 9) == -1);
    assert(oddSum(0b10001) == 0 + 100 + 4);
    assert(oddSum(0) == 300);
    assert(nested(2) == 0 + 1);
    assert(nested(5) == (0 + 1 + 2 + 3 + 4) * 1 + (0 + 1 + 2 + 3 + 4) * 2);
    assert(tooLong(0) == 175);
    assert(tooLong(1) == -6 + 0 + 2 + 4 + 6 + 8 + 10 + 12 + 14 + 16 + 18);
}
