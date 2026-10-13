/* REQUIRED_ARGS: -O
 */
// A struct of at most 8 bytes whose integer fields are written and read one by one,
// held in a register: the fields keep their values and signs, and building one is
// done without memory

struct Cap { int s, e; }
struct Mixed { byte a; short b; int c; }
struct Bytes { ubyte x, y, z, w; }
struct Halves { short p; ushort q; }

pragma(inline, false) Cap make(int a, int b) { return Cap(a, b); }
pragma(inline, false) void setp(Cap* p, int a, int b) { *p = Cap(a, b); }

pragma(inline, false) Mixed mixed(int a, int b, int c)
{
    Mixed m;
    m.a = cast(byte) a;
    m.b = cast(short) b;
    m.c = c;
    return m;
}

pragma(inline, false) int sumBytes(int n)
{
    Bytes v;
    foreach (i; 0 .. n)
    {
        v.x = cast(ubyte)(v.x + 1);
        v.y = cast(ubyte)(v.y + 3);
        v.z = cast(ubyte)(v.z ^ i);
        v.w = cast(ubyte) i;
    }
    return v.x + v.y * 2 + v.z * 3 + v.w * 4;
}

pragma(inline, false) int halves(int p, int q)
{
    Halves h;
    h.p = cast(short) p;
    h.q = cast(ushort) q;
    return h.p * 100_000 + h.q;
}

// the number of loads and stores in f's code up to its first return
int memoryOps(void* f)
{
    int n;
    for (const(uint)* p = cast(const(uint)*) f; *p != 0xD65F03C0; ++p)
        if ((*p & 0x0A00_0000) == 0x0800_0000)
            ++n;
    return n;
}

void main()
{
    assert(make(3, -4) == Cap(3, -4));
    Cap c;
    setp(&c, -7, 9);
    assert(c == Cap(-7, 9));
    assert(mixed(-3, -300, -70_000) == Mixed(-3, -300, -70_000));
    assert(mixed(127, 32_767, int.max) == Mixed(127, 32_767, int.max));

    Bytes v;
    foreach (i; 0 .. 1000)
    {
        v.x = cast(ubyte)(v.x + 1);
        v.y = cast(ubyte)(v.y + 3);
        v.z = cast(ubyte)(v.z ^ i);
        v.w = cast(ubyte) i;
    }
    assert(sumBytes(1000) == v.x + v.y * 2 + v.z * 3 + v.w * 4);
    assert(halves(-2, 65_535) == -2 * 100_000 + 65_535);
    assert(halves(300, 1) == 300 * 100_000 + 1);

    version (AArch64)
    {
        assert(memoryOps(&make) == 0);
        assert(memoryOps(&setp) == 1);
    }
}
