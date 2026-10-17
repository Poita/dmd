module digits;

struct Digits
{
    enum freeze = function(int[] a) pure @trusted { return cast(immutable) a; };

    immutable(int)[] frozen(int[] x) { return freeze(x); }

    immutable(int)[] frozenT(T)(T x) { return freeze([cast(int) x]); }
}
