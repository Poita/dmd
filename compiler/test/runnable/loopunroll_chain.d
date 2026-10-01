// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Loops with a constant number of iterations that can be unrolled:
 * signed loop variables, and bodies in more than one block.
 */

ulong readU64(const(ubyte)* p)
{
    ulong v;
    foreach (i; 0 .. 8)
        v |= cast(ulong) p[i] << (8 * i);
    return v;
}

int sumSquares()
{
    int s;
    for (int i = 2; i < 12; i += 2)
        s += i * i;
    return s;
}

int withContinue(const(int)[] a)
{
    int s;
    foreach (i; 0 .. 6)
    {
        if (a[i] < 0)
            continue;
        s += a[i];
    }
    return s;
}

int withBreak(const(int)[] a)
{
    int s;
    foreach (i; 0 .. 6)
    {
        if (a[i] == 0)
            break;
        s += a[i];
    }
    return s;
}

long countdown()
{
    long s = 0;
    foreach_reverse (i; 0 .. 5)
        s = s * 10 + i;
    return s;
}

int nested()
{
    int s;
    foreach (i; 0 .. 3)
        foreach (j; 0 .. 4)
            s += i * 10 + j;
    return s;
}

int main()
{
    ubyte[8] b = [1, 2, 3, 4, 5, 6, 7, 8];
    assert(readU64(b.ptr) == 0x0807060504030201);
    assert(sumSquares() == 4 + 16 + 36 + 64 + 100);
    int[6] a = [1, -2, 3, -4, 5, 6];
    assert(withContinue(a[]) == 15);
    int[6] z = [1, 2, 0, 4, 5, 6];
    assert(withBreak(z[]) == 3);
    assert(countdown() == 43210);
    assert(nested() == (0 + 10 + 20) * 4 + (0 + 1 + 2 + 3) * 3);
    return 0;
}
