// REQUIRED_ARGS: -inline
// PERMUTE_ARGS: -O

/* Functions with loops inlined as statements that initialize or assign a
 * local variable.
 */

size_t lowerBound()(const(ulong)[] entries, ulong key)
{
    size_t lo = 0;
    size_t hi = entries.length;
    while (lo < hi)
    {
        const mid = (lo + hi) / 2;
        if (entries[mid] < key)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
}

int sumTo(int n)
{
    int r;
    foreach (i; 0 .. n)
        r += i;
    return r;
}

__gshared int calls;

float scaled(float x)
{
    ++calls;
    float r = x;
    foreach (i; 0 .. 3)
        r *= 2;
    return r;
}

size_t count(const(ulong)[] e, ulong a, ulong b)
{
    const lo = lowerBound(e, a);
    size_t hi;
    hi = lowerBound(e, b);
    return hi - lo;
}

void main()
{
    ulong[] e = [1, 3, 3, 5, 8, 13, 21];
    assert(count(e, 3, 9) == 4);
    assert(count(e, 0, 100) == 7);
    assert(count(e, 22, 30) == 0);
    int t = sumTo(5);
    assert(t == 10);
    t = sumTo(4);
    assert(t == 6);
    float f = scaled(1.5f);
    f = scaled(f);
    assert(f == 96 && calls == 2);
    const lo = lowerBound(e, 4);
    assert(lo == 3);
}
