// REQUIRED_ARGS: -O -release
// Values loaded from memory keep the extension their uses ask for.

pragma(inline, false) ulong widenUnsigned(const(int)* p)
{
    return cast(uint)*p;
}

pragma(inline, false) ulong widenBoth(const(int)* p)
{
    return cast(uint)*p + cast(ulong)cast(long)*p * 3;
}

pragma(inline, false) long widenSigned(const(int)* p, const(short)* q, const(byte)* r)
{
    return *p + cast(long)*q + cast(long)*r;
}

pragma(inline, false) ulong mixed(const(short)* q)
{
    short s = *q;
    return cast(ushort)s + cast(ulong)cast(long)s;
}

void main()
{
    int i = -2;
    short h = -3;
    byte b = -4;
    if (!(widenUnsigned(&i) == 0xFFFF_FFFE)) assert(0);
    if (!(widenBoth(&i) == cast(ulong)-6L + 0xFFFF_FFFE)) assert(0);
    if (!(widenSigned(&i, &h, &b) == -9)) assert(0);
    if (!(mixed(&h) == 0xFFFD + cast(ulong)-3L)) assert(0);
}
