// Slices of 2 byte elements filled with one value, of each length to past 8 bytes.
module memset_short;

struct Handle { ushort idx; }

void fillShorts(ushort[] a, ushort v) { a[] = v; }
void fillHandles(Handle[] a) { a[] = Handle(ushort.max); }

int main()
{
    foreach (n; 0 .. 20)
    {
        ushort[24] buf = 7;
        fillShorts(buf[1 .. 1 + n], 0xBEEF);
        foreach (i, x; buf)
            if (x != (i >= 1 && i < 1 + n ? 0xBEEF : 7))
                assert(0);
        Handle[24] h;
        fillHandles(h[2 .. 2 + n]);
        foreach (i, x; h)
            if (x.idx != (i >= 2 && i < 2 + n ? ushort.max : 0))
                assert(0);
    }
    return 0;
}
