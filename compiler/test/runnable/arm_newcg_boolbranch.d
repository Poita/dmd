/* REQUIRED_ARGS: -O -inline
 */
// Branches on the bool results of inlined functions, of comparisons of every kind,
// through masks, extensions and copies, taken and not, with work in between

bool testAndSet(ulong* words, size_t i)
{
    const mask = 1UL << (i & 63);
    const was = (words[i >> 6] & mask) != 0;
    words[i >> 6] |= mask;
    return was;
}

bool less(int a, int b) { return a < b; }
bool below(uint a, uint b) { return a < b; }
bool fless(double a, double b) { return a < b; }
bool same(long a, long b) { return a == b; }

int count(int n)
{
    ulong[4] words;
    int fresh, again;
    foreach (k; 0 .. n)
    {
        const i = (k * 37) % 200;
        if (!testAndSet(words.ptr, i))
            ++fresh;
        else
            ++again;
    }
    return fresh * 1000 + again;
}

int mix(int[] xs, uint[] us, double[] ds, long[] ls)
{
    int r;
    foreach (i; 0 .. xs.length)
    {
        if (less(xs[i], 0)) r += 1;
        if (!below(us[i], 5)) r += 10;
        if (fless(ds[i], 0.5)) r += 100;
        if (same(ls[i], -1)) r += 1000;
    }
    return r;
}

void main()
{
    // 0..300 visits each of 200 slots: the first 200 are new, as 37 and 200 are coprime
    assert(count(300) == 200 * 1000 + 100);
    assert(mix([-1, 0, 5, -7], [0, 5, 9, 4], [0.25, 0.5, double.nan, -1], [-1, 0, -1, 2]) ==
           2 * 1 + 2 * 10 + 2 * 100 + 2 * 1000);
}
