// REQUIRED_ARGS: -d
// Multiplication mixing complex with real or imaginary operands.

cdouble rmulc(double r, cdouble c) { return r * c; }
cdouble imulc(idouble i, cdouble c) { return i * c; }
cdouble cmulr(cdouble c, double r) { return c * r; }
cdouble cmuli(cdouble c, idouble i) { return c * i; }
cfloat cmulif(cfloat c, ifloat i) { return c * i; }

void main()
{
    assert(rmulc(2, 1 + 3i) == 2 + 6i);
    assert(imulc(2i, 1 + 3i) == -6 + 2i);
    assert(cmulr(1 + 3i, 2) == 2 + 6i);
    assert(cmuli(1 + 3i, 2i) == -6 + 2i);
    assert(cmulif(1 + 3i, 2i) == -6 + 2i);
}
