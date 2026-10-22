/* PERMUTE_ARGS: -O -inline
 */
// A loop counting up with `<=` or `>` reaches its bound plus the increment
// before it stops, which can wrap around to a negative value: the signed
// comparison then goes on where an unsigned one would stop.

enum int inc = 1_435_234_887;

pragma(inline, false) int countLe(ref int last)
{
    int n;
    int i;
    for (i = 0; i <= inc; i += inc)
        ++n;
    last = i;
    return n;
}

pragma(inline, false) int countGt(ref int last)
{
    int n;
    int i;
    for (i = 0; !(i > inc); i += inc)
        ++n;
    last = i;
    return n;
}

void main()
{
    int last;
    assert(countLe(last) == 4);
    assert(last == 1_445_972_252);
    assert(countGt(last) == 4);
    assert(last == 1_445_972_252);
}
