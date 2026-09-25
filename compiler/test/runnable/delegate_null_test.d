// Delegates without a context compare unequal to null by their function pointer.
struct World { int prepped, ticked; int[] marks; }

void run(ref World w, ulong ticks, ulong seed,
        scope void delegate(ref World) prep = null,
        scope void delegate(ref World) eachTick = null)
{
    if (prep !is null)
        prep(w);
    foreach (t; 0 .. ticks)
        if (eachTick !is null)
            eachTick(w);
    w.marks ~= cast(int) seed;
}

void mark(ref World w, int k) { w.marks ~= k; }

void main()
{
    World w;
    run(w, 3, 33, (ref World ww) { ++ww.prepped; mark(ww, 1); }, (ref World ww) { ++ww.ticked; mark(ww, 2); });
    assert(w.prepped == 1 && w.ticked == 3);
    assert(w.marks == [1, 2, 2, 2, 33]);
    World v;
    run(v, 2, 7);
    assert(v.prepped == 0 && v.marks == [7]);
}
