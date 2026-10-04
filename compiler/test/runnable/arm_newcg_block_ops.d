/* REQUIRED_ARGS: -O
 */
// Copies and fills of a number of bytes known only when they run

struct P { int a; short b; byte c; }

pragma(inline, false) void copy(T)(T[] d, const(T)[] s) { d[] = s[]; }
pragma(inline, false) void fill(T)(T[] d, T v) { d[] = v; }

void checkCopy(T)(size_t n, T delegate(size_t) make)
{
    auto s = new T[n];
    foreach (i; 0 .. n)
        s[i] = make(i);
    auto d = new T[n + 2];
    d[0] = make(1000);
    d[$ - 1] = make(1001);
    copy(d[1 .. $ - 1], s);
    if (d[0] != make(1000) || d[$ - 1] != make(1001)) assert(0);
    foreach (i; 0 .. n)
        if (d[i + 1] != s[i]) assert(0);
}

void checkFill(T)(size_t n, T v, T guard)
{
    auto d = new T[n + 2];
    d[0] = guard;
    d[$ - 1] = guard;
    fill(d[1 .. $ - 1], v);
    if (d[0] != guard || d[$ - 1] != guard) assert(0);
    foreach (i; 0 .. n)
        if (d[i + 1] != v) assert(0);
}

void main()
{
    static immutable size_t[] lengths = [0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 63, 64, 65, 1000, 100_003];
    foreach (n; lengths)
    {
        checkCopy!ubyte(n, i => cast(ubyte)(i * 7 + 1));
        checkCopy!int(n, i => cast(int)(i * 31 - 5));
        checkCopy!double(n, i => i * 0.5);
        checkCopy!P(n, i => P(cast(int)i, cast(short)(i * 3), cast(byte)i));
        checkFill!ubyte(n, 0, 9);
        checkFill!ubyte(n, 0xA5, 9);
        checkFill!char(n, 'x', 'y');
        checkFill!int(n, 0, -1);
        checkFill!int(n, 0x1234_5678, -1);
        checkFill!float(n, 0.0f, 1.0f);
        checkFill!float(n, 2.5f, 1.0f);
        checkFill!long(n, 0, -1);
        checkFill!long(n, 0x0102_0304_0506_0708, -1);
        checkFill!double(n, 0.0, -1.0);
    }
}
