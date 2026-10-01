// REQUIRED_ARGS: -O -release
// Floating point post increments and decrements whose results are unused.

__gshared double da = 5;
__gshared float fa = 5;
__gshared real ra = 5;

void incDouble()
{
    double a, b;
    double* pa, pb;
    a = 5;
    b = a++;
    pa = &a;
    pb = &b;
    *pb = (*pa)++;
    da = a;
}

void decFloat()
{
    float a, b;
    float* pa, pb;
    a = 5;
    b = a--;
    pa = &a;
    pb = &b;
    *pb = (*pa)--;
    fa = a;
}

void incReal()
{
    real a, b;
    real* pa, pb;
    a = 5;
    b = a++;
    pa = &a;
    pb = &b;
    *pb = (*pa)++;
    ra = a;
}

void main()
{
    incDouble();
    assert(da == 7);
    decFloat();
    assert(fa == 3);
    incReal();
    assert(ra == 7);
}
