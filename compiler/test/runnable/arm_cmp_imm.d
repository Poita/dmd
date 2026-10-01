// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Compares with constants that fit the CMP and CMN immediate field,
 * signed and unsigned, 32 and 64 bit, at the edges of the field.
 */

int flags(T, T c)(T x)
{
    int r;
    if (x < c) r |= 1;
    if (x <= c) r |= 2;
    if (x > c) r |= 4;
    if (x >= c) r |= 8;
    if (x == c) r |= 16;
    if (x != c) r |= 32;
    return r;
}

int expect(T)(T x, T c)
{
    int r;
    if (x < c) r |= 1;
    if (x <= c) r |= 2;
    if (x > c) r |= 4;
    if (x >= c) r |= 8;
    if (x == c) r |= 16;
    if (x != c) r |= 32;
    return r;
}

void check(T, T c)()
{
    static immutable T[] xs = [T.min, T.min + 1, cast(T)-4096, cast(T)-4095, cast(T)-1, 0, 1,
                               0xFFE, 0xFFF, 0x1000, 0x1001, 0xFFF000, 0xFFF001, T.max - 1, T.max];
    foreach (x; xs)
    {
        // the value is opaque to the compare, which must use the constant
        T v = x;
        assert(flags!(T, c)(*cast(shared T*)&v) == expect!T(x, c));
    }
}

void checkAll(T)()
{
    check!(T, 0)();
    check!(T, 1)();
    check!(T, 0xFFF)();
    check!(T, 0x1000)();
    check!(T, 0xFFF000)();
    check!(T, cast(T)-1)();
    check!(T, cast(T)-4095)();
    check!(T, cast(T)-4096)();
    check!(T, T.min)();
    check!(T, T.max)();
}

int main()
{
    checkAll!int();
    checkAll!uint();
    checkAll!long();
    checkAll!ulong();
    return 0;
}
