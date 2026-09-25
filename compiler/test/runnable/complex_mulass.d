// REQUIRED_ARGS: -d
// Complex multiply- and divide-assign store both parts of the result.

void main()
{
    cdouble p = 1 + 2i;
    p *= 3 + 4i;
    assert(p == -5 + 10i);
    p /= 1 + 2i;
    assert(p == 3 + 4i);

    cfloat f = 1 + 2i;
    f *= 3 + 4i;
    assert(f == -5 + 10i);

    creal[] a = [1 + 1i, 2 + 0i];
    a[0] *= a[1];
    assert(a[0] == 2 + 2i);
}
