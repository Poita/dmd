/* REQUIRED_ARGS: -O
 */
// Loads in loops without stores or calls of what the code before the loop loaded

struct S { int[] a; int bias; }

pragma(inline, false) int sum(const(S)* s)
{
    int t = 0;
    for (size_t i = 0; i < s.a.length; i++)
        t += s.a[i] + s.bias;
    return t;
}

pragma(inline, false) int sumWithStore(S* s, int* out_)
{
    // the store may change what the loop reads
    int t = 0;
    for (size_t i = 0; i < s.a.length; i++)
    {
        t += s.bias;
        *out_ = t;
    }
    return t;
}

__gshared S* shared_;
pragma(inline, false) void grow() { shared_.bias += 1; }

pragma(inline, false) int sumWithCall(S* s)
{
    int t = 0;
    for (size_t i = 0; i < s.a.length; i++)
    {
        t += s.bias;
        grow();
    }
    return t;
}

void main()
{
    S s = S([1, 2, 3], 10);
    if (sum(&s) != 36)
        assert(0);
    if (sumWithStore(&s, &s.bias) != 40)
        assert(0);
    S u = S([1, 2, 3], 1);
    shared_ = &u;
    if (sumWithCall(&u) != 1 + 2 + 3)
        assert(0);
}
