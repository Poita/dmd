/* REQUIRED_ARGS: -O
 */
// Loops skipping on || chains of tests, some of what the loop does not change

pragma(inline, false) int cells(const bool[] g, int S, int N)
{
    int c;
    foreach (vy; 0 .. N)
        foreach (vx; 0 .. N)
        {
            const cx = vx / 4 - 1, cy = vy / 4 - 1;
            if (cx < 0 || cy < 0 || cx >= S || cy >= S)
                continue;
            if (vx < cx * 4 || vx > cx * 4 + 4 || vy < cy * 4 || vy > cy * 4 + 4)
                continue;
            c += g[cy * S + cx];
        }
    return c;
}

pragma(inline, false) float floats(const float[] v, float lo, float hi, float limit)
{
    float s = 0;
    foreach (x; v)
    {
        if (lo > limit || x < lo || hi < limit || x > hi)
            continue;
        s += x;
    }
    return s;
}

pragma(inline, false) int bitsAndSigns(const int[] v, uint flags, int k)
{
    int s;
    foreach (x; v)
    {
        if (flags & 2 || x < 0 || k < 0 || !(flags & 0x100))
            continue;
        s += x;
    }
    return s;
}

// the test of the outer loop's variable in the inner loop, and of a variable set in the outer loop
pragma(inline, false) long nested(int n, int m)
{
    long s;
    foreach (i; 0 .. n)
    {
        const odd = i & 1;
        foreach (j; 0 .. m)
        {
            if (odd != 0 || j == 3 || i > 5 || j > 7)
                continue;
            s += i * 100 + j;
        }
    }
    return s;
}

// a chain the loop also enters in its middle
pragma(inline, false) int entered(const int[] v, int a, int b)
{
    int s;
    foreach (x; v)
    {
        if (x == 1)
            goto Lmiddle;
        if (a > 3 || x > 50)
            continue;
    Lmiddle:
        if (b > 3 || x < 0)
            continue;
        s += x;
    }
    return s;
}

void main()
{
    auto g = new bool[](25);
    foreach (i, ref b; g)
        b = (i % 3) == 0;
    int reference;
    foreach (vy; 0 .. 20)
        foreach (vx; 0 .. 20)
        {
            const cx = vx / 4 - 1, cy = vy / 4 - 1;
            if (cx >= 0 && cy >= 0 && cx < 5 && cy < 5 && vx >= cx * 4 && vx <= cx * 4 + 4 &&
                vy >= cy * 4 && vy <= cy * 4 + 4)
                reference += g[cy * 5 + cx];
        }
    if (cells(g, 5, 20) != reference) assert(0);
    if (cells(g, 0, 20) != 0) assert(0);

    float[6] f = [1, 2, 3, 4, 5, 6];
    if (floats(f[], 2, 5, 3) != 2 + 3 + 4 + 5) assert(0);
    if (floats(f[], 4, 5, 3) != 0) assert(0);        // lo > limit
    if (floats(f[], 2, 2.5, 3) != 0) assert(0);      // hi < limit
    if (floats(f[], float.nan, 5, 3) != 1 + 2 + 3 + 4 + 5) assert(0);   // nothing compares with NaN

    int[5] v = [-2, 1, 3, 60, 7];
    if (bitsAndSigns(v[], 0x100, 0) != 1 + 3 + 60 + 7) assert(0);
    if (bitsAndSigns(v[], 0x102, 0) != 0) assert(0);
    if (bitsAndSigns(v[], 0x100, -1) != 0) assert(0);
    if (bitsAndSigns(v[], 0, 0) != 0) assert(0);

    long r;
    foreach (i; 0 .. 9)
        foreach (j; 0 .. 10)
            if (!(i & 1) && j != 3 && i <= 5 && j <= 7)
                r += i * 100 + j;
    if (nested(9, 10) != r) assert(0);

    int[6] w = [1, 2, 60, -1, 5, 1];
    if (entered(w[], 0, 0) != 1 + 2 + 5 + 1) assert(0);
    if (entered(w[], 4, 0) != 1 + 1) assert(0);       // only through the middle
    if (entered(w[], 0, 4) != 0) assert(0);
}
