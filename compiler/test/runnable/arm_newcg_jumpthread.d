/* REQUIRED_ARGS: -O -inline
 */
// Branches on values known where they are set: results of inlined functions with
// several returns, conditionals as conditions, chains of them, and comparisons
// of every size and sign

bool inRange(int x, int lo, int hi)
{
    if (x < lo) return false;
    if (x > hi) return false;
    return true;
}

int* pick(int* a, int* b, bool first)
{
    if (!a) return null;
    if (first) return a;
    return b;
}

int classify(int x)
{
    if (inRange(x, 0, 9)) return 1;
    if (inRange(x, 10, 99) && x % 2 == 0) return 2;
    return 3;
}

long sumKnown(int n)
{
    long s;
    foreach (i; 0 .. n)
    {
        bool small = i < 4;
        byte b = cast(byte)(small ? -1 : 1);
        ushort u = cast(ushort)(small ? 0xFFFF : 1);
        if (b < 0) s += 1;
        if (u > 0x8000) s += 10;
        if (cast(uint)b > 5) s += 100;     // -1 is large unsigned
        s += (small ? i : -i) > 0 ? 1000 : 0;
    }
    return s;
}

void main()
{
    assert(classify(5) == 1 && classify(42) == 2 && classify(43) == 3 && classify(-1) == 3);
    int a = 1, b = 2;
    assert(pick(&a, &b, true) is &a);
    assert(pick(&a, &b, false) is &b);
    assert(pick(null, &b, true) is null);
    int hits;
    foreach (i; -5 .. 120)
        if (inRange(i, 3, 7) || inRange(i, 100, 105))
            ++hits;
    assert(hits == 11);
    assert(sumKnown(10) == 4 * (1 + 10 + 100) + 1000 * 3);
}
