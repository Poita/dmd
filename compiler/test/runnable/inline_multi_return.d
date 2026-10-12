/* REQUIRED_ARGS: -O -inline
 */
// Functions with returns inside loops and conditions, inlined as statements in
// declarations, assignments, conditions and expression statements, and into
// functions that are inlined in turn

__gshared int calls;

bool contains(const(int)[] a, int x)
{
    foreach (v; a)
        if (v == x)
            return true;
    return false;
}

int indexOf(const(int)[] a, int x)
{
    foreach (i, v; a)
    {
        if (v == x)
            return cast(int)i;
        if (v < 0)
            return -2;
    }
    return -1;
}

void bumpUntil(int[] a, int stop)
{
    foreach (ref v; a)
    {
        if (v == stop)
            return;
        ++v;
        ++calls;
    }
}

int classify(int n)
{
    if (n < 0)
        return -1;
    for (int i = 2; i * i <= n; i++)
        if (n % i == 0)
            return i;
    if (n < 2)
        return 0;
    return n;
}

// inlines contains and indexOf, and is inlined in turn
int score(const(int)[] a, int x)
{
    int s;
    if (contains(a, x))
        s += 10;
    int at = indexOf(a, x);
    s += at;
    return s;
}

struct P { int a, b; }

P pick(int n)
{
    foreach (i; 0 .. n)
        if (i * i > n)
            return P(i, n);
    return P(-1, -1);
}

void main()
{
    int[] a = [3, 1, 4, 1, 5, 9, 2, 6];
    assert(contains(a, 9) && !contains(a, 7));
    bool found = contains(a, 5);
    assert(found);
    int k = indexOf(a, 4);
    assert(k == 2);
    k = indexOf(a, 8);
    assert(k == -1);
    assert(indexOf([1, -3, 8], 8) == -2);

    calls = 0;
    bumpUntil(a, 4);
    assert(a[0] == 4 && a[1] == 2 && a[2] == 4 && calls == 2);

    int total;
    foreach (n; -2 .. 30)
        total += classify(n);
    int expect;
    foreach (n; -2 .. 30)
    {
        int c = n < 0 ? -1 : n < 2 ? 0 : n;
        for (int i = 2; i * i <= n; i++)
            if (n % i == 0) { c = i; break; }
        expect += c;
    }
    assert(total == expect);

    int[] b = [5, 6, 7];
    assert(score(b, 6) == 11 && score(b, 8) == -1);
    int sc;
    foreach (x; 4 .. 9)
        sc += score(b, x);
    assert(sc == -1 + 10 + 0 + 11 + 12 - 1);

    P p = pick(10);
    assert(p.a == 4 && p.b == 10);
    p = pick(0);
    assert(p.a == -1);
}
