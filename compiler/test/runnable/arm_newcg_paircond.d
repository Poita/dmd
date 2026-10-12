/* REQUIRED_ARGS: -O
 */
// Slices and delegates tested for being nonzero, as the value of an assignment

int[] pick(bool which, int[] a)
{
    if (auto r = which ? a : null)
        return r;
    return [7];
}

int[] lengthOnly(size_t n)
{
    int[] r = (cast(int*)null)[0 .. n];   // a length with a null pointer is still nonzero
    if (r)
        return [1];
    return [2];
}

int call(int delegate() d)
{
    if (auto g = d)
        return g();
    return -1;
}

void main()
{
    int[] a = [3, 4];
    assert(pick(true, a) == [3, 4]);
    assert(pick(false, a) == [7]);
    assert(pick(true, null) == [7]);
    assert(lengthOnly(0) == [2]);
    assert(lengthOnly(5) == [1]);
    int k = 9;
    assert(call(() => k + 1) == 10);
    assert(call(null) == -1);
}
