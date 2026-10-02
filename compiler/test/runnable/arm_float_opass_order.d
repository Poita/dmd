// PERMUTE_ARGS: -O -inline -release

/* The left operand of a floating point op= is evaluated before the right one,
 * as the optimizer may move the assignment of a variable both read into the
 * left one.
 */

pragma(inline, false) void add(double* total, const(double)* tick, int p)
{
    int i = p + 1;
    total[i] += tick[i];
    int j = p + 2;
    total[j] -= tick[j];
    int k = p + 3;
    total[k] *= tick[k];
}

pragma(inline, false) void addf(float* total, const(float)* tick, int p)
{
    int i = p * 2;
    total[i] += tick[i];
    int j = p * 2 + 1;
    total[j] /= tick[j];
}

void main()
{
    double[6] t = [1, 2, 3, 4, 5, 6];
    double[6] k = [10, 20, 30, 40, 50, 60];
    add(t.ptr, k.ptr, 0);
    assert(t == [1, 22, -27, 160, 5, 6]);

    float[4] f = [1, 2, 3, 4];
    float[4] g = [4, 8, 16, 32];
    addf(f.ptr, g.ptr, 1);
    assert(f == [1, 2, 19, 0.125f]);
}
