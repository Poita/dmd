/* REQUIRED_ARGS: -O
 */
// A ushort cut from a ulong and zero extended by the old code generator, as
// a function the new one does not compile

__gshared ulong[1] tab = [0x0000_0936_0000_0970];

pragma(inline, false)
ulong f(size_t n)
{
    ushort idx = cast(ushort)(tab[n] >> (16 * n));
    if (idx == 0xFFFF)
        return 0;
    return idx;
}

void main()
{
    assert(f(0) == 0x970);
}
