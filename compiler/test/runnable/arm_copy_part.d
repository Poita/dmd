// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Copies of a part of a larger variable, used in loops, with the variable
 * changed after the copy.
 */

struct S { long a; long b; long c; }

pragma(inline, false) S make(long x) { return S(x, x * 2, x * 3); }

pragma(inline, false) long sumB(long x, int n)
{
    S s = make(x);
    const b = s.b;
    long r;
    foreach (i; 0 .. n)
    {
        r += b;
        s.b += i;               // does not change the copy
    }
    return r + s.b;
}

pragma(inline, false) float[] fill(size_t n)
{
    auto a = new float[](n);
    foreach (i, ref x; a)
        x = i * 0.5f;
    return a;
}

void main()
{
    assert(sumB(5, 4) == 4 * 10 + 10 + 6);
    auto a = fill(7);
    assert(a.length == 7 && a[6] == 3.0f);
    auto z = new float[](3);
    foreach (x; z)
        assert(x != x);         // float.init is NaN
}
