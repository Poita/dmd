/* REQUIRED_ARGS: -O -inline -release
 * PERMUTE_ARGS:
 */
// Nested functions whose every call is inlined, and nested functions still referred to

int all(int n)
{
    int m = n * 2;
    int[] a = new int[](m);
    int at(int i) { return a[i % m] + m; }  // every call inlined
    foreach (i; 0 .. m)
        a[i] = i;
    int s = 0;
    foreach (i; 0 .. m)
        s += at(i);
    return s;
}

int viaSibling(int n)
{
    int k = n + 1;
    int inner(int x) { return x * k; }
    int outer(int x) { return inner(x) + inner(x + 1); }
    int delegate(int) dg = &outer;
    return dg(n);
}

int recursive(int n)
{
    int base = 3;
    int f(int x) { return x <= 0 ? base : f(x - 1) + base; }
    return f(n);
}

int apply(scope int delegate(int) dg, int x) { return dg(x); }

int lambda(int n)
{
    int c = n * 5;
    return apply((int x) => x + c, n);
}

void main()
{
    if (all(4) != 28 + 64)
        assert(0);
    if (viaSibling(2) != 2 * 3 + 3 * 3)
        assert(0);
    if (recursive(4) != 15)
        assert(0);
    if (lambda(2) != 12)
        assert(0);
}

int applyT(alias f)(int x) { return f(x); }

int viaTemplate(int n)
{
    int k = n;
    int g(int x) { return x + k; }
    static int h(int x) { return x * 2; }
    return applyT!g(n) + applyT!h(n);
}

shared static this()
{
    if (viaTemplate(3) != 6 + 6)
        assert(0);
}

struct Each
{
    int opApply(scope int delegate(int) dg)
    {
        foreach (i; 0 .. 3)
            if (auto r = dg(i))
                return r;
        return 0;
    }
}

pragma(inline, false) void call(scope void delegate(int) dg, int x) { dg(x); }

int viaForeachBody(int n)
{
    int total = n;
    void add(int x) { total += x; }
    foreach (i; Each())
        call((int x) { add(x); }, i);
    return total;
}

shared static this()
{
    if (viaForeachBody(10) != 13)
        assert(0);
}
