// Converting a double to a 64 bit integer leaves the double intact for its
// other uses.

double frac(double value) { return value - cast(long) value; }
double fracu(double value) { return value - cast(ulong) value; }

void main()
{
    assert(frac(1.5) == 0.5 && frac(-2.25) == -0.25);
    assert(fracu(3.75) == 0.75);
    double d = 337000.5;
    assert(cast(long) d == 337000 && cast(ulong) d == 337000 && d == 337000.5);
}
