// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline

/* Compares of byte and short values, from memory, from arithmetic that
 * leaves bits above them set, and with constants at the ends of their range.
 */

pragma(inline, false) int cmpMem(const(ubyte)[] a, const(byte)[] b, const(ushort)[] c, const(short)[] d)
{
    int r;
    foreach (i; 0 .. a.length)
    {
        r += a[i] == 2;
        r += a[i] < a[i ^ 1];
        r += a[i] == 255;
        r += b[i] < -100;
        r += b[i] > b[i ^ 1];
        r += b[i] == -128;
        r += c[i] > 60000;
        r += c[i] == c[i ^ 1];
        r += d[i] < -30000;
        r += d[i] >= d[i ^ 1];
    }
    return r;
}

pragma(inline, false) int cmpDirty(ubyte x, ubyte y, byte p, byte q, ushort s, short t)
{
    int r;
    foreach (k; 0 .. 4)
    {
        ubyte u = cast(ubyte)(x + y + k);       // wraps above 255
        byte v = cast(byte)(p - q - k);         // wraps below -128
        ushort w = cast(ushort)(s * 3 + k);
        short z = cast(short)(t * 5 - k);
        r = r * 3 + (u < y) + (u == 1) + (v > p) + (v == 127) + (w < s) + (w == 0xFFFF) + (z > t) + (z == -32768);
        r += (u < x) + (y > u) + (v >= q) + (q < v);
    }
    return r;
}

int refDirty(ubyte x, ubyte y, byte p, byte q, ushort s, short t)
{
    int r;
    foreach (k; 0 .. 4)
    {
        const int u = (x + y + k) & 0xFF;
        const int v = cast(byte)((p - q - k) & 0xFF);
        const int w = (s * 3 + k) & 0xFFFF;
        const int z = cast(short)((t * 5 - k) & 0xFFFF);
        r = r * 3 + (u < y) + (u == 1) + (v > p) + (v == 127) + (w < s) + (w == 0xFFFF) + (z > t) + (z == -32768);
        r += (u < x) + (y > u) + (v >= q) + (q < v);
    }
    return r;
}

// a byte loaded into a register variable, then compared
pragma(inline, false) uint scan(const(ubyte)[] state, const(ubyte)[] owner, ubyte own)
{
    uint best = uint.max;
    foreach (cell, st; state)
    {
        if (st != 1 || owner[cell] != own)
            continue;
        best = cast(uint) cell;
    }
    return best;
}

void main()
{
    ubyte[6] st = [0, 1, 2, 1, 1, 0x81];
    ubyte[6] ow = [3, 3, 3, 4, 3, 3];
    assert(scan(st[], ow[], 3) == 4);
    assert(scan(st[], ow[], 4) == 3);
    assert(scan(st[], ow[], 5) == uint.max);

    ubyte[4] a = [2, 255, 0, 2];
    byte[4] b = [-128, 127, -101, 5];
    ushort[4] c = [60001, 60001, 1, 65535];
    short[4] d = [-30001, 32767, -32768, 0];
    assert(cmpMem(a[], b[], c[], d[]) == 19);

    foreach (x; [0, 1, 200, 255])
        foreach (y; [0, 2, 254])
            foreach (p; [-128, -1, 0, 127])
                foreach (q; [-128, 3, 127])
                    foreach (s; [0, 21845, 65535])
                        foreach (t; [-32768, -1, 6554])
                            assert(cmpDirty(cast(ubyte)x, cast(ubyte)y, cast(byte)p, cast(byte)q,
                                            cast(ushort)s, cast(short)t) ==
                                   refDirty(cast(ubyte)x, cast(ubyte)y, cast(byte)p, cast(byte)q,
                                            cast(ushort)s, cast(short)t));
}
