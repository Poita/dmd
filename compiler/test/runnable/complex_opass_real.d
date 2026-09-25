// REQUIRED_ARGS: -d
// Complex add/subtract-assign of a real or imaginary operand.

void add(ref cdouble c, double r) { c += r; }
void subi(ref cdouble c, idouble i) { c -= i; }
void addf(ref cfloat c, ifloat i) { c += i; }
cdouble addRet(ref cdouble c, double r) { return c += r; }
void main()
{
    cdouble c = 1.0 + 2.0i;
    add(c, 3.0);
    assert(c == 4.0 + 2.0i);
    subi(c, 5.0i);
    assert(c == 4.0 - 3.0i);
    cfloat f = 1.0f + 1.0fi;
    addf(f, 2.0fi);
    assert(f == 1.0f + 3.0fi);
    assert(addRet(c, 1.0) == 5.0 - 3.0i);
    assert(c == 5.0 - 3.0i);
    addc(c, 3.0 + 4.0i);
    assert(c == 8.0 + 1.0i);
}

void addc(ref cdouble c, cdouble d) { c += d; }
