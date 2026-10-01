// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// Branches on a value compared with zero

struct U { byte a; bool b; int c; long d; ushort e; int* p; }

pragma(inline, false) int loads(const U* u)
{
    int n;
    if (u.a) n |= 1;
    if (u.b) n |= 2;
    if (u.c) n |= 4;
    if (!u.d) n |= 8;
    if (u.e) n |= 16;
    if (u.p) n |= 32;
    return n;
}

// narrow variables whose registers may hold other bits above them
pragma(inline, false) int narrow(int a, int b, int k)
{
    int n;
    foreach (i; 0 .. k)
    {
        ubyte x = cast(ubyte)(a + b + i);       // 0 when a + b + i is 256
        ushort y = cast(ushort)(a * b + i);     // 0 when a * b + i is 65536
        if (x) n += 1;
        if (!x) n += 10;
        if (y) n += 100;
        if (!y) n += 1000;
    }
    return n;
}

pragma(inline, false) int compares(int* p, long q, uint k, ubyte b)
{
    int n;
    foreach (i; 0 .. k)
    {
        if (p == null) n += 1;
        if (q != 0) n += 2;
        if (p && *p == 0) n += 4;
        if (b == 0) n += 8;
        q >>= 1;
        b += 64;
    }
    return n;
}

pragma(inline, false) bool odd(int i) { return (i & 1) != 0; }
pragma(inline, false) ubyte low(int i) { return cast(ubyte) i; }

pragma(inline, false) int flags(int k)
{
    int n;
    bool flag = false;
    foreach (i; 0 .. k)
    {
        if (!flag) n += 1;
        if (odd(i)) n += 10;
        if (low(i)) n += 100;
        flag = (n & 2) != 0;
    }
    return n;
}

void main()
{
    U u;
    assert(loads(&u) == 8);
    int v;
    u = U(-128, true, 1 << 30, 1L << 40, 0x8000, &v);
    assert(loads(&u) == (1 | 2 | 4 | 16 | 32));
    u = U(0, false, 0, 0, 0, null);
    assert(loads(&u) == 8);

    static int narrowRef(int a, int b, int k)
    {
        int n;
        foreach (i; 0 .. k)
        {
            n += ((a + b + i) & 0xFF) ? 1 : 10;
            n += ((a * b + i) & 0xFFFF) ? 100 : 1000;
        }
        return n;
    }
    // a + b + i reaches 256, a * b + i reaches 65536
    assert(narrow(255, 0, 3) == narrowRef(255, 0, 3));
    assert(narrow(65535, 1, 3) == narrowRef(65535, 1, 3));
    assert(narrow(200, 300, 70) == narrowRef(200, 300, 70));

    int z = 0, nz = 5;
    // q: 4, 2, 1, 0; b: 0, 64, 128, 192
    assert(compares(&z, 4, 4, 0) == 2 * 3 + 4 * 4 + 8);
    assert(compares(&nz, 4, 4, 0) == 2 * 3 + 8);
    assert(compares(null, 0, 2, 192) == 1 * 2 + 8);

    int n;
    bool flag = false;
    foreach (i; 0 .. 600)
    {
        if (!flag) n += 1;
        if (i & 1) n += 10;
        if (cast(ubyte) i) n += 100;
        flag = (n & 2) != 0;
    }
    assert(flags(600) == n);
}
