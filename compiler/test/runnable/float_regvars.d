// REQUIRED_ARGS: -O
// Floating point locals and parameters held in registers across loops, calls and conversions.

double dot(const(double)[] a, const(double)[] b)
{
    double s = 0;
    foreach (i; 0 .. a.length)
        s += a[i] * b[i];
    return s;
}

float lerpSum(float a, float b, int n)
{
    float acc = 0;
    foreach (i; 0 .. n)
    {
        float t = cast(float) i / n;
        acc += a + (b - a) * t;
    }
    return acc;
}

double callAcross(double x)
{
    import core.math : sqrt;
    double y = x * 2;
    double z = sqrt(y);     // a call in between
    return y + z;
}

int toInt(double d) { double e = d * 3; return cast(int) e; }

double sel(double a, double b, bool c) { double r = c ? a : b; return r * 2; }

void main()
{
    assert(dot([1, 2, 3], [4, 5, 6]) == 32);
    assert(lerpSum(0, 10, 10) == 45);
    assert(callAcross(8) == 20);
    assert(toInt(2.5) == 7);
    assert(sel(1, 2, true) == 2 && sel(1, 2, false) == 4);
    float f = 1;
    foreach (i; 0 .. 10)
        f *= 2;
    assert(f == 1024);
}
