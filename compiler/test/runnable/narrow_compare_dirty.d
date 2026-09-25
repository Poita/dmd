// Comparing narrow values whose registers hold more than the value, such as the
// result of assigning an int expression to a byte.

int big(int x) { return x * 100; }

void main()
{
    byte b = 10;
    assert((b = cast(byte) big(10)) == cast(byte) 1000);
    ubyte ub;
    assert((ub = cast(ubyte) big(10)) == cast(ubyte) 1000);
    short s;
    assert((s = cast(short) big(10000)) == cast(short) 1_000_000);
    ushort us;
    assert((us = cast(ushort) big(10000)) < 20000);

    byte bw = 10;
    bw ^^= 3;
    assert(bw == cast(byte) 1000);
}
