// Slices and delegates compared for equality.
module pair_compare;

struct R
{
    int a;
    string name;
    int delegate(int) dg;
}

bool sameName(ref const R x, ref const R y) { return x.name is y.name; }
bool sameDg(ref const R x, ref const R y) { return x.dg is y.dg; }
bool otherDg(ref const R x, ref const R y) { return x.dg !is y.dg; }
bool sameSlice(const(int)[] a, const(int)[] b) { return a is b; }


int main()
{
    int k = 3;
    int add(int v) { return v + k; }
    int mul(int v) { return v * k; }
    R r1 = R(1, "abc", &add), r2 = R(2, r1.name, &add), r3 = R(3, "abc".idup, &mul);
    assert(sameName(r1, r2));
    assert(!sameName(r1, r3));
    assert(sameDg(r1, r2));
    assert(!sameDg(r1, r3));
    assert(otherDg(r2, r3));
    assert(!otherDg(r1, r2));
    int[4] buf = [1, 2, 3, 4];
    assert(sameSlice(buf[0 .. 2], buf[0 .. 2]));
    assert(!sameSlice(buf[0 .. 2], buf[0 .. 3]));
    assert(!sameSlice(buf[0 .. 2], buf[1 .. 3]));
    return 0;
}
