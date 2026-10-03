// REQUIRED_ARGS: -O -inline -release
// 16 byte slice values: returned, passed, assigned, selected and stored.

struct Holder { int[] items; size_t n; }

pragma(inline, false) int[] middle(int[] a)
{
    return a.length > 2 ? a[1 .. $ - 1] : a;
}

pragma(inline, false) int sum(int[] a)
{
    int s;
    foreach (x; a)
        s += x;
    return s;
}

pragma(inline, false) void keep(ref Holder h, int[] a, bool first)
{
    h.items = first ? a[0 .. 1] : a;
    h.n = h.items.length;
}

pragma(inline, false) int[] pick(int[] a, int[] b, int k)
{
    int[] r = a;
    if (k > 0)
        r = b;
    r = r[0 .. $ - (k & 1)];
    return r;
}

pragma(inline, false) uint high(ulong x)
{
    return cast(uint)(x >> 32);
}

void main()
{
    int[5] v = [1, 2, 3, 4, 5];
    int[] m = middle(v[]);
    if (!(m.length == 3 && m.ptr == &v[1])) assert(0);
    if (!(sum(m) == 9)) assert(0);
    if (!(sum(middle(v[0 .. 2])) == 3)) assert(0);
    Holder h;
    keep(h, v[], true);
    if (!(h.n == 1 && h.items.ptr == &v[0])) assert(0);
    keep(h, v[2 .. $], false);
    if (!(h.n == 3 && sum(h.items) == 12)) assert(0);
    if (!(sum(pick(v[0 .. 2], v[2 .. 5], 0)) == 3)) assert(0);
    if (!(sum(pick(v[0 .. 2], v[2 .. 5], 1)) == 7)) assert(0);
    if (!(high(0x1234_5678_9abc_def0) == 0x1234_5678)) assert(0);
}
