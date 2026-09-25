// The quotient and remainder of a 64 bit division computed together.

char[] toStr(ulong value, char[] buf)
{
    size_t i = buf.length;
    do
    {
        uint x = void;
        if (value < 10) { x = cast(uint) value; value = 0; }
        else { x = cast(uint)(value % 10); value /= 10; }
        buf[--i] = cast(char)(x + '0');
    } while (value);
    return buf[i .. $];
}

long divmod(long a, long b, out long r) { r = a % b; return a / b; }

void main()
{
    char[24] b;
    assert(toStr(ulong.max, b[]) == "18446744073709551615");
    long r;
    assert(divmod(-0x1_0000_0007, 3, r) == -0x5555_5557 && r == -2);
}
