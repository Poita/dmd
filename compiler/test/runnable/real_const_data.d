// Floating point constants placed in the data segment keep their value.

void check(real[] x, real v)
{
    foreach (e; x)
        assert(e == v);
}

void main()
{
    real[2] a = [real.max, real.max];
    check(a[], real.max);
    real[3] b = 1.1L;
    check(b[], 1.1L);
    double[2] c = [double.max, double.max];
    assert(c[1] == double.max);
}
