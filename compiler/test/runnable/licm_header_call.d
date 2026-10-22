/* REQUIRED_ARGS: -O
 */
// A load in the header of a loop after a call that may not return is not moved
// before the loop, where it would be made also when the call does not return.

import core.stdc.stdlib : exit;

pragma(inline, false) void check(const int* p)
{
    if (!p)
        exit(0);
}

pragma(inline, false) int f(const(int)* p, int n)
{
    int s;
    do
    {
        check(p);
        s += *p;
    } while (--n);
    return s;
}

struct S { int a, b; }

pragma(inline, false) int g(const(S)* p, int n)
{
    int s;
    do
    {
        s += p.a;
        check(p ? &p.b : null);
        s += p.b;
    } while (--n);
    return s;
}

void main()
{
    int x = 3;
    assert(f(&x, 4) == 12);
    S y = S(1, 2);
    assert(g(&y, 2) == 6);
    f(null, 4);
    assert(0);
}
