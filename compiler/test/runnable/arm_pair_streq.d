// PERMUTE_ARGS: -O -inline -release

// A struct of two integers copied whole into another struct

import core.atomic;

struct Pair { long a, b; }

pragma(inline, true) ulong[2] bits(Pair value)
{
    const ulong[2] desired = *cast(ulong[2]*) &value;
    return desired;
}

pragma(inline, false) Pair copyOf(Pair v)
{
    Pair w = void;
    w = v;
    return w;
}

void main()
{
    shared Pair p = Pair(1, 2);
    assert(cas(&p, Pair(1, 2), Pair(3, 4)));
    assert(atomicLoad(p) == Pair(3, 4));
    assert(!cas(&p, Pair(1, 2), Pair(5, 6)));

    const r = bits(Pair(7, 8));
    assert(r[0] == 7 && r[1] == 8);
    assert(copyOf(Pair(9, 10)) == Pair(9, 10));
}
