// Integer and hidden result pointer parameters homed beyond a scaled 12 bit frame offset.
struct Big { long[20] a; }

Big make(long x, int y, short z, long w) @trusted
{
    long[16384] pad;                    // pushes the parameter homes far from the frame pointer
    pad[x & 7] = y;
    Big b;
    b.a[0] = x;
    b.a[1] = y;
    b.a[2] = z;
    b.a[3] = w + pad[x & 7];
    return b;
}

void main()
{
    auto b = make(5, -6, 7, 8);
    assert(b.a[0] == 5 && b.a[1] == -6 && b.a[2] == 7 && b.a[3] == 2);
}
