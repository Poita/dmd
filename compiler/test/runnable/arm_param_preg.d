// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Parameters read from the registers they came in, unless something changed
 * the register or the parameter first.
 */

__gshared int sink;
pragma(inline, false) int clobber(int a, int b, int c) { sink += a; return a * b - c; }

pragma(inline, false) ulong widen(uint i) { return i; }
pragma(inline, false) long widenS(int i) { return i; }
pragma(inline, false) size_t index(size_t b, uint i) { return b + (size_t(i) << 3); }
pragma(inline, false) long afterCall(int a, int b, uint c)
{
    const r = clobber(3, 4, 5);     // the argument registers are reused
    return long(a) * r + b + c;
}
pragma(inline, false) long modified(int a, uint b)
{
    a += 7;
    b *= 3;
    return long(a) + b;
}
pragma(inline, false) int addressTaken(int a, int b)
{
    int* p = &a;
    *p += b;
    return a + b;
}
pragma(inline, false) int narrow(ubyte a, short b, byte c)
{
    return a + b + c + a * b;
}

int main()
{
    assert(widen(0xFFFF_FFFF) == 0xFFFF_FFFF);
    assert(widenS(-5) == -5);
    assert(index(16, 0x8000_0000) == 16 + 0x4_0000_0000);
    assert(afterCall(10, 20, 30) == 10 * 7 + 50);
    assert(modified(1, 5) == 8 + 15);
    assert(addressTaken(4, 6) == 16);
    assert(narrow(200, -3, -4) == 200 - 3 - 4 - 600);
    return 0;
}
