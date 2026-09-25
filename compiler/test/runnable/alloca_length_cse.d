// An alloca whose size and a later index share a common subexpression.

import core.stdc.stdlib : alloca;

int fill(int[] t)
{
    auto si = cast(int*) alloca((t.length + 1) * int.sizeof);
    si[t.length] = 7;
    return si[t.length];
}

void main()
{
    int[3] a;
    assert(fill(a[]) == 7);
}
