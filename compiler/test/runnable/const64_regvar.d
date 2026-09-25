// A 64 bit constant assigned to a variable the optimizer keeps in a register.
enum ulong big = 0x27D4EB2F165667C5UL;

ulong pick(ulong a, bool wide)
{
    ulong h;
    if (wide)
        h = (a << 1 | a >> 63) + a;
    else
        h = big;
    h += a;
    return h ^ (h >> 33);
}

void main()
{
    assert(pick(0, false) == (big ^ (big >> 33)));
    assert(pick(5, false) == ((big + 5) ^ ((big + 5) >> 33)));
    assert(pick(3, true) == 12);
}
