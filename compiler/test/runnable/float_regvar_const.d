// Assigning constants to floating point variables held in registers.

double powAssign()
{
    double x = -1.0;
    const y = (x += 3) ^^ 2.0;
    return y + x;
}

float sumConsts(int n)
{
    float a = 0.25f;
    float b = 1.5f;
    foreach (i; 0 .. n)
    {
        a = a * 2;
        b = 3.0f;
    }
    return a + b;
}

void main()
{
    assert(powAssign() == 6.0);
    assert(sumConsts(3) == 5.0f);
    assert(sumConsts(0) == 1.75f);
}
