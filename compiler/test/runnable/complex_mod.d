// REQUIRED_ARGS: -d
// Complex modulo by a real or imaginary value is applied to each part.

void main()
{
    cfloat f = 5 + 7i;
    f %= 2i;
    assert(f == 1 + 1i);

    cdouble d = 5.5 + 7i;
    d = d % 2.0;
    assert(d == 1.5 + 1i);

    creal r = 9 + 4i;
    r = r % 3i;
    assert(r == 0 + 1i);

    cdouble e = 7 + 9i;
    e %= 4.0;
    assert(e == 3 + 1i);
}
