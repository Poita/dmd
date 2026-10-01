// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Slice copies of every length up to a few chunks, at unaligned offsets,
 * leaving the bytes around the destination untouched.
 */

pragma(inline, false) void copy(ubyte[] d, const(ubyte)[] s)
{
    d[] = s[];
}

struct Buf
{
    ubyte[32] buffer;
    size_t used;

    pragma(inline, false) void put(scope const(ubyte)[] data)
    {
        buffer[used .. used + data.length] = data[];
        used += data.length;
    }
}

void main()
{
    ubyte[100] src;
    foreach (i, ref b; src)
        b = cast(ubyte)(i * 7 + 3);

    foreach (len; 0 .. 71)
    {
        foreach (so; 0 .. 9)
        {
            foreach (dof; 0 .. 9)
            {
                ubyte[100] dst = 0xEE;
                copy(dst[dof .. dof + len], src[so .. so + len]);
                foreach (i; 0 .. dof)
                    assert(dst[i] == 0xEE);
                foreach (i; 0 .. len)
                    assert(dst[dof + i] == src[so + i]);
                foreach (i; dof + len .. 100)
                    assert(dst[i] == 0xEE);
            }
        }
    }

    Buf b;
    b.put(src[1 .. 4]);
    b.put(src[10 .. 18]);
    b.put(src[30 .. 31]);
    b.put(src[50 .. 62]);
    assert(b.used == 24);
    assert(b.buffer[0 .. 3] == src[1 .. 4]);
    assert(b.buffer[3 .. 11] == src[10 .. 18]);
    assert(b.buffer[11] == src[30]);
    assert(b.buffer[12 .. 24] == src[50 .. 62]);
    foreach (x; b.buffer[24 .. $])
        assert(x == 0);
}
