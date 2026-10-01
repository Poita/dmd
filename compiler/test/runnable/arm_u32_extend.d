// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

// 32 bit results widened to 64 bits, whose high bits the 32 bit instructions zero

pragma(inline, false) ulong widen(uint a, uint b, int s)
{
    ulong r;
    r += cast(ulong)(a + b) * 3;        // wraps at 32 bits
    r ^= cast(ulong)(a - b) << 1;       // wraps below 0
    r += cast(ulong)(a * b);
    r += cast(ulong)(~a);
    r += cast(ulong)(-a);
    r += cast(ulong)(a >> s) + cast(ulong)(a << s);
    r += cast(ulong)(cast(uint) s >> 1);
    return r;
}

void main()
{
    uint a = 0xFFFF_FFF0, b = 0x20;
    int s = 4;
    ulong r;
    r += cast(ulong)(cast(uint)(a + b)) * 3;
    r ^= cast(ulong)(cast(uint)(a - b)) << 1;
    r += cast(ulong)(cast(uint)(a * b));
    r += cast(ulong)(cast(uint) ~a);
    r += cast(ulong)(cast(uint) -a);
    r += cast(ulong)(cast(uint)(a >> s)) + cast(ulong)(cast(uint)(a << s));
    r += cast(ulong)(cast(uint) s >> 1);
    assert(widen(a, b, s) == r);
}
