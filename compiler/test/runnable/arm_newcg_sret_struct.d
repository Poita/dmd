/* REQUIRED_ARGS: -O
 */
// Structs returned through the hidden result pointer

struct Big
{
    long a, b, c;
    double d;
}

struct Mat3
{
    float[9] m;
}

__gshared int dtors;

struct Owned
{
    int[5] v;
    ~this() { ++dtors; }
}

pragma(inline, false) Big make(long x, double y)
{
    return Big(x, x * 2, x * 3, y);
}

pragma(inline, false) Big named(long x)
{
    Big r;          // returned in place
    r.a = x;
    foreach (i; 0 .. 4)
        r.b += r.a + i;
    r.c = r.b - 1;
    r.d = 0.5 * x;
    return r;
}

pragma(inline, false) Big pick(bool p, ref Big u, ref Big v)
{
    return p ? u : v;
}

pragma(inline, false) Big early(int n)
{
    if (n < 0)
        return Big(-1, -1, -1, -1);
    Big r = make(n, n);
    r.c += n;
    return r;
}

pragma(inline, false) Mat3 scale(ref const Mat3 m, float s)
{
    Mat3 r;
    foreach (i; 0 .. 9)
        r.m[i] = m.m[i] * s;
    return r;
}

pragma(inline, false) Owned owned(int k)
{
    Owned o;
    foreach (i, ref e; o.v)
        e = k + cast(int)i;
    return o;
}

pragma(inline, false) long sum(Big b)
{
    return b.a + b.b + b.c + cast(long)b.d;
}

void main()
{
    Big b = make(3, 1.5);
    if (b.a != 3 || b.b != 6 || b.c != 9 || b.d != 1.5) assert(0);

    Big n = named(5);
    if (n.a != 5 || n.b != 26 || n.c != 25 || n.d != 2.5) assert(0);

    Big u = Big(1, 2, 3, 4), v = Big(5, 6, 7, 8);
    if (pick(true, u, v) != u || pick(false, u, v) != v) assert(0);

    if (early(-3) != Big(-1, -1, -1, -1)) assert(0);
    Big e = early(4);
    if (e.a != 4 || e.b != 8 || e.c != 16 || e.d != 4) assert(0);

    if (sum(make(2, 7.0)) != 2 + 4 + 6 + 7) assert(0);

    Mat3 m;
    foreach (i; 0 .. 9)
        m.m[i] = i;
    Mat3 s = scale(m, 2);
    foreach (i; 0 .. 9)
        if (s.m[i] != 2 * i) assert(0);

    {
        Owned o = owned(10);
        if (o.v != [10, 11, 12, 13, 14]) assert(0);
    }
    if (dtors != 1) assert(0);
}
