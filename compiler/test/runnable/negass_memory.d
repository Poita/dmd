// REQUIRED_ARGS: -O

// Negating a variable in place when the variable lives in memory.

void escape(int* p) {}
void escape(long* p) {}
void escape(short* p) {}

int negInt(int x, bool sign)
{
    int v = x;
    escape(&v);
    if (sign)
        v = -v;
    return v;
}

long negLong(long x, bool sign)
{
    long v = x;
    escape(&v);
    if (sign)
        v = -v;
    return v;
}

short negShort(short x, bool sign)
{
    short v = x;
    escape(&v);
    if (sign)
        v = cast(short) -v;
    return v;
}

void main()
{
    assert(negInt(7, true) == -7);
    assert(negInt(7, false) == 7);
    assert(negLong(45, true) == -45);
    assert(negLong(-45, true) == 45);
    assert(negShort(8, true) == -8);
}
