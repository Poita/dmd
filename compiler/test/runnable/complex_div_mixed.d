// REQUIRED_ARGS: -d
// Division mixing complex with real or imaginary operands.

cdouble rdivc(double r, cdouble c) { return r / c; }
cdouble idivc(idouble i, cdouble c) { return i / c; }
cdouble cdivr(cdouble c, double r) { return c / r; }
cdouble cdivi(cdouble c, idouble i) { return c / i; }
cfloat rdivcf(float r, cfloat c) { return r / c; }

void main()
{
    assert(rdivc(2, 1 + 1i) == 1 - 1i);
    assert(idivc(2i, 1 + 1i) == 1 + 1i);
    assert(cdivr(4 + 6i, 2) == 2 + 3i);
    assert(cdivi(4 + 6i, 2i) == 3 - 2i);
    assert(rdivcf(2, 1 + 1i) == 1 - 1i);
}
