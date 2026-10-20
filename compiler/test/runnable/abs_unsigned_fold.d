/*
REQUIRED_ARGS: -O
PERMUTE_ARGS: -inline
*/

// `a >= 0 ? a : -a` of a signed value converted to unsigned is an absolute
// value of the signed value, also when it is a constant folded at compile time.

uint absU(int a)
{
    return a >= 0 ? cast(uint)a : -cast(uint)a;
}

uint absU2(int a)
{
    return a < 0 ? -cast(uint)a : cast(uint)a;
}

ulong absUL(long a)
{
    return a >= 0 ? cast(ulong)a : -cast(ulong)a;
}

uint gcdLike(int a, uint b)
{
    uint ax = a >= 0 ? a : -cast(uint)a;
    if (ax == 0)
        return b;
    return ax;
}

void main()
{
    if (absU(-120) != 120) assert(0);
    if (absU(120) != 120) assert(0);
    if (absU(int.min) != 0x8000_0000u) assert(0);
    if (absU2(-7) != 7) assert(0);
    if (absUL(-5) != 5) assert(0);
    if (absUL(long.min) != 0x8000_0000_0000_0000uL) assert(0);
    if (gcdLike(-120, 10u) != 120) assert(0);
    if (gcdLike(0, 10u) != 10) assert(0);

    enum c = absU(-3);
    static assert(c == 3);
}
