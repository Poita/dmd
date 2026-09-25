/* Adding and subtracting complex numbers and real or imaginary ones.
 * REQUIRED_ARGS: -d
 */

cdouble addR(cdouble c, double x) { return c + x; }
cdouble subR(cdouble c, double x) { return c - x; }
cdouble addI(cdouble c, idouble y) { return c + y; }
cdouble subI(cdouble c, idouble y) { return c - y; }
cdouble rSub(double x, cdouble c) { return x - c; }
cdouble iSub(idouble y, cdouble c) { return y - c; }
cfloat faddR(cfloat c, float x) { return c + x; }

void main()
{
    cdouble c = 1 + 2i;
    assert(addR(c, 3) == 4 + 2i);
    assert(subR(c, 3) == -2 + 2i);
    assert(addI(c, 3i) == 1 + 5i);
    assert(subI(c, 3i) == 1 - 1i);
    assert(rSub(3, c) == 2 - 2i);
    assert(iSub(3i, c) == -1 + 1i);
    assert(faddR(1 + 2i, 3) == 4 + 2i);
    assert(widen(4 + 2i) == 4 + 2i);
    assert(narrow(5 + 3i) == 5 + 3i);
}

cdouble widen(cfloat c) { return c; }
cfloat narrow(cdouble c) { return c; }

cdouble realImag(double x, idouble y) { return x + y; }
cdouble imagReal(idouble y, double x) { return y - x; }

static this()
{
    assert(realImag(1, 2i) == 1 + 2i);
    assert(imagReal(2i, 1) == -1 + 2i);
}
