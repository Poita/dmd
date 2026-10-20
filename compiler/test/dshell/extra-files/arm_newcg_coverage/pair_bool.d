// Slices and delegates tested for being null, as values and as branch conditions.
module pair_bool;

struct S
{
    int x;
    void delegate() dg;
    int[] arr;
}

bool hasDg(const(S)* s) { return s.dg !is null; }
bool noDg(const(S)* s) { return !s.dg; }
bool hasArr(const(S)* s) { return s.arr !is null; }
int branchDg(const(S)* s) { if (s.dg) return 1; return 2; }
int branchNoArr(const(S)* s) { if (s.arr is null) return 3; return 4; }

int main()
{
    S s;
    if (hasDg(&s) || !noDg(&s) || hasArr(&s) || branchDg(&s) != 2 || branchNoArr(&s) != 3)
        assert(0);
    int k;
    s.dg = () { ++k; };
    s.arr = [1];
    if (!hasDg(&s) || noDg(&s) || !hasArr(&s) || branchDg(&s) != 1 || branchNoArr(&s) != 4)
        assert(0);
    // nonzero in only one half
    s.arr = (cast(int*) null)[0 .. 0];
    s.arr = s.arr.ptr[0 .. 0];
    int[] lenOnly = (cast(int*) null)[0 .. 1];
    s.arr = lenOnly;
    if (!hasArr(&s) || branchNoArr(&s) != 4)
        assert(0);
    s.arr = (new int[2])[0 .. 0];
    if (!hasArr(&s) || branchNoArr(&s) != 4)
        assert(0);
    return 0;
}
