// Conditional updates of a variable by an operation on it

uint sel2_countIf(const(int)[] a, int t)
{
    uint c = 0;
    foreach (v; a)
        if (v == t)
            ++c;
    return c;
}

long sel2_sumPositive(const(int)[] a)
{
    long s = 0;
    foreach (v; a)
        if (v > 0)
            s += v;
    return s;
}

ubyte sel0_bump(ubyte x, int c)
{
    if (c < 0)
        x += 7;
    return x;
}

int sel0_maskIf(int x, int m, bool b)
{
    if (b)
        x &= m;
    return x;
}

uint sel0_shiftIf(uint x, int c)
{
    if (c > 3)
        x <<= 3;
    else
        x ^= 0x55;
    return x;
}

long sel0_decIf(long x, long y)
{
    if (x > y)
        x--;
    return x;
}

int* sel0_stepIf(int* p, int c)
{
    if (c)
        p += 2;
    return p;
}

int sel0_mulIf(int x, int c)
{
    if (c != 5)
        x *= c;
    return x;
}

// the divisions may fault, so are not done unless chosen
int divIf(int x, int c)
{
    if (c != 0)
        x /= c;
    return x;
}

void main()
{
    static immutable int[] a = [3, -1, 3, 0, int.max, 3, int.min, 7];
    if (sel2_countIf(a, 3) != 3) assert(0);
    if (sel2_countIf(a, 9) != 0) assert(0);
    if (sel2_countIf(null, 3) != 0) assert(0);
    if (sel2_sumPositive(a) != 3L + 3 + int.max + 3 + 7) assert(0);
    if (sel0_bump(250, -1) != 1) assert(0);
    if (sel0_bump(250, 0) != 250) assert(0);
    if (sel0_maskIf(0xFF, 0x0F, true) != 0x0F) assert(0);
    if (sel0_maskIf(0xFF, 0x0F, false) != 0xFF) assert(0);
    if (sel0_shiftIf(0x8000_0001, 4) != 8) assert(0);
    if (sel0_shiftIf(1, 3) != 0x54) assert(0);
    if (sel0_decIf(long.min, long.min) != long.min) assert(0);
    if (sel0_decIf(long.min + 1, long.min) != long.min) assert(0);
    int[4] arr;
    if (sel0_stepIf(arr.ptr, 1) != arr.ptr + 2) assert(0);
    if (sel0_stepIf(arr.ptr, 0) != arr.ptr) assert(0);
    if (sel0_mulIf(int.max, 2) != -2) assert(0);
    if (sel0_mulIf(3, 5) != 3) assert(0);
    if (divIf(7, 0) != 7) assert(0);
    if (divIf(7, 2) != 3) assert(0);
}
