// REQUIRED_ARGS: -O -release
// A register variable read whole as a struct, as *cast(T*)&bits becomes.

struct S { int* p; }
struct P { uint a, b; }

pragma(inline, false) T fromBits(T, U)(U bits) @trusted
{
    return *cast(T*) &bits;
}

void main()
{
    int x;
    auto s = fromBits!S(cast(ulong)cast(size_t)&x);
    if (s.p !is &x) assert(0);
    auto z = fromBits!S(0UL);
    if (z.p !is null) assert(0);
    auto p = fromBits!P(0x0000_0002_0000_0001UL);
    if (p.a != 1 || p.b != 2) assert(0);
}
