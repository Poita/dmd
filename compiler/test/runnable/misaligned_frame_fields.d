// Misaligned fields of locals at offsets beyond the reach of an unscaled load.

struct P
{
align(1):
    ubyte a;
    int b;
    long c;
}

long near()
{
    ubyte[300] pad = void;
    P[4] ps;
    pad[0] = 1;
    ps[3].b = 7;
    ps[3].c = 9;
    return pad[0] + ps[3].b + ps[3].c;
}

long far()
{
    ubyte[70_000] pad = void;
    P[40] ps;
    pad[0] = 1;
    ps[39].b = 7;
    ps[39].c = 9;
    ps[20].c = 11;
    return pad[0] + ps[39].b + ps[39].c + ps[20].c;
}

void main()
{
    assert(near() == 17);
    assert(far() == 28);
}
