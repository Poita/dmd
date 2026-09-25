// REQUIRED_ARGS: -d
// The real and imaginary parts of complex values that are not in memory.

cdouble make(double re, double im) { return re + im * 1i; }
cfloat makef(float re, float im) { return re + im * 1i; }

void main()
{
    assert(make(1, 2).re == 1);
    assert(make(1, 2).im == 2);
    assert(makef(3, 4).re == 3);
    assert(makef(3, 4).im == 4);

    cdouble a = 5 + 6i, b = 1 + 1i;
    assert((a + b).re == 6);
    assert((a - b).im == 5);
}
