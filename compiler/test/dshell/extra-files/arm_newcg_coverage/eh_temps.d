// Temporaries with destructors in expressions: each is destroyed once, at the end of
// its expression or as an exception thrown before then leaves it, and the values the
// destructors and the code after them use are intact on both ways.
module eh_temps;

// asserts are compiled out with -release
void check(bool ok, int line = __LINE__)
{
    import core.stdc.stdio : fprintf, stderr;
    import core.stdc.stdlib : exit;
    if (!ok)
    {
        fprintf(stderr, "check failed at line %d\n", line);
        exit(1);
    }
}

__gshared long dtors;
__gshared long dtorSum;

struct S
{
    long x;
    ~this() { ++dtors; dtorSum += x; }
}

pragma(inline, false) S make(long x) { return S(x); }

pragma(inline, false) long use(long a, long b)
{
    if (b < 0)
        throw new Exception("negative");
    return a + b;
}

pragma(inline, false) long use2(long a, long b, long c)
{
    if (c == 7)
        throw new Exception("seven");
    return a * b + c;
}

pragma(inline, false) long oneTemp(long v)
{
    return use(make(v).x, v);
}

pragma(inline, false) long twoTemps(long a, long b, long c)
{
    return use2(make(a).x, make(b).x, c) + a;
}

// a value computed before the temporary and used after it, across the calls
pragma(inline, false) long around(long a, long b)
{
    const k = a * 3 + 1;
    const r = use(make(a + b).x, b);
    return r * k + k;
}

pragma(inline, false) long inLoop(long n)
{
    long s;
    foreach (i; 0 .. n)
    {
        try
            s += use(make(i).x, i == 3 ? -1 : i);
        catch (Exception e)
            s += 1000;
    }
    return s;
}

struct P
{
    long* p;
    ~this() { *p += 10; }
}

pragma(inline, false) P makeP(long* p) { return P(p); }

pragma(inline, false) long viaPointer(long a)
{
    long local = a;
    const r = use(makeP(&local).p is null ? 0 : 1, a);
    return r + local;
}

void main()
{
    check(oneTemp(3) == 6);
    check(dtors == 1 && dtorSum == 3);
    bool caught;
    try
        oneTemp(-2);
    catch (Exception e)
        caught = true;
    check(caught && dtors == 2 && dtorSum == 1);

    dtors = dtorSum = 0;
    check(twoTemps(2, 5, 1) == 2 * 5 + 1 + 2);
    check(dtors == 2 && dtorSum == 7);
    caught = false;
    try
        twoTemps(4, 6, 7);
    catch (Exception e)
        caught = true;
    check(caught && dtors == 4 && dtorSum == 17);

    dtors = dtorSum = 0;
    check(around(2, 5) == (7 + 5) * 7 + 7);
    check(dtors == 1 && dtorSum == 7);
    caught = false;
    try
        around(2, -5);
    catch (Exception e)
        caught = true;
    check(caught && dtors == 2 && dtorSum == 4);

    dtors = dtorSum = 0;
    check(inLoop(6) == 0 + 2 + 4 + 1000 + 8 + 10);
    check(dtors == 6 && dtorSum == 0 + 1 + 2 + 3 + 4 + 5);

    check(viaPointer(5) == 6 + 15);
    caught = false;
    try
        viaPointer(-5);
    catch (Exception e)
        caught = true;
    check(caught);
}
