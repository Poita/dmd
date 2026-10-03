// REQUIRED_ARGS: -O -release
// The signedness of a division comes from its operands, not from the type of its
// result, which the optimizer may make unsigned for an unsigned shift of it.

pragma(inline, false) int nz(int x) { return x == 0 ? 1 : x; }

pragma(inline, false) int f(uint p0, int s)
{
    return (cast(int)~65535 / nz(cast(int)(100 * p0))) >>> (s & 7);
}

pragma(inline, false) int g(int a, int b, int s)
{
    int x = a;
    x /= b;
    return x >>> s;
}

void main()
{
    if (!(f(1, 1) == 2147483320)) assert(0);
    if (!(f(15, 2) == 1073741813)) assert(0);
    if (!(g(-1000, 7, 1) == 2147483577)) assert(0);
}
