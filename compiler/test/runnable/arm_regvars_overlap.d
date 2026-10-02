// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Many integer and floating point variables live at the same time, across
 * loops, branches and calls, each in its own register.
 */

pragma(inline, false) int touch(int x) { return x ^ 0x55; }

pragma(inline, false) long mix(int a, int b, int n, const(int)[] arr)
{
    int x = a + 1, y = b * 3, z = a ^ b, w = a - b, u = b + 7, v = a * a;
    long acc = 0;
    float f = a * 0.5f, g = b * 0.25f;
    double d = a + 0.125;
    foreach (i; 0 .. n)
    {
        x += y;
        y ^= z + i;
        z -= x;
        if (i & 1)
            w += touch(u);
        else
            u -= v;
        v = v * 3 + arr[i % arr.length];
        f = f * 0.5f + g;
        g -= f * 0.125f;
        d += f;
        acc += x + y + z + w + u + v;
    }
    return acc + cast(long)(f * 8) + cast(long)(g * 8) + cast(long) d;
}

long refMix(int a, int b, int n, const(int)[] arr)
{
    int x = a + 1, y = b * 3, z = a ^ b, w = a - b, u = b + 7, v = a * a;
    long acc = 0;
    float f = a * 0.5f, g = b * 0.25f;
    double d = a + 0.125;
    for (int i = 0; i < n; ++i)
    {
        x += y;
        y ^= z + i;
        z -= x;
        if (i & 1)
            w += u ^ 0x55;
        else
            u -= v;
        v = v * 3 + arr[i % arr.length];
        f = f * 0.5f + g;
        g -= f * 0.125f;
        d += f;
        acc += x + y + z + w + u + v;
    }
    return acc + cast(long)(f * 8) + cast(long)(g * 8) + cast(long) d;
}

void main()
{
    int[5] arr = [3, -1, 4, 1, -5];
    foreach (n; [0, 1, 2, 7, 33])
        foreach (a; [-3, 0, 5])
            assert(mix(a, a + 2, n, arr[]) == refMix(a, a + 2, n, arr[]));
}
