// Reading a narrow field of a small struct parameter passed in a register.

struct Date
{
    short year;
    ubyte month;
    ubyte day;

    pragma(inline, false)
    int opCmp(Date rhs) const
    {
        if (year < rhs.year) return -1;
        if (year > rhs.year) return 1;
        if (month < rhs.month) return -1;
        if (month > rhs.month) return 1;
        if (day < rhs.day) return -1;
        if (day > rhs.day) return 1;
        return 0;
    }
}

struct Pair
{
    ubyte lo;
    ubyte hi;
    int rest;
}

pragma(inline, false)
int sumLo(Pair p, Pair q)
{
    return p.lo + q.lo;
}

pragma(inline, false)
bool loEq(Pair p, ubyte v)
{
    return p.lo == v;
}

void main()
{
    assert(Date(1982, 1, 4).opCmp(Date(1012, 12, 21)) == 1);
    assert(Date(1982, 1, 4).opCmp(Date(2012, 12, 21)) == -1);
    assert(Date(1, 1, 1).opCmp(Date(1, 1, 1)) == 0);
    assert(Date(2010, 1, 1).opCmp(Date(1, 1, 1)) == 1);
    assert(Date(5, 2, 1).opCmp(Date(5, 1, 30)) == 1);

    assert(sumLo(Pair(1, 200, 7), Pair(2, 100, 9)) == 3);
    assert(loEq(Pair(5, 6, 7), 5));
}
