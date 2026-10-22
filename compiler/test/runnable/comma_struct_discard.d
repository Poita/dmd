/* REQUIRED_ARGS: -O
 * PERMUTE_ARGS: -inline
 */
// A discarded expression whose last operand copies a struct keeps the type of
// the struct copy, which the data flow analysis needs for its size.

struct S { ushort a; float b; ubyte c; }

S mk(long x)
{
    S s;
    s.a = cast(ushort)(x * 3);
    return s;
}

__gshared int sink;

void f(long y, long z)
{
    int v = cast(int)(cast(long)(mk(y).b * 64) + mk(z).a);
}

int g(long y, long z)
{
    float b = 2.5;
    S s = mk(y);
    s.b = b;
    int v = cast(int)(cast(long)(s.b * 64) + mk(z).a);
    sink = v;
    return cast(int)(cast(long)(s.b * 64) + mk(z).a);
}

void main()
{
    f(1, 2);
    assert(g(1, 2) == 166);
    assert(sink == 166);
}
