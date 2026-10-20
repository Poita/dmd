// Narrow loads into variables are extended already

int ext0_range(const ref ubyte[16] px)
{
    int lo = 255, hi = 0;
    foreach (v; px)
    {
        lo = v < lo ? v : lo;
        hi = v > hi ? v : hi;
    }
    return hi * 256 + lo;
}

uint ext0_sumHalves(const(ushort)[] a)
{
    uint s;
    foreach (v; a)
        s += v;
    return s;
}

// a signed byte is sign extended, so needs it
int signedBytes(const(byte)[] a)
{
    int s;
    foreach (v; a)
        s += v;
    return s;
}

// the low byte of a sum needs zero extending
uint lowByte(uint x, uint y)
{
    ubyte b = cast(ubyte)(x + y);
    return b;
}

void main()
{
    ubyte[16] px = [9, 200, 3, 255, 7, 0, 18, 30, 40, 50, 60, 70, 80, 90, 100, 110];
    if (ext0_range(px) != 255 * 256 + 0) assert(0);
    ubyte[16] q = 77;
    if (ext0_range(q) != 77 * 256 + 77) assert(0);
    static immutable ushort[] h = [65535, 1, 65535];
    if (ext0_sumHalves(h) != 131071) assert(0);
    static immutable byte[] b = [-128, 127, -1, -1];
    if (signedBytes(b) != -3) assert(0);
    if (lowByte(0xFF, 2) != 1) assert(0);
}
